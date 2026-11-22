import lupa, sys
L = lupa.LuaRuntime(unpack_returned_tuples=True)
base = sys.argv[1]
L.execute(r'''
unpack = table.unpack
local binds, macros, log = {}, {}, {}
LOG, BINDS, MACROS = log, binds, macros
function print(...) local t={} for i=1,select('#',...) do t[#t+1]=tostring(select(i,...)) end table.insert(log, table.concat(t," ")) end
spells = {[768]="Cat Form",[5487]="Bear Form",[9634]="Dire Bear Form",[1066]="Aquatic Form",[783]="Travel Form",
 [5215]="Prowl",[5229]="Enrage",[1850]="Dash",[29166]="Innervate",[22812]="Barkskin",[16689]="Nature's Grasp",
 [774]="Rejuvenation",[20484]="Rebirth",[2782]="Remove Curse",[2893]="Abolish Poison",[8946]="Cure Poison",
 [1126]="Mark of the Wild",[5185]="Healing Touch",[8936]="Regrowth",[8921]="Moonfire",[3273]="First Aid",[2550]="Cooking",[2259]="Alchemy"}
known = {[5487]=true,[768]=true,[1066]=true,[774]=true,[8946]=true,[1126]=true,[5185]=true,[8936]=true,[8921]=true,[5229]=true,[3273]=true,[2259]=true}
C_Spell = { GetSpellName = function(id) return spells[id] end }
C_Item = { GetItemNameByID = function(id) return ({[100]="Staff of Bears",[200]="Wand of Light",[201]="Holy Book"})[id] end,
           GetItemIconByID = function(id) return "icon"..id end }
function IsPlayerSpell(id) return known[id] or false end
forms = {5487, 1066, 768}      -- bear, aquatic, cat (no travel yet, like the user)
function GetNumShapeshiftForms() return #forms end
function GetShapeshiftFormInfo(i) return "icon", false, true, forms[i] end
equipped = {[16]=200,[17]=201}
function GetInventoryItemID(u,s) return equipped[s] end
function UnitClass() return "Druida","DRUID" end
COMBAT=false
function InCombatLockdown() return COMBAT end
function GetMacroIndexByName(n) return macros[n] and macros[n].idx or 0 end
local nextIdx=1
function CreateMacro(n,icon,body,perChar) assert(#n<=16,"macro name too long: "..n) assert(#body<=255,"body too long "..n) macros[n]={idx=nextIdx,body=body,perChar=perChar}; nextIdx=nextIdx+1 end
function EditMacro(idx,n,icon,body) assert(#body<=255) for k,v in pairs(macros) do if v.idx==idx then v.body=body end end end
function DeleteMacro(x) for k,v in pairs(macros) do if v.idx==x or k==x then macros[k]=nil end end end
function GetMacroInfo(n) local m=macros[n]; if m then return n,"icon",m.body end end
function GetBindingAction(k) return binds[k] or "" end
function GetBindingKey(a) local r={} for k,v in pairs(binds) do if v==a then table.insert(r,k) end end return unpack(r) end
function SetBindingSpell(k,s) binds[k]="SPELL "..s return true end
function SetBindingMacro(k,m) assert(macros[m],"bind to missing macro "..m) binds[k]="MACRO "..m return true end
function SetBinding(k,a) binds[k]=a return true end
function SaveBindings() end
function SetBindingClick(k,name,btn) binds[k]="CLICK "..name..":"..(btn or "LeftButton") return true end
FORM=0
function GetShapeshiftForm() return FORM end
CLICKREG={}
function GetCurrentBindingSet() return 1 end
NOW=100
function GetTime() return NOW end
UIErrorsFrame = { AddMessage=function(self,m) table.insert(log,"[screen] "..m) end }
_CV={GamePadCursorAutoEnable="1",GamePadCursorAutoDisableSticks="1",ActionButtonUseKeyDown="1",GamePadEnable="1",uiScale="0.90",useUiScale="0",GamePadUIEnabled="1",lastCharacterIndex="0"}
C_Console={GetAllCommands=function() local t={} for k in pairs(_CV) do table.insert(t,{command=k,commandType=0}) end return t end}
RELOADED=false
function ReloadUI() RELOADED=true end
C_CVar={GetCVar=function(n) return _CV[n] end, SetCVar=function(n,v) _CV[n]=v end, GetCVarBool=function(n) return _CV[n]=="1" end}
local Frame = {}
Frame.__index = function(t, k)
  if Frame[k] then return Frame[k] end
  if type(k)=="string" and k:match("^%u") then return function() end end
  return nil
end
function Frame.new(name) local f = setmetatable({_attr={}, _scripts={}, _shown=true, _enabled=true}, Frame); if name then _G[name]=f end; return f end
function Frame:SetAttribute(k,v) assert(not COMBAT,"SetAttribute in combat") self._attr[k]=v end
function Frame:Show() self._shown=true end
function Frame:Hide() self._shown=false end
function Frame:RegisterForClicks(...) self._clicks={...} end
function Frame:GetStringWidth() return 150 end
function Frame:SetScale(v) self._scale=v end
function Frame:GetCenter() return self._cx, self._cy end
function Frame:GetWidth() return rawget(self,"_W") or self._w or 1365 end
function Frame:GetHeight() return rawget(self,"_H") or self._h or 853 end
function Frame:EnableMouse(v) self._mouse=v end
function Frame:SetShown(v) self._shown=v end
function Frame:IsShown() return self._shown end
function Frame:SetScript(k,fn) self._scripts[k]=fn end
function Frame:HookScript(k,fn) self._scripts["hook_"..k]=fn end
function Frame:CreateFontString(n,l,tmpl) local t=Frame.new(); t._fs=true; t._font=tmpl; t._parent=self; table.insert(ALLTEX,t); return t end
function Frame:CreateTexture(name, layer) local t=Frame.new(); t._layer=layer; t._parent=self; table.insert(ALLTEX, t); return t end
function Frame:CreateLine() local t=Frame.new(); t._isline=true; t._parent=self; table.insert(ALLTEX,t); return t end
function Frame:SetStartPoint(a,p,x,y) self._s={x,y} end
function Frame:SetEndPoint(a,p,x,y) self._e={x,y} end
function Frame:SetColorTexture(r,g,b,a) self._c={r,g,b,a or 1} end
function Frame:SetAlpha(a) self._a=a end
function Frame:SetTexCoord(a,b,c,d) self._tc={a,b,c,d} end
function Frame:SetTexture(p) self._tex=p end
function Frame:SetSize(w,h) self._w=w; self._h=h end
function Frame:SetPoint(a,b,c,d,e) if type(b)=="table" then self._pt={a,c,d,e} else self._pt={a,b,c,d} end end
function Frame:ClearAllPoints() self._pt=nil end
function Frame:SetFontObject(o) self._font=o end
function Frame:GetChecked() return self._checked end
function Frame:SetChecked(v) self._checked=v end
function Frame:SetText(t) self._text=t end
function Frame:Enable() self._enabled=true end
function Frame:Disable() self._enabled=false end
function Frame:LockHighlight() self._hl=true end
function Frame:UnlockHighlight() self._hl=false end
ALLFRAMES = {}
ALLTEX = {}
function CreateFrame(kind, name, parent, template) local f = Frame.new(name); f._template=template; table.insert(ALLFRAMES, f); return f end
UIParent, Minimap, GameTooltip = Frame.new(), Frame.new(), Frame.new()
UIParent._W, UIParent._H = 1365, 853
UISpecialFrames = {}
function tinsert(t,v) table.insert(t,v) end
function wipe(t) for k in pairs(t) do t[k]=nil end return t end
SlashCmdList = {}
''')
yb = L.eval("{}")
load = L.eval("function(code, yb, name) local f, err = load(code, name); assert(f, err); f('YagriverBinds', yb) end")
import re as _re
toc=[l.strip().replace("\\","/") for l in open(base+"/YagriverBinds.toc") if l.strip() and not l.startswith("#")]
for f in toc:
    load(open(base+"/"+f).read(), yb, "@"+f)
g = L.globals(); raw=L.eval("function(f,k) return rawget(f,k) end")
run = L.eval("function(yb, m, ...) return yb[m](yb, ...) end")
click = L.eval("function(b, ...) b._scripts.OnClick(b, ...) end")
def btn(text, last=True):
    c=[f for f in g.ALLFRAMES.values() if (raw(f,"_text") or "").startswith(text)]
    return c[-1] if last else c[0]
def body(n): return g.MACROS[n].body if g.MACROS[n] else None
def check(name, cond):
    print(("PASS " if cond else "FAIL ")+name); 
    if not cond: check.fail+=1
check.fail=0

# starting state: bar-5 keys, v1 macro (untouched text), v1 macro the user edited, v2 macro, user's own macro
g.BINDS["F1"]="MULTIACTIONBAR3BUTTON1"; g.BINDS["F2"]="MULTIACTIONBAR3BUTTON2"
g.CreateMacro("Party Hi","x","/p Hi everyone!",None); g.BINDS["CTRL-SHIFT-F1"]="MACRO Party Hi"
g.CreateMacro("Reply Hi","x","/r Hola, que tal",None)            # user edited -> must be kept
g.CreateMacro("YB Ph Hi","x","/run YagriverBinds_Say(\"Hi!\")",None); g.BINDS["CTRL-SHIFT-1"]="MACRO YB Ph Hi"
g.CreateMacro("MyOwn","x","/dance",None); g.BINDS["ALT-Q"]="MACRO MyOwn"

L.execute("SlashCmdList['YAGRIVERBINDS']()")
check("window opens", g.YagriverBindsFrame._shown)
# weapons: caster = wand+book, feral = staff
click(btn("Use equipped"))            # caster row is last
g.equipped[16]=100; g.equipped[17]=None
click(btn("Use equipped", last=False))
db=run(yb,"DB"); check("weapon hint on by default", db.weaponHint==True)
check("weapon sets saved as item ids", db.weapons.caster.mh==200 and db.weapons.caster.oh==201 and db.weapons.feral.mh==100 and db.weapons.feral.oh is None)
db.swap.bear=True; db.swap.cat=True; db.swap.caster=True; db.equipFirst=True   # old saved settings must be ignored
click(btn("Apply binds")); print("   ", list(g.LOG.values())[-1])
check("Apply did NOT delete old macros", body("Party Hi") is not None and body("YB Ph Hi") is not None)
check("forms bound", g.BINDS["F1"]=="MACRO YB Travel" and g.BINDS["F2"]=="MACRO YB Bear" and g.BINDS["F3"]=="MACRO YB Cat")
check("holds bound as clicks", g.BINDS["SHIFT-F1"]=="CLICK YBClickDash:LeftButton" and g.BINDS["SHIFT-F3"]=="CLICK YBClickProwl:LeftButton" and g.BINDS["SHIFT-F2"]=="CLICK YBClickEnrage:LeftButton")
pb=g.YBClickProwl
check("hold button: secure spell Prowl, registered up+down", pb._attr["type"]=="spell" and pb._attr["spell"]=="Prowl" and sorted(pb._clicks.values())==["AnyDown","AnyUp"])
check("weapon keys bound", g.BINDS["CTRL-SHIFT-F5"]=="MACRO YB Caster Set" and g.BINDS["CTRL-SHIFT-F6"]=="MACRO YB Feral Set")
print("--- YB Caster Set:\n"+body("YB Caster Set")); print("--- YB Feral Set:\n"+body("YB Feral Set"))
check("caster set macro: main + off hand", body("YB Caster Set")=="#showtooltip\n/equipslot 16 item:200\n/equipslot 17 item:201")
check("feral set macro: 2H only", body("YB Feral Set")=="#showtooltip\n/equipslot 16 item:100")
check("party targets bound", g.BINDS["CTRL-SHIFT-1"]=="TARGETSELF" and g.BINDS["CTRL-SHIFT-5"]=="TARGETPARTYMEMBER4")
check("panel key bound", g.BINDS["CTRL-SHIFT-F11"]=="MACRO YB Panel" and body("YB Panel")=="/yagpanel")
check("emergency plain spells (no mouseover)", g.BINDS["CTRL-F1"]=="SPELL Innervate" and g.BINDS["CTRL-F5"]=="SPELL Rebirth")
check("12 phrase macros", all(body(f"YB Say {i}") for i in range(1,13)) and body("YB Say 2")=="/p Thanks!")
print("--- YB Bear:\n"+body("YB Bear")); print("--- YB Cat:\n"+body("YB Cat")); print("--- YB Travel:\n"+body("YB Travel")); print("--- YB Regrowth:\n"+body("YB Regrowth"))
check("bear key: shift only", body("YB Bear")=="#showtooltip\n/cast Bear Form")
check("travel key: aquatic in water", body("YB Travel")=="#showtooltip\n/cast [swimming] Aquatic Form; Travel Form")
check("heal: cast only", body("YB Regrowth")=="#showtooltip\n/cast [@mouseover,help,nodead][] Regrowth")
check("no automatic equip in any form/heal macro", not any("equipslot" in body(n) for n in ["YB Bear","YB Cat","YB Travel","YB Regrowth","YB HealTouch","YB Rejuv","YB Moonfire","YB Rejuv Self"]))
check("all macros <=255", all(len(m.body)<=255 for m in g.MACROS.values()))
# options
db.cancelForm=True; click(btn("Apply binds"))
check("no /cancelform anywhere, even with an old saved setting", not any("/cancelform" in m.body for m in g.MACROS.values()))
# cleanup: two clicks, verified by content
cu=btn("Clean old macros"); check("cleanup button counts 2 safe macros", raw(cu,"_text")=="Clean old macros (2)")
click(cu); check("first click deletes nothing", body("Party Hi") is not None); print("   ", list(g.LOG.values())[-1])
click(btn("CONFIRM")); print("   ", list(g.LOG.values())[-1])
check("confirmed: old addon macros deleted", body("Party Hi") is None and body("YB Ph Hi") is None)
check("edited same-name macro kept", body("Reply Hi")=="/r Hola, que tal")
check("user macro + its key kept", body("MyOwn")=="/dance" and g.BINDS["ALT-Q"]=="MACRO MyOwn")
check("current YB macros kept", body("YB Bear") is not None and body("YB Say 1") is not None)
check("dead key freed", g.BINDS["CTRL-SHIFT-F1"] is None)
# confirm timeout
g.CreateMacro("Say Hello","x","/s Hello!",None); click(btn("Setup")); click(btn("Clean old macros")); g.NOW=200; click(btn("CONFIRM"))
check("expired confirmation does not delete", body("Say Hello") is not None)
# panel
L.execute("SlashCmdList['YAGRIVERPANEL']()"); p=g.YagriverBindsPanel
check("panel opens", p._shown)
sec=[f for f in g.ALLFRAMES.values() if raw(f,"_template") and "Secure" in raw(f,"_template")]
ph=[f for f in sec if f._attr["type"]=="macro"]; pr=[f for f in sec if f._attr["type"]=="spell" and f._attr["spell"] not in ("Prowl","Enrage","Dash")]
check("12 phrase buttons run real macros", len(ph)==12 and ph[1]._attr["macro"]=="YB Say 2" and raw(ph[1],"_text")=="Thanks!")
check("profession buttons for known professions", sorted(f._attr["spell"] for f in pr)==["Alchemy","First Aid"])
g.EditMacro(g.MACROS["YB Say 2"].idx,None,None,"/p Gracias!")      # user edits phrase in /macro
click(btn("Guild"))
check("channel switch rewrites macros, keeps edited phrase", body("YB Say 2")=="/g Gracias!" and body("YB Say 1")=="/g Hi!" and raw(ph[1],"_text")=="Gracias!")
click(btn("Reply")); check("reply channel", body("YB Say 3")=="/r Ready!")
click(btn("Apply binds")); check("Apply keeps channel and edited phrase", body("YB Say 2")=="/r Gracias!")
L.eval("function(b) b._scripts.hook_PostClick(b,'LeftButton',true) end")(ph[1]); check("panel closes after sending", not p._shown)
g.COMBAT=True; L.execute("YagriverBinds_TogglePanel()"); check("panel blocked in combat", not p._shown)
check("channel change refused in combat", run(yb,"SetChatChannel","s")==False and body("YB Say 3")=="/r Ready!")
ok,msg=run(yb,"Apply"); check("Apply refused in combat", ok==False)
g.COMBAT=False
# keybinds tab renders
click(btn("Keybinds")); check("keybinds tab renders without error", not any("Error" in x for x in g.LOG.values()))
# remove restores
click(btn("Setup")); click(btn("Remove binds")); print("   ", list(g.LOG.values())[-1])
check("remove restores bar keys", g.BINDS["F1"]=="MULTIACTIONBAR3BUTTON1" and g.BINDS["F2"]=="MULTIACTIONBAR3BUTTON2" and g.BINDS["F3"] is None)
check("remove does not restore deleted macro", g.BINDS["CTRL-SHIFT-1"] is None)
check("remove keeps macros", body("YB Bear") is not None)
# stick toggle + other class
r=run(yb,"SetStickCamera",True); check("stick on", g._CV["GamePadCursorAutoEnable"]=="0")
r=run(yb,"SetStickCamera",False); check("stick off restores", g._CV["GamePadCursorAutoEnable"]=="1" and g._CV["GamePadCursorAutoDisableSticks"]=="1")
L.execute('UnitClass=function() return "Mago","MAGE" end'); ok,msg=run(yb,"Apply"); check("other class: Apply changes nothing", ok==False and "No profile" in msg)
# ---- 5.1: settings key, device tab
L.execute('UnitClass=function() return "Druida","DRUID" end')
click(btn("Apply binds"))
check("settings macro bound to Ctrl+Shift+F12", g.BINDS["CTRL-SHIFT-F12"]=="MACRO YB Settings" and body("YB Settings")=="/yag")
check("all macros <=255 (5.1)", all(len(m.body)<=255 for m in g.MACROS.values()))
gen=sum(1 for m in g.MACROS.values() if not m.perChar); ch=sum(1 for m in g.MACROS.values() if m.perChar)
print("    general macros:", gen, " character macros:", ch); check("character macros within limit 18", ch<=18)
def sbtn(text, i=0):
    c=[f for f in g.ALLFRAMES.values() if (raw(f,"_text") or "").startswith(text) and f._shown]
    return c[i]
def last(): return list(g.LOG.values())[-1]
click(btn("Device"))
check("device tab renders", not any("Error" in x for x in g.LOG.values()))
check("controller not set up -> Detect step 1 shown", sbtn("Detect: step 1") is not None)
click(sbtn("Handheld")); print("   ", last())
gd=g.YagriverBindsDB
check("handheld keeps current scale, says controller not set up, no reload", gd.mode=="handheld" and gd.modes.handheld.scale==0.9 and "not set up" in last() and not g.RELOADED)
click(sbtn("-",0)); check("UI scale minus -> 0.85 saved in handheld", g._CV["uiScale"]=="0.85" and g._CV["useUiScale"]=="1" and gd.modes.handheld.scale==0.85)
for _ in range(12): click(sbtn("+",0))
check("UI scale clamped at 1.15", g._CV["uiScale"]=="1.15")
click(sbtn("1.00")); check("UI scale reset 1.00", float(g._CV["uiScale"])==1.0)
click(sbtn("-",0)); click(sbtn("-",0))
# --- detect Forever's gamepad UI setting (simulated name; the real one is unknown)
click(sbtn("Detect: step 1")); print("   ", last())
check("step 1 saves a snapshot", gd.padSnap is not None and sbtn("Detect: step 2") is not None)
g._CV["GamePadUIEnabled"]="0"; g._CV["lastCharacterIndex"]="1"     # user flips Blizzard's option, game reloads
click(sbtn("Detect: step 2")); print("   ", last())
check("step 2 finds the gamepad UI setting, ignores noise", gd.padCVar=="GamePadUIEnabled" and gd.padOn=="1" and gd.padOff=="0" and gd.padSnap is None)
check("controller button appears, shows OFF", sbtn("Controller: OFF") is not None)
click(sbtn("Controller: OFF")); print("   ", last())
check("controller ON: setting 1 + input on + reload", g._CV["GamePadUIEnabled"]=="1" and g._CV["GamePadEnable"]=="1" and g.RELOADED and gd.modes.handheld.pad==True)
g.RELOADED=False
click(sbtn("Docked")); print("   ", last())
check("docked: 0.75, controller off, reload", g._CV["uiScale"]=="0.75" and g._CV["GamePadUIEnabled"]=="0" and g.RELOADED)
g.RELOADED=False; g._CV["GamePadEnable"]="0"
click(sbtn("Handheld")); print("   ", last())
check("handheld: 0.90, controller on, input re-enabled, reload", g._CV["uiScale"]=="0.9" and g._CV["GamePadUIEnabled"]=="1" and g._CV["GamePadEnable"]=="1" and g.RELOADED)
g.RELOADED=False; click(sbtn("Handheld")); check("same mode again: no reload", not g.RELOADED)
g.COMBAT=True; ok,msg=run(yb,"ApplyMode","docked"); check("mode change refused in combat", ok==False and g._CV["GamePadUIEnabled"]=="1"); g.COMBAT=False
# --- weapon hint size / move / reset per mode
H=g.YagriverBindsWeaponHint
check("hint defaults: handheld 1.7, docked 1.2, 1/6 from top", gd.modes.handheld.hint.scale==1.7 and gd.modes.docked.hint.scale==1.2 and abs(gd.modes.handheld.hint.y-5/6)<1e-9)
click(sbtn("+",1)); check("hint + -> 1.8 for handheld", abs(gd.modes.handheld.hint.scale-1.8)<1e-9 and abs(raw(H,"_scale")-1.8)<1e-9)
pt=raw(H,"_pt"); check("hint anchored at 1/6 from top, centre", abs(pt[3]-0.5*1365/1.8)<1e-6 and abs(pt[4]-(5/6)*853/1.8)<1e-6)
click(sbtn("Move")); check("move: sample shown, mouse on", H._shown and raw(H,"_mouse")==True and sbtn("Done") is not None)
H._cx, H._cy = 300.0, 100.0
L.eval("function(h) h._scripts.OnDragStop(h) end")(H)
check("drag saves position as screen fraction", abs(gd.modes.handheld.hint.x-300*1.8/1365)<1e-9 and abs(gd.modes.handheld.hint.y-100*1.8/853)<1e-9)
click(sbtn("Done")); check("done: mouse off", raw(H,"_mouse")==False)
click(sbtn("Docked")); check("docked has its own hint size", abs(raw(H,"_scale")-1.2)<1e-9)
click(sbtn("Handheld")); check("handheld hint kept", abs(raw(H,"_scale")-1.8)<1e-9)
click(sbtn("Reset")); check("reset restores 1.7 and 1/6 from top", gd.modes.handheld.hint.scale==1.7 and abs(gd.modes.handheld.hint.y-5/6)<1e-9)
g.RELOADED=False
# ---- 5.5: controller via options panel; camera noise rejected; wrong old result dropped
gd=g.YagriverBindsDB
L.execute('''
_GPVAL=true
local st={GetVariable=function() return "PROXY_GAMEPAD_UI" end, GetValue=function() return _GPVAL end,
          SetValue=function(self,v) _GPVAL=v end, GetName=function() return "Habilitar IU de mando (Alfa)" end}
local cam={GetVariable=function() return "GamePadCameraYawSpeed" end, GetValue=function() return 1.0 end, GetName=function() return "Velocidad de cámara del mando" end}
local function init(s,n) return {GetData=function() return {setting=s,name=n} end} end
local sub={GetName=function() return "Mando (Alfa)" end, GetSubcategories=function() return {} end}
local top={GetName=function() return "Juego" end, GetSubcategories=function() return {sub} end}
SettingsPanel={GetAllCategories=function() return {top} end,
  GetLayout=function(self,c) if c==sub then return {GetInitializers=function() return {init(cam,"Velocidad de cámara del mando"),init(st,"Habilitar IU de mando (Alfa)")} end} end return {GetInitializers=function() return {} end} end}
Settings={GetSetting=function(v) if v=="PROXY_GAMEPAD_UI" then return st end end}
''')
# user's real case: only float camera values change between the two steps
run(yb,"ForgetPad"); g._CV["GamepadCameraSavedDistance"]="15.150008"; g._CV["CameraFollowPitchSpeed"]="0.5"
ok,msg=run(yb,"DetectPad"); g._CV["GamepadCameraSavedDistance"]="15.150014"; g._CV["CameraFollowPitchSpeed"]="1.000000"
ok,msg=run(yb,"DetectPad"); print("   ", msg)
check("detect rejects camera noise (no on/off change)", ok==False and gd.padCVar is None and "No on/off setting" in msg)
# the wrong v5.4 result is dropped at login
gd.padCVar, gd.padOn, gd.padOff = "GamepadCameraSavedDistance", "15.150014", "15.150008"
fire=L.eval("function() for _,f in ipairs(ALLFRAMES) do local s=rawget(f,'_scripts') if s and s.OnEvent then s.OnEvent(f,'PLAYER_LOGIN') end end end"); fire()
check("old camera 'result' dropped at login", gd.padCVar is None)
click(btn("Setup")); click(btn("Device"))
click(sbtn("Find in options")); print("   ", last())
check("find in options: Spanish checkbox found", gd.padSetting=="PROXY_GAMEPAD_UI" and "Habilitar IU de mando" in last())
g.RELOADED=False
click(sbtn("Controller: ON")); print("   ", last())
check("controller OFF via options setting + reload", g._GPVAL==False and g.RELOADED)
g.RELOADED=False; click(sbtn("Controller: OFF"))
check("controller ON again via options setting + input on + reload", g._GPVAL==True and g._CV["GamePadEnable"]=="1" and g.RELOADED)
g.RELOADED=False; click(sbtn("Docked")); check("docked mode switches the options setting off", g._GPVAL==False and g.RELOADED)
g.RELOADED=False
L.execute("SlashCmdList['YAGRIVERBINDS']()"); L.execute("SlashCmdList['YAGRIVERBINDS']()")
check("window reopens on last tab without error", g.YagriverBindsFrame._shown and not any("Error" in x for x in g.LOG.values()))
# ---- 5.2: groups folded, deck map
L.execute('UnitClass=function() return "Druida","DRUID" end')
click(btn("Setup"))
check("groups folded by default", any(raw(f,"_text")=="Show groups" and f._shown for f in g.ALLFRAMES.values()) and not any(raw(f,"_text")=="Hide groups" and f._shown for f in g.ALLFRAMES.values()))
check("no cancelform checkbox", not any("cancelform" in (raw(f,"_text") or "") for f in g.ALLFRAMES.values()))
click(btn("Show groups")); check("groups expand", btn("Hide groups") is not None)
click(btn("Deck map"))
F=g.YagriverBindsFrame
check("deck map tab widens window to 1000x560", raw(F,"_w")==1000 and raw(F,"_h")==560)
check("no error on deck map", not any("Error" in x for x in g.LOG.values()))
import os
tex=set(raw(t,"_tex") for t in g.ALLTEX.values() if raw(t,"_tex") and "AddOns\\YagriverBinds" in raw(t,"_tex"))
miss=[p for p in tex if not (os.path.exists(base+"/"+p.split("YagriverBinds\\")[1].replace("\\","/")+".tga"))]
print("    addon textures used:", len(tex), "missing:", miss); check("every texture file exists", not miss)
def boxes():
    out=[]
    for t in g.ALLTEX.values():
        pt=raw(t,"_pt")
        if raw(t,"_layer")=="BACKGROUND" and pt and raw(t,"_w")==150 and t._shown: out.append((pt[3],-pt[4],150,raw(t,"_h")))
    return out
FX,FY,FW,FH=186,40,600,674*600/1729; BX,BY,BW,BH=321,FY+FH+26,330,657*330/1720
def inter(a,b): return a[0]<b[0]+b[2] and b[0]<a[0]+a[2] and a[1]<b[1]+b[3] and b[1]<a[1]+a[3]
for view in ["Normal","Hold R5","Town set"]:
    click(btn(view)); bx=boxes()
    bad=[b for b in bx if inter(b,(FX,FY,FW,FH)) or inter(b,(BX,BY,BW,BH)) or b[0]<0 or b[0]+b[2]>972 or b[1]+b[3]>446]
    ov=[(a,b) for i,a in enumerate(bx) for b in bx[i+1:] if inter(a,b)]
    print(f"    {view}: {len(bx)} label boxes, lowest edge {max(b[1]+b[3] for b in bx):.0f}/446")
    check(f"{view}: 16 boxes, none on the console, none overlapping, inside the page", len(bx)==16 and not bad and not ov)
click(btn("Hold R5"))
ic=[raw(t,"_tex").split("\\")[-1] for t in g.ALLTEX.values() if raw(t,"_tex") and "icons" in raw(t,"_tex") and t._shown]
check("R5 view shows 14 menu icons on the screen", len(ic)==14)
click(btn("Device")); check("leaving deck map restores 600x600", raw(F,"_w")==600 and raw(F,"_h")==600)
# ---- 5.3: hint, capture refresh, clear, login reminder
L.execute('UnitClass=function() return "Druida","DRUID" end; InCombatLockdown=function() return COMBAT end')
H=g.YagriverBindsWeaponHint
same=L.eval("function(a,b) return rawequal(a,b) end")
ht=lambda: " / ".join(raw(t,"_text") or "" for t in g.ALLTEX.values() if raw(t,"_fs") and same(raw(t,"_parent"),H))
g.equipped[16]=200; g.equipped[17]=201; g.FORM=1; L.execute("YagriverBinds_Hint=nil"); run(yb,"UpdateWeaponHint") if False else L.eval("function(y) y.UpdateWeaponHint() end")(yb)
check("bear + caster weapon -> feral hint", H._shown and "Feral weapon" in ht() and "right" in ht())
g.FORM=0; g.equipped[16]=100; g.equipped[17]=None; L.eval("function(y) y.UpdateWeaponHint() end")(yb)
check("caster form + feral weapon -> caster hint", H._shown and "Caster weapon" in ht() and "left" in ht())
g.FORM=1; L.eval("function(y) y.UpdateWeaponHint() end")(yb); check("bear + feral weapon -> no hint", not H._shown)
g.FORM=2; g.equipped[16]=200; L.eval("function(y) y.UpdateWeaponHint() end")(yb); check("aquatic form -> no hint", not H._shown)
g.FORM=1; run(yb,"DB").weaponHint=False; L.eval("function(y) y.UpdateWeaponHint() end")(yb); check("hint off -> hidden", not H._shown)
run(yb,"DB").weaponHint=True
g.equipped[16]=300; g.equipped[17]=None; ok,msg=run(yb,"CaptureWeapons","feral")
check("capture updates the set macro at once", body("YB Feral Set")=="#showtooltip\n/equipslot 16 item:300")
ok,msg=run(yb,"ClearWeapons","feral"); check("clear updates the set macro at once", "no feral weapon set" in body("YB Feral Set"))
g.COMBAT=True; ok,msg=run(yb,"CaptureWeapons","feral"); check("capture refused in combat", ok==False); g.COMBAT=False
g.BINDS["CTRL-SHIFT-F6"]=None; n0=len(g.LOG)
fire=L.eval("function() for _,f in ipairs(ALLFRAMES) do local s=rawget(f,'_scripts') if s and s.OnEvent then s.OnEvent(f,'PLAYER_LOGIN') end end end"); fire()
check("login reminder for unbound key", any("not bound yet" in x for x in list(g.LOG.values())[n0:]))
check("login did not bind anything", g.BINDS["CTRL-SHIFT-F6"] is None)
print("\nFAILED:", check.fail)

# ---- draw what the Lua placed on the deck map page (R5 view)
from PIL import Image, ImageDraw, ImageFont
click(btn("Deck map")); click(btn("Hold R5"))
page=[p for p in [raw(t,"_parent") for t in g.ALLTEX.values() if raw(t,"_tex") and "deck_front" in raw(t,"_tex") and raw(t,"_layer")=="ARTWORK"]][0]
K=1.25; img=Image.new("RGBA",(int(972*K),int(486*K)),(20,17,13,255)); d=ImageDraw.Draw(img)
fnt=lambda b: ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf"%("-Bold" if b else ""),int(10*K))
same=L.eval("function(a,b) return rawequal(a,b) end")
items=[t for t in g.ALLTEX.values() if same(raw(t,"_parent"),page) and t._shown]
print("    items on deck map page:", len(items))
for t in items:
    pt=raw(t,"_pt")
    if raw(t,"_tex") and pt and pt[1]=="TOPLEFT":
        x,y=pt[3]*K,-pt[4]*K; w,h=raw(t,"_w")*K,raw(t,"_h")*K; p=raw(t,"_tex").split("YagriverBinds\\")[1].replace("\\","/")
        im=Image.open(base+"/"+p+".tga").convert("RGBA"); tc=raw(t,"_tc")
        if tc: im=im.crop((0,0,im.width,int(im.height*tc[4])))
        img.alpha_composite(im.resize((int(w),int(h))),(int(x),int(y)))
for t in items:
    c=raw(t,"_c"); pt=raw(t,"_pt")
    if c and not raw(t,"_isline") and pt and raw(t,"_w"):
        col=tuple(int(c[i]*255) for i in (1,2,3))+(int(c[4]*255),)
        if pt[1]=="CENTER": x,y=pt[3]*K-3,-pt[4]*K-3
        else: x,y=pt[3]*K,-pt[4]*K
        ov=Image.new("RGBA",img.size,(0,0,0,0)); ImageDraw.Draw(ov).rectangle([x,y,x+raw(t,"_w")*K,y+raw(t,"_h")*K],fill=col); img.alpha_composite(ov)
d=ImageDraw.Draw(img)
for t in items:
    if raw(t,"_isline") and raw(t,"_s"):
        c=raw(t,"_c"); d.line([raw(t,"_s")[1]*K,-raw(t,"_s")[2]*K,raw(t,"_e")[1]*K,-raw(t,"_e")[2]*K],fill=tuple(int(c[i]*255) for i in (1,2,3)),width=2)
import re
for t in items:
    if raw(t,"_fs") and raw(t,"_text") and raw(t,"_pt") and raw(t,"_pt")[1]=="TOPLEFT":
        pt=raw(t,"_pt"); txt=re.sub(r"\|c\w{8}|\|r","",raw(t,"_text")); f=str(raw(t,"_font"))
        a=raw(t,"_a"); dim = a is not None and a<1
        col=(255,209,0) if "Normal" in f else (232,226,208)
        if dim: col=tuple(int(v*0.45) for v in col)
        d.text((pt[3]*K,-pt[4]*K),txt,font=fnt("Normal" in f),fill=col)
img.convert("RGB").save("./lua_layout_r5.png"); print("rendered")
