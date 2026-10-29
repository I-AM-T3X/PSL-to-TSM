local ADDON, ns = ...

-- Builds the TSM search string from the shopping list.
--
-- Every reagent becomes "i:<itemID>/x<amount>", and the entries are joined
-- with ";". TSM's search box won't take an endless string, so a long result
-- is also cut into pages of at most PAGE_LIMIT characters, always between
-- entries, to paste one at a time.

local Builder = {}
ns.Builder = Builder

Builder.PAGE_LIMIT = 1000

-- Bind types that can't be bought from other players (Enum.ItemBind):
-- 1 binds when picked up, 4 is a quest item.
local CANT_BUY = { [1] = true, [4] = true }

-- True only when the game says so. An item whose details aren't loaded yet
-- counts as buyable rather than being dropped.
local function CantBeBought(itemID)
  if not C_Item.GetItemInfo then
    return false
  end
  local name, _, _, _, _, _, _, _, _, _, _, _, _, bindType = C_Item.GetItemInfo(itemID)
  return name ~= nil and CANT_BUY[bindType] == true
end

local function Paginate(entries)
  local pages = {}
  local page = ""
  for _, entry in ipairs(entries) do
    if page == "" then
      page = entry
    elseif #page + 1 + #entry <= Builder.PAGE_LIMIT then
      page = page .. ";" .. entry
    else
      table.insert(pages, page)
      page = entry
    end
  end
  table.insert(pages, page)
  return pages
end

-- Returns a report:
--   ready       false when PSL couldn't be read at all
--   via         how it was read ("api" or "recipes", see Source.lua)
--   text        the whole search string
--   pages       the same string in pasteable pieces (always at least one)
--   listed      reagents on PSL's list
--   toBuy       reagents in the string
--   haveEnough  left out because you already own enough
--   cantBuy     left out because they're soulbound or quest items
function Builder:Build()
  local report = { ready = false, text = "", pages = { "" }, listed = 0, toBuy = 0, haveEnough = 0, cantBuy = 0 }

  local list, via = ns.Source:Read()
  if not list then
    return report
  end
  report.ready, report.via = true, via

  local ids = {}
  for itemID in pairs(list) do
    table.insert(ids, itemID)
  end
  table.sort(ids) -- same order every time, so a refresh doesn't shuffle it
  report.listed = #ids

  local missingOnly = ns.settings.missingOnly
  local entries = {}
  for _, itemID in ipairs(ids) do
    local item = list[itemID]
    local amount = math.ceil(missingOnly and (item.need - item.have) or item.need)
    if amount < 1 then
      report.haveEnough = report.haveEnough + 1
    elseif CantBeBought(itemID) then
      report.cantBuy = report.cantBuy + 1
    else
      table.insert(entries, "i:" .. itemID .. "/x" .. amount)
    end
  end

  report.toBuy = #entries
  report.text = table.concat(entries, ";")
  report.pages = Paginate(entries)
  return report
end

-- One or two lines describing a report, for the tab and the window.
function Builder:Describe(report)
  if not report.ready then
    return "Profession Shopping List isn't loaded."
  end
  if report.listed == 0 then
    return "Profession Shopping List isn't tracking any recipes."
  end
  if report.toBuy == 0 then
    return ("You already have everything (%d reagents)."):format(report.listed)
  end

  local line = ("%d to buy"):format(report.toBuy)
  if report.haveEnough > 0 then
    line = line .. (", %d already owned"):format(report.haveEnough)
  end
  if report.cantBuy > 0 then
    line = line .. (", %d soulbound or quest"):format(report.cantBuy)
  end
  line = line .. "."
  if #report.pages > 1 then
    line = line .. ("\n|cffffd100Too long for one search: paste the %d parts one at a time.|r"):format(#report.pages)
  end
  return line
end
