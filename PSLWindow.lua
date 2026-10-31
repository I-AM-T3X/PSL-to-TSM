local ADDON, ns = ...

-- Two tabs under Profession Shopping List's tracking window:
--
--   Shopping List   PSL's window exactly as PSL draws it
--   TSM             PSL's list swapped for the TSM search string, ready to
--                   copy, so it can be grabbed while TSM's Auction House
--                   window is open
--
-- Done with Slackluster's OK. PSL's window is the global frame
-- "PSLTrackingWindow", and everything PSL shows in it lives in its
-- .ScrollFrame; the TSM tab hides that and shows ours in its place. The
-- tabs are drawn to match PSL's window (black, blue tooltip border).
--
-- If PSL's window ever changes shape so it can't be hooked, the tabs just
-- don't appear, and /psltsm convert still opens the string in its own
-- window.

local Style = ns.Style

local PSLWindow = {}
ns.PSLWindow = PSLWindow

local PSL_BORDER = { 0.25, 0.78, 0.92, 1 }
local TAB_BACKDROP = {
  bgFile = "Interface/Tooltips/UI-Tooltip-Background",
  edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
  edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local win, panel, view, status
local listTab, tsmTab
local onTSM = false

local function FindWindow()
  local frame = _G.PSLTrackingWindow
  if type(frame) == "table" and type(frame.ScrollFrame) == "table" and frame.HookScript then
    return frame
  end
  return nil
end

local function PaintTab(tab, selected)
  tab:SetBackdropColor(0, 0, 0, selected and 1 or 0.75)
  tab:SetBackdropBorderColor(unpack(PSL_BORDER))
  tab.label:SetTextColor(unpack(selected and Style.GOLD or Style.GREY))
end

local function MakeTab(text, onClick)
  local tab = CreateFrame("Button", nil, win, "BackdropTemplate")
  tab:SetBackdrop(TAB_BACKDROP)
  tab.label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  tab.label:SetPoint("CENTER", 0, 1)
  tab.label:SetText(text)
  tab:SetSize(math.max(64, tab.label:GetStringWidth() + 26), 22)
  tab:SetScript("OnClick", onClick)
  return tab
end

local function BuildPanel()
  -- Below PSL's row of buttons at the top, and clear of its resize corner.
  panel = CreateFrame("Frame", nil, win)
  panel:SetPoint("TOPLEFT", 9, -26)
  panel:SetPoint("BOTTOMRIGHT", -9, 18)
  panel:Hide()

  status = Style.Text(panel, "GameFontHighlightSmall")
  status:SetPoint("TOPLEFT")
  status:SetPoint("RIGHT")

  view = ns.NewTextView(panel, true)
  view.well:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -6)
  view.well:SetPoint("BOTTOMRIGHT", 0, 28)
  view.bar:SetPoint("BOTTOMRIGHT")
  view.hint:Hide() -- no room; the Select All button says enough here
end

-- Switches tabs. fromPlayer: a click, so the string is selected for copying.
function PSLWindow:Show(tab, fromPlayer)
  if not win then
    return
  end
  onTSM = tab == "tsm"
  win.ScrollFrame:SetShown(not onTSM)
  panel:SetShown(onTSM)
  PaintTab(listTab, not onTSM)
  PaintTab(tsmTab, onTSM)
  if onTSM then
    self:Update(fromPlayer)
  end
end

function PSLWindow:IsShown()
  return panel ~= nil and panel:IsVisible()
end

function PSLWindow:Update(fromPlayer)
  local report = ns.Builder:Build()
  view:SetPages(report.pages, not fromPlayer)
  status:SetText(ns.Builder:Describe(report))
  if fromPlayer and report.toBuy > 0 then
    view:SelectAll()
  end
end

function PSLWindow:IsHooked()
  return win ~= nil
end

-- Opens PSL's window on the TSM tab. False if PSL's window couldn't be
-- hooked or opened.
function PSLWindow:Open()
  if not win then
    return false
  end
  if not win:IsShown() and type(ProfessionShoppingList.ToggleWindow) == "function" then
    pcall(ProfessionShoppingList.ToggleWindow, ProfessionShoppingList)
  end
  if not win:IsShown() then
    return false
  end
  self:Show("tsm", true)
  return true
end

ns.On("PLAYER_LOGIN", function()
  -- PSL builds its window while it loads, which is before PSL to TSM.
  win = FindWindow()
  if not win then
    return
  end

  BuildPanel()
  listTab = MakeTab("Shopping List", function() PSLWindow:Show("list", true) end)
  tsmTab = MakeTab("TSM", function() PSLWindow:Show("tsm", true) end)
  listTab:SetPoint("TOPLEFT", win, "BOTTOMLEFT", 8, 2)
  tsmTab:SetPoint("LEFT", listTab, "RIGHT", 2, 0)

  -- Reopening the window keeps whichever tab was last picked, up to date.
  win:HookScript("OnShow", function()
    if onTSM then
      PSLWindow:Update(false)
    end
  end)

  PSLWindow:Show("list", false)
  ns.AddView(PSLWindow)
end)
