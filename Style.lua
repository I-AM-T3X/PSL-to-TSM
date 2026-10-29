local ADDON, ns = ...

-- Flat, dark look: solid fills with a 1px border, gold headings, white text.

local Style = {}
ns.Style = Style

local SOLID = "Interface\\Buttons\\WHITE8x8"

Style.PANEL = { 0.06, 0.06, 0.07, 0.96 }
Style.WELL = { 0.02, 0.02, 0.02, 1 }
Style.EDGE = { 0.24, 0.24, 0.26, 1 }
Style.EDGE_HOVER = { 1, 0.82, 0, 1 }
Style.BUTTON = { 0.13, 0.13, 0.15, 1 }
Style.BUTTON_HOVER = { 0.19, 0.19, 0.22, 1 }
Style.GOLD = { 1, 0.82, 0 }
Style.WHITE = { 1, 1, 1 }
Style.GREY = { 0.55, 0.55, 0.55 }

-- Gives a BackdropTemplate frame a solid fill and border.
function Style.Fill(frame, fill, edge)
  frame:SetBackdrop({ bgFile = SOLID, edgeFile = SOLID, edgeSize = 1 })
  frame:SetBackdropColor(unpack(fill or Style.PANEL))
  frame:SetBackdropBorderColor(unpack(edge or Style.EDGE))
end

function Style.Frame(kind, name, parent, fill)
  local frame = CreateFrame(kind or "Frame", name, parent, "BackdropTemplate")
  Style.Fill(frame, fill)
  return frame
end

function Style.Text(parent, font, color)
  local text = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
  text:SetTextColor(unpack(color or Style.WHITE))
  text:SetJustifyH("LEFT")
  return text
end

function Style.Button(parent, label, width)
  local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
  button:SetSize(width or 90, 22)
  Style.Fill(button, Style.BUTTON)

  local text = Style.Text(button, "GameFontHighlightSmall")
  text:SetPoint("CENTER")
  text:SetJustifyH("CENTER")
  text:SetText(label)
  button.label = text

  button:SetScript("OnEnter", function(self)
    if self:IsEnabled() then
      self:SetBackdropColor(unpack(Style.BUTTON_HOVER))
      self:SetBackdropBorderColor(unpack(Style.EDGE_HOVER))
    end
  end)
  button:SetScript("OnLeave", function(self)
    self:SetBackdropColor(unpack(Style.BUTTON))
    self:SetBackdropBorderColor(unpack(Style.EDGE))
  end)
  button:SetScript("OnDisable", function(self)
    self.label:SetTextColor(unpack(Style.GREY))
  end)
  button:SetScript("OnEnable", function(self)
    self.label:SetTextColor(unpack(Style.WHITE))
  end)
  return button
end

-- A labelled on/off box. read() returns the current value; write(value)
-- stores a new one. Call :Sync() to redraw it from read().
function Style.Check(parent, label, help, read, write)
  local box = CreateFrame("Button", nil, parent, "BackdropTemplate")
  box:SetSize(16, 16)
  Style.Fill(box, Style.WELL)

  local mark = box:CreateTexture(nil, "OVERLAY")
  mark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
  mark:SetPoint("CENTER")
  mark:SetSize(22, 22)

  local text = Style.Text(box, "GameFontHighlight")
  text:SetPoint("LEFT", box, "RIGHT", 8, 0)
  text:SetText(label)

  local note = Style.Text(box, "GameFontDisableSmall")
  note:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -3)
  note:SetWidth(520)
  note:SetText(help or "")

  function box:Sync()
    mark:SetShown(read() and true or false)
  end

  box:SetScript("OnClick", function(self)
    write(not read())
    self:Sync()
  end)
  box:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(Style.EDGE_HOVER)) end)
  box:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(Style.EDGE)) end)

  box.note = note
  return box
end
