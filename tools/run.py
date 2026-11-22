import lupa, sys
L = lupa.LuaRuntime(unpack_returned_tuples=True)
base = sys.argv[1]
stubs = r'''
local binds, macros, log = {}, {}, {}
_G.LOG = log
function print(...) local t={} for i=1,select('#',...) do t[#t+1]=tostring(select(i,...)) end table.insert(log, table.concat(t," ")) end
spells = {[768]="Cat Form",[5487]="Bear Form",[9634]="Dire Bear Form",[1066]="Aquatic Form",[783]="Travel Form",
 [5215]="Prowl",[5229]="Enrage",[1850]="Dash",[29166]="Innervate",[22812]="Barkskin",[16689]="Nature's Grasp",
 [774]="Rejuvenation",[20484]="Rebirth",[2782]="Remove Curse",[2893]="Abolish Poison",[8946]="Cure Poison",
 [1126]="Mark of the Wild",[5185]="Healing Touch",[8936]="Regrowth",[8921]="Moonfire"}
known = {[5487]=true,[1066]=true,[783]=true,[774]=true,[8946]=true,[1126]=true,[5185]=true,[8936]=true,[8921]=true,[5229]=true,[1850]=false}
C_Spell = { GetSpellName = function(id) return spells[id] end }
C_Item = { GetItemNameByID = function(id) return ({[100]="Staff of Bears",[200]="Wand of Light",[201]="Holy Book"})[id] end }
function IsPlayerSpell(id) return known[id] or false end
forms = {5487, 1066, 783}
function GetNumShapeshiftForms() return #forms end
function GetShapeshiftFormInfo(i) return "icon", false, true, forms[i] end
equipped = {[16]=200,[17]=201}
function GetInventoryItemID(u,s) return equipped[s] end
function UnitClass() return "Druida","DRUID" end
function InCombatLockdown() return false end
function GetMacroIndexByName(n) return macros[n] and macros[n].idx or 0 end
local nextIdx=1
function CreateMacro(n,icon,body,perChar) assert(#n<=16,"macro name too long: "..n) assert(#body<=255,"body too long "..n) macros[n]={idx=nextIdx,body=body}; nextIdx=nextIdx+1 end
function EditMacro(idx,n,icon,body) assert(#body<=255) for k,v in pairs(macros) do if v.idx==idx then v.body=body end end end
function DeleteMacro(idx) for k,v in pairs(macros) do if v.idx==idx then macros[k]=nil end end end
function GetBindingAction(k) return binds[k] or "" end
function SetBindingSpell(k,s) binds[k]="SPELL "..s end
function SetBindingMacro(k,m) assert(macros[m],"bind to missing macro "..m) binds[k]="MACRO "..m end
function SetBinding(k,a) binds[k]=a end
function SaveBindings() end
function GetCurrentBindingSet() return 1 end
UIErrorsFrame = { AddMessage=function(self,m) table.insert(log,"[screen] "..m) end }
local sent = {}
SENT = sent
local eb = {text=""}
function ChatFrame_OpenChat(t) eb.text=t end
function ChatEdit_GetActiveWindow() return eb end
function ChatEdit_SendText(e) table.insert(sent, e.text) end
function ChatEdit_DeactivateChat(e) end
BINDS, MACROS = binds, macros
'''
L.execute(stubs)
YB = L.eval("{}")
for f in ["Core.lua","Profiles/Common.lua","Profiles/Druid.lua"]:
    code = open(base+"/"+f).read()
    L.execute("local f = load(...); f('YagriverBinds', YBT)".replace("YBT","_YB"), ) if False else None
    L.globals()._YB = YB
    fn = L.eval("function(code, yb) local f, err = load(code); assert(f, err); f('YagriverBinds', yb) end")
    fn(code, YB)
g = L.globals()
# pre-existing bar-5 bindings and a v1 macro
g.BINDS["F1"]="MULTIACTIONBAR3BUTTON1"; g.BINDS["F2"]="MULTIACTIONBAR3BUTTON2"
g.CreateMacro("Party Hi","x","/p Hi everyone!",None); g.BINDS["CTRL-SHIFT-F1"]="MACRO Party Hi"
run = L.eval("function(yb, m, ...) return yb[m](yb, ...) end")
print("capture caster:", run(YB,"CaptureWeapons","caster"))
g.equipped[16]=100; g.equipped[17]=None
print("capture feral:", run(YB,"CaptureWeapons","feral"))
db = run(YB,"DB"); db.swap.bear=True; db.swap.caster=True
print("apply:", run(YB,"Apply"))
for k in ["F1","F2","F3","SHIFT-F1","SHIFT-F3","CTRL-F1","CTRL-F4","CTRL-F7","CTRL-F10","CTRL-SHIFT-F1","CTRL-SHIFT-1","ALT-SHIFT-F5"]:
    print(f"  {k:14} -> {g.BINDS[k]}")
for n in ["YB Bear","YB Travel","YB Cat","YB Rejuv Self","YB Regrowth","YB Moonfire","YB Ch p","YB Ph Thanks"]:
    m = g.MACROS[n]; print(f"--- {n}\n{m.body if m else 'MISSING'}")
print("old macro still there:", g.MACROS["Party Hi"] is not None)
L.execute('YagriverBinds_Channel("p"); YagriverBinds_Say("Thanks!"); YagriverBinds_Channel("r"); YagriverBinds_Say("Sure!")')
print("sent:", list(g.SENT.values()))
L.execute('YagriverBinds_Type("r")')
print("status F2:", run(YB,"Status", L.eval("{type='form', key='F2', name='YB Bear'}")))
print("remove:", run(YB,"Remove"))
for k in ["F1","F2","F3","CTRL-SHIFT-F1"]: print(f"  {k:14} -> {g.BINDS[k]}")
print("LOG:", list(g.LOG.values()))
L.execute('''_CV={GamePadCursorAutoEnable="1",GamePadCursorAutoDisableSticks="1"}
C_CVar={GetCVar=function(n) return _CV[n] end, SetCVar=function(n,v) _CV[n]=v end}''')
print("stick on:", run(YB,"SetStickCamera",True), dict(g._CV))
print("stick off:", run(YB,"SetStickCamera",False), dict(g._CV))
