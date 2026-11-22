-- YB Probe 1.0: a one-off test for the YagriverBinds PC edition.
-- It only reads, except during a test stage, when it adds temporary override
-- bindings on the bumpers and stick clicks (gone at the end of the stage or on
-- /reload) and, in the "RT modifier" stage, one gamepad setting that it puts
-- back afterwards (also at the next login if the game closed mid-stage).
-- Everything it sees is written to YBProbeDB (SavedVariables\YBProbe.lua).

local VERSION = "1.0"
local STAGE_SECONDS = 45
local MAX_LINES = 4000

local P = {}
_G.YBProbe = P

local function db()
    YBProbeDB = YBProbeDB or {}
    YBProbeDB.log = YBProbeDB.log or {}
    return YBProbeDB
end

---------------------------------------------------------------------------
-- Log
---------------------------------------------------------------------------
local t0 = GetTime()
local function add(fmt, ...)
    local line = select("#", ...) > 0 and format(fmt, ...) or fmt
    local d = db()
    if #d.log < MAX_LINES then d.log[#d.log + 1] = format("%7.2f  %s", GetTime() - t0, line) end
    P:Show(line)
end

local function section(title)
    add("")
    add("== %s ==", title)
end

local function safe(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(fn, ...)
    if ok then return a, b, c, d end
    return nil
end

local function cvar(name)
    local v = safe(C_CVar and C_CVar.GetCVar, name)
    if v == nil then v = safe(GetCVar, name) end
    return v
end

---------------------------------------------------------------------------
-- What is checked
---------------------------------------------------------------------------
local PAD_KEYS = {
    "PAD1", "PAD2", "PAD3", "PAD4", "PAD5", "PAD6",
    "PADDUP", "PADDRIGHT", "PADDDOWN", "PADDLEFT",
    "PADLSHOULDER", "PADRSHOULDER", "PADLTRIGGER", "PADRTRIGGER",
    "PADLSTICK", "PADRSTICK", "PADBACK", "PADFORWARD", "PADSOCIAL", "PADSYSTEM",
    "PADPADDLE1", "PADPADDLE2", "PADPADDLE3", "PADPADDLE4",
}
local PREFIXES = { "", "SHIFT-", "CTRL-", "ALT-", "CTRL-SHIFT-", "ALT-SHIFT-", "ALT-CTRL-", "ALT-CTRL-SHIFT-" }
-- The buttons the wheels could live on
local TEST_KEYS = { "PADLSHOULDER", "PADRSHOULDER", "PADLSTICK", "PADRSTICK" }

local CVARS = {
    "InputDeviceInterfaceStyle", "GamePadEnable", "GamePadSingleActiveID",
    "GamePadEmulateShift", "GamePadEmulateCtrl", "GamePadEmulateAlt", "GamePadStickAxisButtons",
    "GamePadCursorAutoEnable", "GamePadCursorAutoDisableSticks", "GamePadCursorLeftClick", "GamePadCursorRightClick",
    "useUiScale", "uiScale", "gxWindowedResolution", "gxFullscreenResolution", "gxMaximize",
    "synchronizeSettings", "synchronizeBindings", "synchronizeConfig", "synchronizeMacros", "synchronizeChatFrames",
    "ActionButtonUseKeyDown", "autoSelfCast",
}

-- The Deck edition's keys (v5.x), to see whether the server brought them here
local DECK_KEYS = {
    "F1", "F2", "F3", "SHIFT-F1", "SHIFT-F2", "SHIFT-F3",
    "CTRL-F1", "CTRL-F2", "CTRL-F3", "CTRL-F4", "CTRL-F5", "CTRL-F6", "CTRL-F7", "CTRL-F8", "CTRL-F9", "CTRL-F10",
    "CTRL-SHIFT-F5", "CTRL-SHIFT-F6", "CTRL-SHIFT-F11", "CTRL-SHIFT-F12",
    "CTRL-SHIFT-1", "CTRL-SHIFT-2", "CTRL-SHIFT-3", "CTRL-SHIFT-4", "CTRL-SHIFT-5",
}

local OTHER_ADDONS = { "YagriverBinds", "EasyController", "ControllerForever", "ForeverControllerTweaks", "ImprovedForever", "ConsolePort" }

local function isLoaded(name)
    local f = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return safe(f, name) and true or false
end

local function padIndex(binding)
    local i = safe(C_GamePad and C_GamePad.ButtonBindingToIndex, binding)
    return i and (i + 1) or nil
end

local function mappedState()
    return safe(C_GamePad and C_GamePad.GetDeviceMappedState)
end

local function cameraStick(state)
    if state and C_GamePad and C_GamePad.StickIndexToConfigName then
        for i = 1, state.stickCount or 0 do
            local n = safe(C_GamePad.StickIndexToConfigName, i - 1)
            if n == "Camera" or n == "Right" or n == "Look" then return i end
        end
    end
    return 2
end

---------------------------------------------------------------------------
-- Snapshot: read only
---------------------------------------------------------------------------
function P:Snapshot()
    local d = db()
    d.runs = (d.runs or 0) + 1
    section(format("YB Probe %s, snapshot %d, %s", VERSION, d.runs, date("%Y-%m-%d %H:%M")))
    local ver, build, bdate, iface = GetBuildInfo()
    add("Client %s build %s (%s), interface %s", tostring(ver), tostring(build), tostring(bdate), tostring(iface))
    local _, class = UnitClass("player")
    add("Character: %s, %s, level %s", tostring(UnitName("player")), tostring(class), tostring(UnitLevel("player")))
    add("In combat: %s", InCombatLockdown() and "yes" or "no")

    section("Screen")
    local pw, ph = safe(GetPhysicalScreenSize)
    add("Physical: %s x %s%s", tostring(pw), tostring(ph), (pw and ph and ph > 0) and format("  (ratio %.3f)", pw / ph) or "")
    add("UI units: %.1f x %.1f, effective scale %.4f", GetScreenWidth(), GetScreenHeight(), UIParent:GetEffectiveScale())

    section("Settings")
    for _, name in ipairs(CVARS) do add("%s = %s", name, tostring(cvar(name))) end

    section("Gamepad")
    add("C_GamePad: %s, enabled %s, active device %s", C_GamePad and "yes" or "no",
        tostring(safe(C_GamePad and C_GamePad.IsEnabled)), tostring(safe(C_GamePad and C_GamePad.GetActiveDeviceID)))
    local st = mappedState()
    if st then
        add("Mapped state: %s buttons, %s sticks, %s axes", tostring(st.buttonCount), tostring(st.stickCount), tostring(st.axisCount))
        local names = {}
        for i = 1, st.buttonCount or 0 do
            names[#names + 1] = i .. "=" .. tostring(safe(C_GamePad.ButtonIndexToBinding, i - 1))
        end
        add("Buttons: %s", table.concat(names, " "))
        local sticks = {}
        for i = 1, st.stickCount or 0 do
            sticks[#sticks + 1] = i .. "=" .. tostring(safe(C_GamePad.StickIndexToConfigName, i - 1))
        end
        add("Sticks: %s (camera stick used: %d)", table.concat(sticks, " "), cameraStick(st))
    else
        add("No mapped state (no pad seen right now)")
    end
    for _, k in ipairs({ "PADLTRIGGER", "PADRTRIGGER", "PADLSHOULDER", "PADRSHOULDER", "PADLSTICK", "PADRSTICK" }) do
        add("Index of %s: %s", k, tostring(padIndex(k)))
    end

    section("Binding contexts")
    local contexts = {}
    if Enum and Enum.BindingContext then
        for name, value in pairs(Enum.BindingContext) do
            contexts[#contexts + 1] = { name = name, value = value }
            add("%s = %s", tostring(name), tostring(value))
        end
    else
        add("Enum.BindingContext missing")
    end

    section("Pad bindings (only keys with something on them)")
    local getByKey = C_KeyBindings and C_KeyBindings.GetBindingByKey
    for _, key in ipairs(PAD_KEYS) do
        for _, prefix in ipairs(PREFIXES) do
            local combo = prefix .. key
            local parts = {}
            local normal = safe(GetBindingAction, combo, false)
            local withOverride = safe(GetBindingAction, combo, true)
            if normal and normal ~= "" then parts[#parts + 1] = "saved=" .. normal end
            if withOverride and withOverride ~= "" and withOverride ~= normal then parts[#parts + 1] = "override=" .. withOverride end
            for _, c in ipairs(contexts) do
                local a = safe(getByKey, combo, c.value)
                if type(a) == "string" and a ~= "" then parts[#parts + 1] = c.name .. "=" .. a end
            end
            if #parts > 0 then add("%s: %s", combo, table.concat(parts, "  ")) end
        end
    end

    section("Deck keys found on this PC")
    local found = 0
    for _, key in ipairs(DECK_KEYS) do
        local a = safe(GetBindingAction, key, false)
        if a and a ~= "" then
            add("%s = %s", key, a)
            found = found + 1
        end
    end
    add("%d of %d Deck keys are bound here", found, #DECK_KEYS)
    local n = safe(GetNumBindings) or 0
    local yb = 0
    for i = 1, n do
        local command, _, k1, k2, k3 = safe(GetBinding, i)
        if type(command) == "string" and (command:find("^MACRO YB") or command:find("^CLICK YBClick")) then
            add("YB binding: %s on %s %s %s", command, tostring(k1), tostring(k2 or ""), tostring(k3 or ""))
            yb = yb + 1
        end
    end
    add("%d bindings point to YB macros or buttons", yb)
    local macros = {}
    for i = 1, 150 do
        local name = safe(GetMacroInfo, i)
        if type(name) == "string" and name:find("^YB") then macros[#macros + 1] = name end
    end
    add("YB macros here: %d %s", #macros, #macros > 0 and ("(" .. table.concat(macros, ", ") .. ")") or "")

    section("Edit Mode layouts")
    local layouts = safe(C_EditMode and C_EditMode.GetLayouts)
    if layouts then
        add("Active layout index: %s", tostring(layouts.activeLayout))
        for i, l in ipairs(layouts.layouts or {}) do
            add("Custom %d (index %d): %s, type %s", i, i + 2, tostring(l.layoutName), tostring(l.layoutType))
        end
    else
        add("C_EditMode.GetLayouts not available")
    end

    section("Other addons loaded")
    for _, name in ipairs(OTHER_ADDONS) do add("%s: %s", name, isLoaded(name) and "LOADED" or "no") end
    add("Snapshot done.")
end

---------------------------------------------------------------------------
-- Watch: logs the pad's buttons as they change (read only)
---------------------------------------------------------------------------
local watcher = CreateFrame("Frame")
watcher:Hide()
local prevButtons, prevPushed = {}, false
local function heldList(state, except)
    local list = {}
    for i = 1, state.buttonCount or 0 do
        if state.buttons[i] and i ~= except then
            list[#list + 1] = tostring(safe(C_GamePad.ButtonIndexToBinding, i - 1) or i)
        end
    end
    return table.concat(list, "+")
end
local function modifiers()
    return (IsShiftKeyDown() and "S" or "") .. (IsControlKeyDown() and "C" or "") .. (IsAltKeyDown() and "A" or "")
end
watcher:SetScript("OnUpdate", function()
    local state = mappedState()
    if not (state and state.buttons) then return end
    for i = 1, state.buttonCount or 0 do
        local down = state.buttons[i] and true or false
        if down ~= (prevButtons[i] or false) then
            prevButtons[i] = down
            add("pad %s %s  (held: %s, keyboard mods: %s)", down and "+" or "-",
                tostring(safe(C_GamePad.ButtonIndexToBinding, i - 1) or i), heldList(state, i), modifiers())
        end
    end
    local cam = state.sticks and state.sticks[cameraStick(state)]
    local pushed = cam and cam.len and cam.len > 0.5 or false
    if pushed ~= prevPushed then
        prevPushed = pushed
        if pushed then add("camera stick pushed x=%.2f y=%.2f", cam.x or 0, cam.y or 0) else add("camera stick back") end
    end
end)

---------------------------------------------------------------------------
-- Catch: temporary override bindings to a secure button that reads the pad
-- in the game's secure code, like a wheel would in combat
---------------------------------------------------------------------------
local owner = CreateFrame("Frame", "YBProbeBindingOwner")
local header = CreateFrame("Frame", "YBProbeHeader", UIParent, "SecureHandlerBaseTemplate")
local catch = CreateFrame("Button", "YBProbeCatch", UIParent, "SecureActionButtonTemplate")
catch:RegisterForClicks("AnyDown", "AnyUp")
catch:Hide()

local SECURE_READ = [[
    self:SetAttribute("ybp-btn", button)
    self:SetAttribute("ybp-down", down and 1 or 0)
    local s = GetGamePadState()
    if not s then
        self:SetAttribute("ybp-ok", 0)
        return
    end
    self:SetAttribute("ybp-ok", 1)
    local b = s.buttons
    local held = ""
    local lt, rt, lb, rb = self:GetAttribute("i-lt"), self:GetAttribute("i-rt"), self:GetAttribute("i-lb"), self:GetAttribute("i-rb")
    local l3, r3 = self:GetAttribute("i-l3"), self:GetAttribute("i-r3")
    if b then
        if lt and b[lt] then held = held .. "LT " end
        if rt and b[rt] then held = held .. "RT " end
        if lb and b[lb] then held = held .. "LB " end
        if rb and b[rb] then held = held .. "RB " end
        if l3 and b[l3] then held = held .. "L3 " end
        if r3 and b[r3] then held = held .. "R3 " end
    end
    self:SetAttribute("ybp-held", held)
    local cam = s.sticks and s.sticks[self:GetAttribute("i-cam") or 2]
    if cam then
        self:SetAttribute("ybp-cam", tostring(cam.x) .. "," .. tostring(cam.y))
    else
        self:SetAttribute("ybp-cam", "none")
    end
]]

local wrapped = false
local function prepareCatch()
    if not wrapped then
        local ok, err = pcall(SecureHandlerWrapScript, catch, "OnClick", header, SECURE_READ)
        add(ok and "Secure reader ready" or ("Secure reader FAILED: " .. tostring(err)))
        wrapped = ok
    end
    local st = mappedState()
    catch:SetAttribute("i-lt", padIndex("PADLTRIGGER"))
    catch:SetAttribute("i-rt", padIndex("PADRTRIGGER"))
    catch:SetAttribute("i-lb", padIndex("PADLSHOULDER"))
    catch:SetAttribute("i-rb", padIndex("PADRSHOULDER"))
    catch:SetAttribute("i-l3", padIndex("PADLSTICK"))
    catch:SetAttribute("i-r3", padIndex("PADRSTICK"))
    catch:SetAttribute("i-cam", cameraStick(st))
    catch:SetAttribute("ybp-ok", nil)
end

catch:HookScript("OnClick", function(self, button, down)
    local ok = self:GetAttribute("ybp-ok")
    local secure = ok == 1 and format("secure read OK, held: %s, camera stick %s", tostring(self:GetAttribute("ybp-held")),
        tostring(self:GetAttribute("ybp-cam"))) or (ok == 0 and "secure read: no pad state") or "secure read: snippet did not run"
    add("CAUGHT %s %s  (%s; keyboard mods: %s)", tostring(button), down and "down" or "up", secure, modifiers())
    self:SetAttribute("ybp-ok", nil)
end)

local bound = {}
local function bindCombo(combo, priority)
    local ok = pcall(SetOverrideBindingClick, owner, priority, combo, "YBProbeCatch", combo)
    local now = safe(GetBindingAction, combo, true)
    bound[#bound + 1] = combo
    if not ok or now ~= ("CLICK YBProbeCatch:" .. combo) then
        add("bind %s: not on top (now: %s)", combo, tostring(now))
    end
end

local function clearBindings()
    if #bound == 0 then return true end
    if InCombatLockdown() then return false end
    ClearOverrideBindings(owner)
    wipe(bound)
    add("Test bindings removed")
    return true
end

---------------------------------------------------------------------------
-- RT as a keyboard modifier (stage 4), always put back
---------------------------------------------------------------------------
local FREE = { [""] = true, none = true, NONE = true }
local function restoreModifier()
    local d = db()
    if d.cvarWas then
        local ok = pcall(SetCVar, d.cvarWas.name, d.cvarWas.value)
        add("%s put back to %s%s", d.cvarWas.name, tostring(d.cvarWas.value), ok and "" or " (FAILED)")
        d.cvarWas = nil
    end
end

local function rtAsModifier()
    for _, name in ipairs({ "GamePadEmulateShift", "GamePadEmulateCtrl", "GamePadEmulateAlt" }) do
        if cvar(name) == "PADRTRIGGER" then
            add("RT is already a modifier through %s", name)
            return true
        end
    end
    for _, name in ipairs({ "GamePadEmulateAlt", "GamePadEmulateCtrl" }) do
        local v = cvar(name)
        if FREE[v or ""] then
            db().cvarWas = { name = name, value = v or "" }
            local ok = pcall(SetCVar, name, "PADRTRIGGER")
            add("%s set to PADRTRIGGER: %s (reads back %s)", name, ok and "ok" or "FAILED", tostring(cvar(name)))
            return ok
        end
    end
    add("No free modifier setting: stage skipped")
    return false
end

---------------------------------------------------------------------------
-- Stages
---------------------------------------------------------------------------
local ORDER = "Slowly, one at a time: ZR+R (ZR first), R+ZR (R first), ZL+R, ZR+L, ZL+L, R3, ZL+R3, ZR+R3, L3, + and -."
local STAGES = {
    watch = { title = "1 Watch", text = "Only watching. " .. ORDER .. " Look at what the game does on ZR+R and ZL+L." },
    soft = { title = "2 Soft takeover", text = "The probe sits under the combinations; L, R, L3 and R3 alone still work as usual. " .. ORDER },
    full = { title = "3 Full takeover", text = "L, R, L3 and R3 now do nothing for the game. " .. ORDER .. " Then hold ZR+R while pushing the right stick up, and let go." },
    rtmod = { title = "4 RT modifier", text = "RT is a keyboard modifier for this stage only. " .. ORDER },
}

local stage, stageEnds
local ticker = CreateFrame("Frame")
ticker:Hide()

function P:Stop(reason)
    if not stage then return end
    watcher:Hide()
    ticker:Hide()
    local name = stage
    stage = nil
    if not clearBindings() then
        add("Combat: test bindings stay until combat ends")
        P.clearAfterCombat = true
    end
    if name == "rtmod" then restoreModifier() end
    add("Stage %s ended (%s)", STAGES[name].title, reason or "done")
    P:Status("Stage ended. Pick the next one, or Save.")
end

function P:Start(name)
    if not STAGES[name] then return end
    if InCombatLockdown() then
        add("Not in combat, please: stage not started")
        return
    end
    if stage then P:Stop("next stage") end
    section("Stage " .. STAGES[name].title)
    wipe(prevButtons)
    prevPushed = false
    if name ~= "watch" then
        prepareCatch()
        if name == "rtmod" and not rtAsModifier() then return end
        local priority = name == "full"
        for _, key in ipairs(TEST_KEYS) do
            for _, prefix in ipairs(PREFIXES) do
                if prefix ~= "" or name == "full" then bindCombo(prefix .. key, priority) end
            end
        end
        add("%d test bindings on, %s", #bound, priority and "with priority" or "without priority")
    end
    stage = name
    stageEnds = GetTime() + STAGE_SECONDS
    watcher:Show()
    ticker:Show()
    P:Status(STAGES[name].title .. ": " .. STAGES[name].text)
end

ticker:SetScript("OnUpdate", function()
    if not stage then return end
    local left = stageEnds - GetTime()
    if left <= 0 then
        P:Stop("time")
    elseif P.timer then
        P.timer:SetText(format("%d s left", left))
    end
end)

---------------------------------------------------------------------------
-- Chat from a secure button (the way the PC edition would send phrases)
---------------------------------------------------------------------------
local chatButton
local chatSentAt
local function makeChatButton(parent)
    local b = CreateFrame("Button", "YBProbeChatTest", parent, "SecureActionButtonTemplate,UIPanelButtonTemplate")
    b:SetSize(120, 24)
    b:SetText("Chat test")
    b:RegisterForClicks("AnyUp")
    b:SetAttribute("type", "macro")
    b:SetAttribute("macrotext", "/w " .. (UnitName("player") or "") .. " YB Probe: chat from a secure button works")
    b:HookScript("OnClick", function()
        chatSentAt = GetTime()
        add("Chat test clicked: whisper to yourself sent")
    end)
    return b
end

---------------------------------------------------------------------------
-- Window (mouse or the Switch touchscreen)
---------------------------------------------------------------------------
local frame, logText, statusText
local shown = {}

function P:Show(line)
    shown[#shown + 1] = line
    if #shown > 60 then table.remove(shown, 1) end
    if logText then logText:SetText(table.concat(shown, "\n")) end
end

function P:Status(text)
    if statusText then statusText:SetText(text) end
    if P.timer and not stage then P.timer:SetText("") end
end

local function button(parent, text, w, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, 24)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

function P:Window()
    if frame then
        frame:Show()
        return
    end
    if InCombatLockdown() then
        print("|cff33ff99YB Probe|r: open it out of combat, please.")
        return
    end
    frame = CreateFrame("Frame", "YBProbeFrame", UIParent, "BackdropTemplate")
    frame:SetSize(700, 470)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    frame:SetBackdropColor(0.05, 0.05, 0.08, 0.95)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("YB Probe " .. VERSION)
    P.timer = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    P.timer:SetPoint("TOPRIGHT", -40, -14)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    statusText:SetPoint("TOPLEFT", 14, -40)
    statusText:SetPoint("TOPRIGHT", -14, -40)
    statusText:SetJustifyH("LEFT")
    statusText:SetJustifyV("TOP")
    statusText:SetHeight(48)
    statusText:SetText("At the desk: Snapshot, then Save. On the Switch: Snapshot, stages 1 to 4, Chat test, then Save.")

    logText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    logText:SetPoint("TOPLEFT", 14, -96)
    logText:SetPoint("BOTTOMRIGHT", -14, 76)
    logText:SetJustifyH("LEFT")
    logText:SetJustifyV("BOTTOM")
    logText:SetWordWrap(true)

    local row1 = {
        button(frame, "Snapshot", 100, function() P:Snapshot() end),
        button(frame, "1 Watch", 100, function() P:Start("watch") end),
        button(frame, "2 Soft", 100, function() P:Start("soft") end),
        button(frame, "3 Full", 100, function() P:Start("full") end),
        button(frame, "4 RT modifier", 120, function() P:Start("rtmod") end),
    }
    for i, b in ipairs(row1) do
        if i == 1 then b:SetPoint("BOTTOMLEFT", 14, 44) else b:SetPoint("LEFT", row1[i - 1], "RIGHT", 8, 0) end
    end
    chatButton = makeChatButton(frame)
    chatButton:SetPoint("BOTTOMLEFT", 14, 12)
    local stop = button(frame, "Stop stage", 100, function() P:Stop("stopped") end)
    stop:SetPoint("LEFT", chatButton, "RIGHT", 8, 0)
    local save = button(frame, "Save (reload)", 120, function()
        if stage then P:Stop("saving") end
        add("Saving: the interface reloads now")
        ReloadUI()
    end)
    save:SetPoint("LEFT", stop, "RIGHT", 8, 0)
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("LEFT", save, "RIGHT", 12, 0)
    hint:SetText("Then send WTF\\...\\SavedVariables\\YBProbe.lua")
    P:Show("Ready.")
end

---------------------------------------------------------------------------
-- Events and command
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
events:RegisterEvent("CHAT_MSG_SYSTEM")
events:RegisterEvent("DISPLAY_SIZE_CHANGED")
events:SetScript("OnEvent", function(_, event, msg)
    if event == "PLAYER_LOGIN" then
        restoreModifier()
        add("Logged in")
        P:Window()   -- opens by itself: on the Switch there is no keyboard for /ybprobe
        print("|cff33ff99YB Probe|r loaded: its window opens at every login; /ybprobe opens it again.")
    elseif event == "PLAYER_REGEN_DISABLED" then
        if stage then add("Combat started during a stage") end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if P.clearAfterCombat then
            P.clearAfterCombat = nil
            clearBindings()
        end
    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        if chatSentAt and GetTime() - chatSentAt < 5 and type(msg) == "string" and msg:find("YB Probe") then
            add("Chat test: OK, the whisper went out")
            chatSentAt = nil
        end
    elseif event == "CHAT_MSG_SYSTEM" then
        if chatSentAt and GetTime() - chatSentAt < 5 then add("System message after chat test: %s", tostring(msg)) end
    elseif event == "DISPLAY_SIZE_CHANGED" then
        local pw, ph = safe(GetPhysicalScreenSize)
        add("Screen changed: %s x %s", tostring(pw), tostring(ph))
    end
end)

SLASH_YBPROBE1 = "/ybprobe"
SlashCmdList.YBPROBE = function(arg)
    arg = (arg or ""):lower():gsub("%s+", "")
    if arg == "snap" or arg == "snapshot" then
        P:Snapshot()
    elseif STAGES[arg] then
        P:Window()
        P:Start(arg)
    elseif arg == "stop" then
        P:Stop("stopped")
    elseif arg == "clear" then
        db().log = {}
        print("YB Probe: log cleared")
    else
        P:Window()
    end
end
