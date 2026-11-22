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
check("handheld: 0.85, controller on, input re-enabled, reload", g._CV["uiScale"]=="0.85" and g._CV["GamePadUIEnabled"]=="1" and g._CV["GamePadEnable"]=="1" and g.RELOADED)
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
