local ADDON, ns = ...

-- PSL to TSM in the game's Settings window: the settings page, with a
-- Changelog page under it (the addon's entry expands to show it).

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
    -- With PSL v12.1.5-02 and newer, PSL builds the string and decides the
    -- amounts itself, so this only applies to older PSL releases.
    onlyFor = "recipes",
    inactiveHelp = "Your Profession Shopping List builds the string itself and already searches "
      .. "for only what you're missing, so this switch doesn't apply.",
  },
  {
    key = "loginMessage",
    label = "Show a message when I log in",
    help = "Prints the addon version to chat at login.",
  },
}

function Options.SourceLine()
  local via = ns.Source:Via()
  if via == "tsm" then
    return "Profession Shopping List: |cff40ff40connected|r"
  elseif via == "recipes" then
    return "Profession Shopping List: |cff40ff40connected|r |cff999999(older version: working from "
      .. "tracked recipes. Update PSL to v12.1.5-02 or newer for its own TSM string.)|r"
  end
  return "Profession Shopping List: |cffff5050not loaded|r"
end

----------------------------------------------------------------------
-- Changelog page (its own entry under PSL to TSM in the Settings list)
----------------------------------------------------------------------

-- Tag colors, as hex for color codes.
local TAG_COLORS = {
  New = "40ff40",
  Changed = "66b3ff",
  Fix = "ff9933",
  Removed = "ff5959",
  Upkeep = "bfbfbf",
}

local ROW_GAP = 4       -- between an entry and its detail
local ENTRY_GAP = 10    -- between entries
local RELEASE_GAP = 16  -- above and below the divider between versions
local DETAIL_INDENT = 18

-- Builds every row once. Each row is { region, indent, gapAbove, isDivider };
-- Layout() positions them for the current width.
local function BuildChangelogRows(content)
  local rows = {}
  local function Add(region, indent, gapAbove, isDivider)
    rows[#rows + 1] = { region = region, indent = indent or 0, gapAbove = gapAbove or 0, isDivider = isDivider }
  end

  for i, release in ipairs(ns.CHANGELOG or {}) do
    if i > 1 then
      local divider = content:CreateTexture(nil, "ARTWORK")
      divider:SetTexture("Interface\\Buttons\\WHITE8x8")
      divider:SetVertexColor(unpack(Style.EDGE))
      divider:SetHeight(1)
      Add(divider, 0, RELEASE_GAP, true)
    end

    local header = Style.Text(content, "GameFontNormalLarge", Style.GOLD)
    header:SetText(("v%s   |cff999999%s|r"):format(release.version, release.date))
    Add(header, 0, i > 1 and RELEASE_GAP or 0)

    for _, entry in ipairs(release.entries) do
      local title = Style.Text(content, "GameFontHighlight")
      title:SetText(("|cff%s[%s]|r  %s"):format(TAG_COLORS[entry.tag] or "ffffff", entry.tag, entry.title))
      Add(title, 0, ENTRY_GAP)
      if entry.detail then
        local detail = Style.Text(content, "GameFontHighlightSmall", Style.GREY)
        detail:SetText(entry.detail)
        Add(detail, DETAIL_INDENT, ROW_GAP)
      end
    end
  end
  return rows
end

local function BuildChangelogPage()
  local page = CreateFrame("Frame")

  local heading = Style.Text(page, "GameFontNormalHuge", Style.GOLD)
  heading:SetPoint("TOPLEFT", 16, -16)
  heading:SetText("Changelog")

  local version = Style.Text(page, "GameFontDisableSmall")
  version:SetPoint("BOTTOMLEFT", heading, "BOTTOMRIGHT", 8, 3)
  version:SetText(ns.TITLE .. " " .. ns.VERSION)

  local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -18)
  scroll:SetPoint("BOTTOMRIGHT", -32, 16)
  scroll.scrollBarHideable = true
  if scroll.ScrollBar then
    scroll.ScrollBar:Hide()
  end

  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(1, 1)
  scroll:SetScrollChild(content)

  local rows = BuildChangelogRows(content)

  -- Stacks the rows top to bottom at the current width, wrapping long text,
  -- and makes the scroll area exactly as tall as the result.
  local function Layout()
    local width = scroll:GetWidth()
    if not width or width <= 0 then
      return
    end
    content:SetWidth(width)
    local y = 0
    for _, row in ipairs(rows) do
      y = y + row.gapAbove
      local region = row.region
      region:ClearAllPoints()
      region:SetPoint("TOPLEFT", content, "TOPLEFT", row.indent, -y)
      if row.isDivider then
        region:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -y)
        y = y + 1
      else
        region:SetWidth(width - row.indent)
        y = y + region:GetStringHeight()
      end
    end
    content:SetHeight(y + 8)
  end

  scroll:SetScript("OnSizeChanged", Layout)
  page:SetScript("OnShow", Layout)
  return page
end

----------------------------------------------------------------------
-- Settings page
----------------------------------------------------------------------

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
    box.switch = switch
    table.insert(boxes, box)
    above, gap = box.note, -16
  end

  local source = Style.Text(page, "GameFontHighlight")
  source:SetPoint("TOPLEFT", above, "BOTTOMLEFT", -24, -24)
  source:SetPoint("RIGHT", -16, 0)

  page:SetScript("OnShow", function()
    local via = ns.Source:Via()
    for _, box in ipairs(boxes) do
      local active = not box.switch.onlyFor or box.switch.onlyFor == via
      box:Sync()
      box:SetActive(active)
      box.note:SetText(active and box.switch.help or box.switch.inactiveHelp)
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
  Settings.RegisterCanvasLayoutSubcategory(category, BuildChangelogPage(), "Changelog")
  Settings.RegisterAddOnCategory(category)
end)
