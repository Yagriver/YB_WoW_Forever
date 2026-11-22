import lupa, sys, subprocess
L = lupa.LuaRuntime(unpack_returned_tuples=True)
base = sys.argv[1]

stubs = open('./run.py').read().split("stubs = r'''")[1].split("'''")[0]
L.execute(stubs)
L.execute(r'''
local Frame = {}
Frame.__index = function(t, k)
  if Frame[k] then return Frame[k] end
  if type(k)=="string" and k:match("^%u") then return function() end end  -- widget methods: no-op
  return nil
end
function Frame.new(name) local f = setmetatable({_attr={}, _scripts={}, _shown=true, _name=name}, Frame); if name then _G[name]=f end; return f end
function Frame:SetAttribute(k,v) self._attr[k]=v end
function Frame:GetAttribute(k) return self._attr[k] end
function Frame:Show() self._shown=true end
function Frame:Hide() self._shown=false end
function Frame:IsShown() return self._shown end
function Frame:SetScript(k,fn) self._scripts[k]=fn end
function Frame:HookScript(k,fn) self._scripts["hook_"..k]=fn end
function Frame:GetScript(k) return self._scripts[k] end
function Frame:CreateFontString() return Frame.new() end
function Frame:CreateTexture() return Frame.new() end
function Frame:GetChecked() return self._checked end
function Frame:SetChecked(v) self._checked=v end
function Frame:SetText(t) self._text=t end
function Frame:GetText() return self._text end
function Frame:LockHighlight() self._hl=true end
function Frame:UnlockHighlight() self._hl=false end
ALLFRAMES = {}
unpack = table.unpack
function CreateFrame(kind, name, parent, template) local f = Frame.new(name); f._template=template; f._parent=parent; table.insert(ALLFRAMES, f); return f end
UIParent, Minimap, GameTooltip = Frame.new(), Frame.new(), Frame.new()
UISpecialFrames = {}
function tinsert(t,v) table.insert(t,v) end
function wipe(t) for k in pairs(t) do t[k]=nil end return t end
SlashCmdList = {}
C_Timer = { After=function(s,f) f() end }
function GetBindingKey(a) local r={} for k,v in pairs(BINDS) do if v==a then table.insert(r,k) end end return unpack(r) end
_CV={ActionButtonUseKeyDown="1"}
C_CVar={GetCVar=function(n) return _CV[n] end, SetCVar=function(n,v) _CV[n]=v end, GetCVarBool=function(n) return _CV[n]=="1" end}
''')
yb = L.eval("{}")
load = L.eval("function(code, yb, name) local f, err = load(code, name); assert(f, err); f('YagriverBinds', yb) end")
for f in ["Core.lua","Profiles/Common.lua","Profiles/Druid.lua","UI.lua","Chat.lua"]:
    load(open(base+"/"+f).read(), yb, f)
g = L.globals()
run = L.eval("function(yb, m, ...) return yb[m](yb, ...) end")
# old v2.2 chat macro bound to a key -> must be deleted and unbound
g.CreateMacro("YB Ph Hi","x","/run YagriverBinds_Say(\"Hi!\")",None); g.BINDS["CTRL-SHIFT-1"]="MACRO YB Ph Hi"
# open settings window: setup + list tabs
L.execute("SlashCmdList['YAGRIVERBINDS']()")
print("window shown:", g.YagriverBindsFrame._shown)
raw=L.eval("function(f,k) return rawget(f,k) end")
tabs=[f for f in g.ALLFRAMES.values() if raw(f,"_text") in ("Setup","Keybinds")]
L.eval("function(b) b._scripts.OnClick() end")([t for t in tabs if raw(t,"_text")=="Keybinds"][0])
L.eval("function(b) b._scripts.OnClick() end")([t for t in tabs if raw(t,"_text")=="Setup"][0])
apply_btn=[f for f in g.ALLFRAMES.values() if raw(f,"_text")=="Apply binds"][-1]
L.eval("function(b) b._scripts.OnClick() end")(apply_btn)
print("after apply LOG:", [x for x in g.LOG.values()][-1:])
print("CTRL-SHIFT-1:", g.BINDS["CTRL-SHIFT-1"], "| old macro exists:", g.MACROS["YB Ph Hi"] is not None)
print("CTRL-SHIFT-F11:", g.BINDS["CTRL-SHIFT-F11"], "->", g.MACROS["YB Chat Panel"].body)
# chat panel
L.execute("YagriverBinds_ToggleChat()")
p=g.YagriverBindsChatPanel; print("panel shown:", p._shown)
raw=L.eval("function(f,k) return rawget(f,k) end")
print("templates:", set(str(raw(f,"_template")) for f in g.ALLFRAMES.values()))
phr=[f for f in g.ALLFRAMES.values() if raw(f,"_template") and "Secure" in raw(f,"_template")]
print("phrase buttons:", len(phr), "| first macrotext:", phr[0]._attr["macrotext"], "| last:", phr[-1]._attr["macrotext"])
guild=[f for f in g.ALLFRAMES.values() if raw(f,"_text")=="Guild"][0]
L.eval("function(b) b._scripts.OnClick(b) end")(guild)
print("after Guild:", phr[1]._attr["macrotext"], "| highlight:", raw(guild,"_hl"))
L.eval("function(b) b._scripts.hook_PostClick(b,'LeftButton',false) end")(phr[1]); print("after up-click shown:", p._shown)
L.eval("function(b) b._scripts.hook_PostClick(b,'LeftButton',true) end")(phr[1]); print("after down-click shown:", p._shown)
L.execute("InCombatLockdown=function() return true end; YagriverBinds_ToggleChat()")
print("combat toggle LOG:", [x for x in g.LOG.values()][-1:])
