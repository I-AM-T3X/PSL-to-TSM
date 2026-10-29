local ADDON, ns = ...

-- The PSL to TSM page in the game's Settings window.

local Style = ns.Style

local Options = {}
ns.Options = Options

-- Shared with /psltsm status, so both list the same switches.
Options.SWITCHES = {
  {
    key = "missingOnly",
    label = "Only buy what I'm missing",
    help = "Each amount is what the tracked recipes need minus what you already own, "
      .. "and reagents you have enough of are left out. Off: search for the full amount.",
    changesString = true,
  },
  {
    key = "loginMessage",
    label = "Show a message when I log in",
    help = "Prints the addon version to chat at login.",
  },
}

function Options.SourceLine()
  local via = ns.Source:Via()
  if via == "api" then
    return "Profession Shopping List: |cff40ff40connected|r"
  elseif via == "recipes" then
    return "Profession Shopping List: |cff40ff40connected|r |cff999999(working from tracked recipes "
      .. "until your PSL has GetShoppingList; switches over by itself after you update it)|r"
  end
  return "Profession Shopping List: |cffff5050not loaded|r"
end

local function Build()
  local page = CreateFrame("Frame")

  local heading = Style.Text(page, "GameFontNormalHuge", Style.GOLD)
  heading:SetPoint("TOPLEFT", 16, -16)
  heading:SetText(ns.TITLE)

  local version = Style.Text(page, "GameFontDisableSmall")
  version:SetPoint("BOTTOMLEFT", heading, "BOTTOMRIGHT", 8, 3)
  version:SetText(ns.VERSION)

  local boxes = {}
  local above, gap = heading, -22
  for _, switch in ipairs(Options.SWITCHES) do
    local box = Style.Check(page, switch.label, switch.help,
      function() return ns.settings[switch.key] end,
      function(value)
        ns.settings[switch.key] = value
        if switch.changesString then
          ns.Changed()
        end
      end)
    box:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, gap)
    table.insert(boxes, box)
    above, gap = box.note, -16
  end

  local source = Style.Text(page, "GameFontHighlight")
  source:SetPoint("TOPLEFT", above, "BOTTOMLEFT", -24, -24)
  source:SetPoint("RIGHT", -16, 0)

  page:SetScript("OnShow", function()
    for _, box in ipairs(boxes) do
      box:Sync()
    end
    source:SetText(Options.SourceLine())
  end)

  return page
end

local category

function Options:Open()
  if category then
    -- Needs the numeric category ID, not the name.
    Settings.OpenToCategory(category:GetID())
  end
end

ns.On("PLAYER_LOGIN", function()
  category = Settings.RegisterCanvasLayoutCategory(Build(), ns.TITLE)
  Settings.RegisterAddOnCategory(category)
end)
