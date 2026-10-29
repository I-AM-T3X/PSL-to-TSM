local ADDON, ns = ...

-- The box the search string is shown in, shared by the AH tab and the
-- window.
--
--   local view = ns.NewTextView(parent)
--   view.well    the dark box with the text (anchor it where you want it)
--   view.bar     page arrows, "Part x of y" and Select All (anchor it too)
--   view.hint    "Select All, then Ctrl+C" line (anchor it too)
--   view:SetPages(pages, keepPlace)
--   view:SelectAll()
--
-- WoW gives addons no clipboard access, so copying is always the player's
-- Ctrl+C. The box only takes keyboard focus when the player does something
-- (clicks it, pages, clicks Select All or Refresh), never by itself.

local Style = ns.Style

local function SamePages(a, b)
  if #a ~= #b then
    return false
  end
  for i = 1, #a do
    if a[i] ~= b[i] then
      return false
    end
  end
  return true
end

function ns.NewTextView(parent)
  local view = { pages = { "" }, page = 1 }

  -- The text well
  local well = Style.Frame("Frame", nil, parent, Style.WELL)
  view.well = well

  local scroll = CreateFrame("ScrollFrame", nil, well, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 6, -6)
  scroll:SetPoint("BOTTOMRIGHT", -26, 6)
  -- Only show the scroll bar when the text is long enough to need it. The
  -- template shows or hides it by this flag whenever the scroll range
  -- changes; it starts hidden because a fresh box has nothing to scroll.
  scroll.scrollBarHideable = true
  if scroll.ScrollBar then
    scroll.ScrollBar:Hide()
  end

  local edit = CreateFrame("EditBox", nil, scroll)
  edit:SetMultiLine(true)
  edit:SetAutoFocus(false)
  edit:SetMaxLetters(0)
  edit:SetFontObject(ChatFontNormal)
  edit:SetTextInsets(2, 2, 2, 2)
  scroll:SetScrollChild(edit)
  view.edit = edit

  -- A scroll child needs a real width to wrap text against.
  scroll:SetScript("OnSizeChanged", function(_, width)
    edit:SetWidth(width)
  end)

  edit:SetScript("OnEscapePressed", edit.ClearFocus)
  edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  -- The box has to accept input to be selectable, but its text is never
  -- meant to change: anything typed is put straight back.
  edit:SetScript("OnTextChanged", function(self, typed)
    local shown = view.pages[view.page] or ""
    if typed and self:GetText() ~= shown then
      self:SetText(shown)
      self:HighlightText()
    end
  end)
  well:SetScript("OnMouseDown", function() edit:SetFocus() end)

  -- Controls: [Part x of y] [<] [>] [Select All]
  local bar = CreateFrame("Frame", nil, parent)
  bar:SetSize(260, 22)
  view.bar = bar

  local selectAll = Style.Button(bar, "Select All", 84)
  selectAll:SetPoint("RIGHT")
  local nextPart = Style.Button(bar, ">", 24)
  nextPart:SetPoint("RIGHT", selectAll, "LEFT", -6, 0)
  local prevPart = Style.Button(bar, "<", 24)
  prevPart:SetPoint("RIGHT", nextPart, "LEFT", -3, 0)
  local partLabel = Style.Text(bar, "GameFontNormalSmall", Style.GOLD)
  partLabel:SetPoint("RIGHT", prevPart, "LEFT", -8, 0)

  local hint = Style.Text(parent, "GameFontDisableSmall")
  hint:SetText(("Select All, then %s to copy."):format((IsMacClient and IsMacClient()) and "Cmd+C" or "Ctrl+C"))
  view.hint = hint

  function view:SelectAll()
    edit:SetFocus()
    edit:HighlightText()
  end

  function view:Turn(page)
    self.page = math.max(1, math.min(page, #self.pages))
    edit:SetText(self.pages[self.page])
    edit:SetCursorPosition(0)
    scroll:SetVerticalScroll(0)

    local several = #self.pages > 1
    partLabel:SetShown(several)
    prevPart:SetShown(several)
    nextPart:SetShown(several)
    partLabel:SetText(("Part %d of %d"):format(self.page, #self.pages))
    prevPart:SetEnabled(self.page > 1)
    nextPart:SetEnabled(self.page < #self.pages)
  end

  -- keepPlace is for updates the player didn't ask for: if nothing changed
  -- the box isn't touched at all (a selection survives), and if something
  -- did, the player stays on the part they were pasting.
  function view:SetPages(pages, keepPlace)
    if type(pages) ~= "table" or #pages == 0 then
      pages = { "" }
    end
    if keepPlace and SamePages(pages, self.pages) then
      return
    end
    self.pages = pages
    self:Turn(keepPlace and self.page or 1)
  end

  selectAll:SetScript("OnClick", function() view:SelectAll() end)
  prevPart:SetScript("OnClick", function() view:Turn(view.page - 1); view:SelectAll() end)
  nextPart:SetScript("OnClick", function() view:Turn(view.page + 1); view:SelectAll() end)

  view:Turn(1)
  return view
end
