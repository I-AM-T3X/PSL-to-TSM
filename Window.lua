local ADDON, ns = ...

-- A small movable window with the search string, opened with
-- /psltsm convert, or from the addon menu if PSL's window can't be used.
-- The backup for the TSM tab on PSL's window. Escape closes it.

local Style = ns.Style

local Window = {}
ns.Window = Window

local frame, view, status

local function Build()
  frame = Style.Frame("Frame", "PSLtoTSMWindow", UIParent)
  frame:SetSize(540, 300)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  table.insert(UISpecialFrames, "PSLtoTSMWindow")

  local title = Style.Text(frame, "GameFontNormal", Style.GOLD)
  title:SetPoint("TOPLEFT", 12, -10)
  title:SetText(ns.TITLE)

  local close = Style.Button(frame, "X", 22)
  close:SetPoint("TOPRIGHT", -6, -6)
  close:SetScript("OnClick", function() frame:Hide() end)

  status = Style.Text(frame, "GameFontHighlightSmall")
  status:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  status:SetPoint("RIGHT", -12, 0)

  view = ns.NewTextView(frame)
  view.bar:SetPoint("TOPRIGHT", -34, -6)
  view.well:SetPoint("TOPLEFT", 10, -62)
  view.well:SetPoint("BOTTOMRIGHT", -10, 28)
  view.hint:SetPoint("BOTTOMLEFT", 12, 9)

  ns.AddView(Window)
end

function Window:IsShown()
  return frame ~= nil and frame:IsShown()
end

function Window:Update(fromPlayer)
  local report = ns.Builder:Build()
  view:SetPages(report.pages, not fromPlayer)
  status:SetText(ns.Builder:Describe(report))
  if fromPlayer and report.toBuy > 0 then
    view:SelectAll()
  end
end

function Window:Open()
  if not frame then
    Build()
  end
  frame:Show()
  self:Update(true)
end

function Window:Toggle()
  if self:IsShown() then
    frame:Hide()
  else
    self:Open()
  end
end
