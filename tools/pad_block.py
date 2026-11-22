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
