# Generates the Steam Input layout. Syntax checked against real Steam-written layouts (RetroDECK)
# and the sc-controller VDF parser: binding = "command, label, icon, colors".
import sys
T="\t"
def kv(k,v,n): return f'{T*n}"{k}"{T*2}"{v}"\n'
def block(name, inner, n): return f'{T*n}"{name}"\n{T*n}{{\n{inner}{T*n}}}\n'
def keys(ks, label, icon=""): return [f"key_press {k}, {label}, {icon}, " for k in ks]
def act(bindings, kind="Full_Press", settings=None):
    inner=block("bindings","".join(kv("binding",b,7) for b in bindings),6)
    if settings: inner+=block("settings","".join(kv(k,v,7) for k,v in settings.items()),6)
    return block(kind, inner, 5)
def inp(name, acts): return block(name, block("activators","".join(acts),4),3)
def group(gid, mode, name, inputs, settings=None):
    inner=kv("id",gid,2)+kv("mode",mode,2)+kv("name",name,2)+kv("description","",2)
    inner+=block("inputs","".join(inputs),2)
    if settings: inner+=block("settings","".join(kv(k,v,3) for k,v in settings.items()),2)
    return block("group",inner,1)
def xi(b,label=""): return [f"xinput_button {b}, {label}, , "]
INT={"interruptable":"1"}
def LP(ms): return {"long_press_time":str(ms)}

def switches(gid, name, town):
    layer = 4 if town else 3
    other = 1 if town else 2
    return group(gid,"switches",name,[
      inp("button_escape",[act(xi("START"))]),
      inp("button_menu",[act(xi("SELECT"),settings=INT),
          act([f"controller_action change_preset {other} 0 1, {'Combat set' if town else 'Town set'}, , "],"Long_Press",LP(600))]),
      inp("left_bumper",[act(xi("SHOULDER_LEFT"))]),
      inp("right_bumper",[act(xi("SHOULDER_RIGHT"))]),
      inp("button_back_left",[act(keys(["F1"],"Travel / Aquatic"),settings=INT),
          act(keys(["LEFT_CONTROL"],"Ctrl (hold)") if town else keys(["LEFT_SHIFT","F1"],"Dash"),"Long_Press",LP(250))]),
      inp("button_back_left_upper",[act(keys(["F2"],"Bear Form"),settings=INT),
          act(keys(["LEFT_SHIFT"],"Shift (hold)") if town else keys(["LEFT_SHIFT","F2"],"Enrage"),"Long_Press",LP(250))]),
      inp("button_back_right",[act(keys(["F3"],"Cat Form"),settings=INT),
          act(keys(["LEFT_SHIFT","F3"],"Prowl"),"Long_Press",LP(250))]),
      inp("button_back_right_upper",[act([f"controller_action hold_layer {layer} 0 0, R5 layer, , "])]),
    ])

def menu(gid, mode, name, items, extra=None):
    st={"touchmenu_button_fire_type":"0","touch_menu_show_labels":"1","touch_menu_haptic":"1"}
    if extra: st.update(extra)
    return group(gid,mode,name,[inp(f"touch_menu_button_{i}",[act(keys(k,l,ic))]) for i,(k,l,ic) in enumerate(items)],st)

G=[]
G.append(group(0,"four_buttons","ABXY (native)",[inp(f"button_{b}",[act(xi(b))]) for b in "ABXY"]))
G.append(switches(1,"Buttons - Combat set",False))
G.append(group(2,"scrollwheel","Left pad: scroll, click = right mouse",[
    inp("scroll_clockwise",[act(["mouse_wheel SCROLL_DOWN, , , "])]),
    inp("scroll_counterclockwise",[act(["mouse_wheel SCROLL_UP, , , "])]),
    inp("click",[act(["mouse_button RIGHT, Right click, , "])])]))
G.append(group(3,"absolute_mouse","Right pad: mouse, click = left mouse",[inp("click",[act(["mouse_button LEFT, Left click, , "])])]))
G.append(group(4,"joystick_move","Left stick (native)",[inp("click",[act(xi("JOYSTICK_LEFT"))])]))
G.append(group(5,"joystick_move","Right stick (native camera)",[inp("click",[act(xi("JOYSTICK_RIGHT"))])],{"output_joystick":"2"}))
G.append(group(6,"dpad","D-pad (native)",[inp(f"dpad_{d}",[act(xi(x))]) for d,x in
    [("north","DPAD_UP"),("south","DPAD_DOWN"),("east","DPAD_RIGHT"),("west","DPAD_LEFT")]]))
# L2 stays the native analog trigger; pulling it (soft or full) also turns the left pad into the party picker
MS=["mode_shift left_trackpad 10, Party picker, , "]
G.append(group(7,"trigger","L2 (native) + party picker on left pad",[inp("click",[act(MS)]),inp("edge",[act(MS)])],{"output_trigger":"1"}))
G.append(group(8,"trigger","R2 (native)",[],{"output_trigger":"2"}))
G.append(menu(10,"radial_menu","L2 + left pad: party picker",[
    (["LEFT_CONTROL","LEFT_SHIFT","1"],"Me","yb_me.png"),
    (["LEFT_CONTROL","LEFT_SHIFT","2"],"Party 1","yb_p1.png"),
    (["LEFT_CONTROL","LEFT_SHIFT","3"],"Party 2","yb_p2.png"),
    (["LEFT_CONTROL","LEFT_SHIFT","4"],"Party 3","yb_p3.png"),
    (["LEFT_CONTROL","LEFT_SHIFT","5"],"Party 4","yb_p4.png")]))
G.append(group(11,"four_buttons","R5 + ABXY: druid utilities",[
    inp("button_A",[act(keys(["LEFT_CONTROL","F5"],"Rebirth"))]),
    inp("button_B",[act(keys(["LEFT_CONTROL","F6"],"Remove Curse"))]),
    inp("button_X",[act(keys(["LEFT_CONTROL","F7"],"Abolish Poison"))]),
    inp("button_Y",[act(keys(["LEFT_CONTROL","F8"],"Mark of the Wild"))])]))
G.append(menu(12,"touch_menu","R5 + right pad: emergencies",[
    (["LEFT_CONTROL","F1"],"Innervate","yb_innervate.png"),
    (["LEFT_CONTROL","F2"],"Barkskin","yb_barkskin.png"),
    (["LEFT_CONTROL","F3"],"Nature's Grasp","yb_natures_grasp.png"),
    (["LEFT_CONTROL","F4"],"Rejuv (me)","yb_rejuv_me.png")],{"touch_menu_button_count":"4"}))
G.append(menu(14,"radial_menu","R5 + left pad: windows",[
    (["M"],"Map","yb_map.png"),
    (["LEFT_SHIFT","B"],"Bags","yb_bags.png"),
    (["J"],"Character","yb_char.png"),
    (["P"],"Spells","yb_spells.png"),
    (["N"],"Talents","yb_talents.png"),
    (["O"],"Social","yb_social.png"),
    (["K"],"Professions","yb_prof.png"),
    (["LEFT_CONTROL","F9"],"Mount","yb_mount.png"),
    (["LEFT_CONTROL","LEFT_SHIFT","F11"],"Chat + Prof.","yb_panel.png"),
    (["LEFT_CONTROL","LEFT_SHIFT","F12"],"YB menu","yb_ybmenu.png")]))
KB="controller_action SHOW_KEYBOARD, Show Keyboard, , "
G.append(group(15,"dpad","R5 + D-pad",[
    inp("dpad_north",[act(keys(["LEFT_CONTROL","F10"],"Hearthstone"))]),
    inp("dpad_south",[act(keys(["RETURN"],"Chat + keyboard")+[KB])]),
    inp("dpad_east",[act(keys(["LEFT_CONTROL","LEFT_SHIFT","F6"],"Feral weapons"))]),
    inp("dpad_west",[act(keys(["LEFT_CONTROL","LEFT_SHIFT","F5"],"Caster weapons"))])]))
G.append(switches(17,"Buttons - Town set",True))

def preset(pid,name,binds): return block("preset",kv("id",pid,2)+kv("name",name,2)+block("group_source_bindings","".join(kv(g,s,3) for g,s in binds),2),1)
base=lambda sw:[(0,"button_diamond active"),(sw,"switch active"),(2,"left_trackpad active"),(3,"right_trackpad active"),
    (4,"joystick active"),(5,"right_joystick active"),(6,"dpad active"),(7,"left_trigger active"),(8,"right_trigger active"),
    (10,"left_trackpad active modeshift")]
layer=[(11,"button_diamond active"),(14,"left_trackpad active"),(12,"right_trackpad active"),(15,"dpad active")]
P=preset(0,"Default",base(1))+preset(1,"Preset_1000001",base(17))+preset(2,"Preset_1000002",layer)+preset(3,"Preset_1000003",layer)

def aset(key,title,extra=""): return block(key,kv("title",title,3)+kv("legacy_set","1",3)+extra,2)
head=(kv("version","3",1)+kv("revision","1",1)+kv("title","WoW Forever - Druid (Yagriver) v5.3",1)
 +kv("description","Native gamepad + back buttons = forms, R5 layer (emergencies, windows, utilities), L2 + left pad = party picker, Town set (hold Select).",1)
 +kv("creator","Yagriver",1)+kv("progenitor","",1)+kv("url","",1)+kv("export_type","personal_local",1)
 +kv("controller_type","controller_neptune",1)+kv("major_revision","0",1)+kv("minor_revision","0",1)+kv("Timestamp","1763337600",1))
actions=block("actions",aset("Default","Combat")+aset("Preset_1000001","Town"),1)
lay=lambda p:kv("set_layer","1",3)+kv("parent_set_name",p,3)
layers=block("action_layers",aset("Preset_1000002","R5 layer",lay("Default"))+aset("Preset_1000003","R5 layer (Town)",lay("Preset_1000001")),1)
tail=block("settings",kv("left_trackpad_mode","0",2)+kv("right_trackpad_mode","0",2),1)
open(sys.argv[1],"w").write(block("controller_mappings",head+actions+layers+"".join(G)+P+tail,0))
