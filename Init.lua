local ADDON, ns = ...

-- PSL to TSM
-- Turns the reagents Profession Shopping List is tracking into a
-- TradeSkillMaster search string.
--
-- This file sets up the shared namespace: names, saved settings, a small
-- event hub other files subscribe through, and the "something changed,
-- redraw what's on screen" signal.

ns.TITLE = "PSL to TSM"

local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
ns.VERSION = getMetadata(ADDON, "Version") or "dev"

ns.DEFAULTS = {
  missingOnly = true,   -- search for what you still need, not the full amount
  loginMessage = false, -- print the version when you log in
}

----------------------------------------------------------------------
-- Chat output
----------------------------------------------------------------------

function ns.Say(message, ...)
  if select("#", ...) > 0 then
    message = message:format(...)
  end
  print("|cffffd100" .. ns.TITLE .. ":|r " .. message)
end

----------------------------------------------------------------------
-- Event hub
--
-- ns.On(event, fn) adds a listener. One frame carries every event; it's
-- parented to UIParent so it can never be garbage collected and go quiet.
----------------------------------------------------------------------

local listeners = {}
local hub = CreateFrame("Frame", nil, UIParent)

hub:SetScript("OnEvent", function(_, event, ...)
  for _, fn in ipairs(listeners[event]) do
    fn(...)
  end
end)

function ns.On(event, fn)
  if not listeners[event] then
    listeners[event] = {}
    hub:RegisterEvent(event)
  end
  table.insert(listeners[event], fn)
end

----------------------------------------------------------------------
-- Settings
----------------------------------------------------------------------

ns.On("ADDON_LOADED", function(name)
  if name ~= ADDON then
    return
  end
  PSLtoTSMDB = type(PSLtoTSMDB) == "table" and PSLtoTSMDB or {}
  PSLtoTSMDB.settings = type(PSLtoTSMDB.settings) == "table" and PSLtoTSMDB.settings or {}
  for key, value in pairs(ns.DEFAULTS) do
    if PSLtoTSMDB.settings[key] == nil then
      PSLtoTSMDB.settings[key] = value
    end
  end
  ns.settings = PSLtoTSMDB.settings
end)

function ns.ResetSettings()
  for key, value in pairs(ns.DEFAULTS) do
    ns.settings[key] = value
  end
end

----------------------------------------------------------------------
-- Views and change notification
--
-- Anything that shows the string (the AH tab, the copy window) registers
-- itself as a view with :IsShown() and :Update(fromPlayer). When PSL's
-- tracked recipes or your bags change, every view that's on screen
-- rebuilds. Changes arrive in bursts (looting, crafting a stack), so the
-- rebuild waits until things have been quiet for a moment and runs once.
----------------------------------------------------------------------

local views = {}
local REDRAW_DELAY = 0.5
local redrawQueued = false

function ns.AddView(view)
  table.insert(views, view)
end

function ns.Changed()
  if redrawQueued then
    return
  end
  redrawQueued = true
  C_Timer.After(REDRAW_DELAY, function()
    redrawQueued = false
    for _, view in ipairs(views) do
      if view:IsShown() then
        view:Update(false)
      end
    end
  end)
end

ns.On("BAG_UPDATE_DELAYED", ns.Changed)

ns.On("PLAYER_LOGIN", function()
  -- PSL announces changes to its tracked recipes through EventRegistry.
  if EventRegistry and EventRegistry.RegisterCallback then
    EventRegistry:RegisterCallback("ProfessionShoppingList.OnTrackedRecipesChanged", ns.Changed, ns)
  end
  if ns.settings.loginMessage then
    ns.Say("%s loaded. Type |cffffffff/psltsm help|r for commands.", ns.VERSION)
  end
end)
