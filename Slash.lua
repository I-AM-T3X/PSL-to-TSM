local ADDON, ns = ...

-- /psltsm (or /psltotsm) and the addon menu entry by the minimap.

local Slash = {}
ns.Slash = Slash

local function OnOff(value)
  return value and "|cff40ff40on|r" or "|cffff5050off|r"
end

-- Shared by the on/off commands: "on", "off", or nothing to flip it.
-- Returns true if the setting changed.
local function Switch(key, word, name)
  local value
  if word == "on" then
    value = true
  elseif word == "off" then
    value = false
  elseif word == "" then
    value = not ns.settings[key]
  else
    ns.Say("Use |cffffffffon|r or |cffffffffoff|r, not '%s'.", word)
    return false
  end
  ns.settings[key] = value
  ns.Say("%s: %s", name, OnOff(value))
  return true
end

local function OpenSettings()
  ns.Options:Open()
end

-- In the order help lists them. `also` are extra words for the same command.
local COMMANDS = {
  { word = "settings", also = { "", "options", "config" }, usage = "open the settings (plain /psltsm does too)",
    run = OpenSettings },
  { word = "convert", usage = "show the search string in a window, anywhere",
    run = function()
      if not ns.Source:Via() then
        ns.Say("Profession Shopping List isn't loaded.")
        return
      end
      ns.Window:Open()
    end },
  { word = "tab", usage = "switch to the PSL to TSM tab (Auction House must be open)",
    run = function()
      if not ns.AuctionTab:Select() then
        ns.Say("Open the Auction House first, or use |cffffffff/psltsm convert|r.")
      end
    end },
  { word = "owned", usage = "on/off: only buy what you're missing",
    run = function(rest)
      if Switch("missingOnly", rest, "Only buy what I'm missing") then
        ns.Changed()
      end
    end },
  { word = "login", usage = "on/off: version message at login",
    run = function(rest) Switch("loginMessage", rest, "Login message") end },
  { word = "status", usage = "show settings and the PSL connection",
    run = function()
      ns.Say(ns.VERSION)
      for _, switch in ipairs(ns.Options.SWITCHES) do
        print(("   %s: %s"):format(switch.label, OnOff(ns.settings[switch.key])))
      end
      print("   " .. ns.Options.SourceLine())
    end },
  { word = "reset", usage = "put the settings back to their defaults",
    run = function()
      ns.ResetSettings()
      ns.Say("Settings reset.")
      ns.Changed()
    end },
  { word = "help", usage = "list these commands",
    run = function() Slash.Help() end },
}

local byWord = {}
for _, command in ipairs(COMMANDS) do
  byWord[command.word] = command
  for _, word in ipairs(command.also or {}) do
    byWord[word] = command
  end
end

function Slash.Help()
  ns.Say("%s commands:", ns.VERSION)
  for _, command in ipairs(COMMANDS) do
    print(("   |cffffd100/psltsm %s|r - %s"):format(command.word, command.usage))
  end
end

function Slash.Run(input)
  local word, rest = (input or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
  local command = byWord[word]
  if command then
    command.run(rest)
  else
    ns.Say("Unknown command '%s'.", word)
    Slash.Help()
  end
end

SLASH_PSLTOTSM1 = "/psltsm"
SLASH_PSLTOTSM2 = "/psltotsm"
SlashCmdList.PSLTOTSM = Slash.Run

----------------------------------------------------------------------
-- Addon menu (the compartment button by the minimap). The TOC names
-- these functions, so they have to be globals.
----------------------------------------------------------------------

function PSLtoTSM_OnAddonCompartmentClick(_, mouseButton)
  if mouseButton == "RightButton" then
    OpenSettings()
  elseif not ns.AuctionTab:Select() then
    ns.Window:Toggle()
  end
end

function PSLtoTSM_OnAddonCompartmentEnter(_, menuButton)
  GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
  GameTooltip:AddLine(ns.TITLE)
  GameTooltip:AddLine("Left-click: the search string", 1, 1, 1)
  GameTooltip:AddLine("Right-click: settings", 1, 1, 1)
  GameTooltip:Show()
end

function PSLtoTSM_OnAddonCompartmentLeave()
  GameTooltip:Hide()
end
