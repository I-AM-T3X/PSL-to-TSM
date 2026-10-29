local ADDON, ns = ...

-- The "PSL to TSM" tab on Blizzard's Auction House window.
--
-- The tab itself comes from LibAHTab, which adds tabs to the Auction House
-- without tainting it. Only the library's public functions are used.
--
-- With several addons adding tabs, the row can run past the right edge of
-- the window. When ours would, it moves down to start a second row under
-- Blizzard's first tab instead. Only our own button is ever moved; the
-- window and everyone else's tabs are left exactly as they are.

local Style = ns.Style

local TAB_ID = "PSLtoTSM"

local Tab = {}
ns.AuctionTab = Tab

local panel, view, status, tabButton, homePoint

local function Library()
  return LibStub and LibStub("LibAHTab-1-0", true)
end

----------------------------------------------------------------------
-- The page shown when the tab is selected
----------------------------------------------------------------------

local function BuildPanel()
  panel = Style.Frame("Frame", "PSLtoTSMPanel", AuctionHouseFrame)
  panel:SetPoint("TOPLEFT", 4, -26)
  panel:SetPoint("BOTTOMRIGHT", -4, 28)

  -- Indented to clear the round portrait in the window's top-left corner.
  local heading = Style.Text(panel, "GameFontNormalLarge", Style.GOLD)
  heading:SetPoint("TOPLEFT", 62, -12)
  heading:SetText("Profession Shopping List")

  local refresh = Style.Button(panel, "Refresh", 80)
  refresh:SetPoint("LEFT", heading, "RIGHT", 14, 0)
  refresh:SetScript("OnClick", function() Tab:Update(true) end)

  view = ns.NewTextView(panel)
  view.bar:SetPoint("TOPRIGHT", -12, -10)

  status = Style.Text(panel, "GameFontHighlightSmall")
  status:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -10)
  status:SetPoint("RIGHT", -14, 0)

  view.well:SetPoint("TOPLEFT", 12, -74)
  view.well:SetPoint("BOTTOMRIGHT", -12, 30)
  view.hint:SetPoint("BOTTOMLEFT", 14, 10)

  local version = Style.Text(panel, "GameFontDisableSmall")
  version:SetPoint("BOTTOMRIGHT", -14, 10)
  version:SetText(ns.VERSION)

  panel:SetScript("OnShow", function() Tab:Update(false) end)
  ns.AddView(Tab)
end

function Tab:IsShown()
  return panel ~= nil and panel:IsVisible()
end

-- fromPlayer: the player asked for this (Refresh), so the finished string
-- is selected for copying. Automatic updates and opening the tab leave the
-- keyboard alone.
function Tab:Update(fromPlayer)
  local report = ns.Builder:Build()
  view:SetPages(report.pages, not fromPlayer)
  status:SetText(ns.Builder:Describe(report))
  if fromPlayer and report.toBuy > 0 then
    view:SelectAll()
  end
end

----------------------------------------------------------------------
-- Where the tab button sits
----------------------------------------------------------------------

local function RunsPastEdge()
  local right, edge = tabButton:GetRight(), AuctionHouseFrame:GetRight()
  return right ~= nil and edge ~= nil and right > edge
end

-- Puts the button back where LibAHTab placed it, then checks once the
-- layout has caught up (positions only update at the end of the frame) and
-- drops it to the second row if it doesn't fit.
local function PlaceButton()
  if not tabButton then
    return
  end
  tabButton:ClearAllPoints()
  tabButton:SetPoint(unpack(homePoint))
  C_Timer.After(0, function()
    if RunsPastEdge() then
      tabButton:ClearAllPoints()
      tabButton:SetPoint("TOPLEFT", AuctionHouseFrame.Tabs[1], "BOTTOMLEFT", 0, 6)
    end
  end)
end

local function CreateTab()
  local lib = Library()
  if not lib or not AuctionHouseFrame or lib:DoesIDExist(TAB_ID) then
    return
  end
  BuildPanel()
  lib:CreateTab(TAB_ID, panel, ns.TITLE, ns.TITLE)
  tabButton = lib:GetButton(TAB_ID)
  homePoint = { tabButton:GetPoint(1) }

  -- Look again whenever the row can have changed: the window opening, or
  -- any addon adding a tab of its own.
  AuctionHouseFrame:HookScript("OnShow", PlaceButton)
  hooksecurefunc(lib, "CreateTab", PlaceButton)
end

-- Blizzard's Auction House UI loads the first time the AH is opened.
ns.On("ADDON_LOADED", function(name)
  if name == "Blizzard_AuctionHouseUI" then
    CreateTab()
  end
end)

ns.On("PLAYER_LOGIN", function()
  local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
  if isLoaded("Blizzard_AuctionHouseUI") then
    CreateTab()
  end
end)

-- Switches to the tab. False when the Auction House isn't open.
function Tab:Select()
  local lib = Library()
  if not (lib and AuctionHouseFrame and AuctionHouseFrame:IsShown() and lib:DoesIDExist(TAB_ID)) then
    return false
  end
  lib:SetSelected(TAB_ID)
  return true
end
