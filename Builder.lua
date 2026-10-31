local ADDON, ns = ...

-- Builds the TSM search string.
--
-- With PSL v12.1.5-02 or newer the string is PSL's own (GetTSMSearchString),
-- so PSL's rules decide what's in it. Its entries are sorted by item ID
-- here, so the string doesn't reshuffle every time it's rebuilt.
--
-- With older PSL releases it's built here from the worked-out list (see
-- Source.lua): every reagent becomes "i:<itemID>/x<amount>", joined with
-- ";".
--
-- Either way, TSM's search box won't take an endless string, so a long
-- result is also cut into pages of at most PAGE_LIMIT characters, always
-- between entries, to paste one at a time.

local Builder = {}
ns.Builder = Builder

Builder.PAGE_LIMIT = 1000

-- Bind types that can't be bought from other players (Enum.ItemBind):
-- 1 binds when picked up, 4 quest item, 7 to 9 warbound / Battle.net bound.
local CANT_BUY = { [1] = true, [4] = true, [7] = true, [8] = true, [9] = true }

-- Items whose details were asked for while PSL's string was empty. When one
-- arrives, whatever's on screen rebuilds.
local waitingFor = {}

ns.On("ITEM_DATA_LOAD_RESULT", function(itemID)
  if waitingFor[itemID] then
    waitingFor[itemID] = nil
    ns.Changed()
  end
end)

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

local function Count(list)
  local n = 0
  for _ in pairs(list or {}) do
    n = n + 1
  end
  return n
end

-- PSL's string, sorted. If it came back empty, checks whether that's
-- because item details are still loading, and asks for them if so.
local function FromPSLString(report)
  local list = ns.Source:MerchantList() -- first: also refreshes PSL's totals
  local text = ns.Source:TSMString()

  local entries = {}
  for entry in (text or ""):gmatch("[^;]+") do
    table.insert(entries, entry)
  end
  table.sort(entries, function(a, b)
    local idA, idB = tonumber(a:match("^i:(%d+)")), tonumber(b:match("^i:(%d+)"))
    if idA and idB and idA ~= idB then
      return idA < idB
    end
    return a < b
  end)

  if #entries == 0 and list then
    for itemID in pairs(list) do
      if C_Item.IsItemDataCachedByID and not C_Item.IsItemDataCachedByID(itemID) then
        waitingFor[itemID] = true
        report.loading = true
        if C_Item.RequestLoadItemDataByID then
          C_Item.RequestLoadItemDataByID(itemID)
        end
      end
    end
  end

  report.listed = list and Count(list) or #entries
  report.toBuy = #entries
  for _, item in pairs(list or {}) do
    if item.have >= item.need then
      report.haveEnough = report.haveEnough + 1
    end
  end
  report.skipped = math.max(0, report.listed - report.toBuy - report.haveEnough)
  return entries
end

-- Built here from the worked-out list (older PSL releases).
local function FromRecipeList(report)
  local list = ns.Source:RecipeList() or {}
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
      report.skipped = report.skipped + 1
    else
      table.insert(entries, "i:" .. itemID .. "/x" .. amount)
    end
  end
  report.toBuy = #entries
  return entries
end

-- Returns a report:
--   ready       false when PSL couldn't be read at all
--   via         "tsm" or "recipes" (see Source.lua)
--   loading     PSL's string is waiting on item details from the game
--   text        the whole search string
--   pages       the same string in pasteable pieces (always at least one)
--   listed      reagents PSL's list has
--   toBuy       entries in the string
--   haveEnough  left out because you already own enough
--   skipped     left out for another reason (can't be bought, or with PSL's
--               string, crafted by another tracked recipe)
function Builder:Build()
  local report = { ready = false, loading = false, text = "", pages = { "" },
    listed = 0, toBuy = 0, haveEnough = 0, skipped = 0 }

  local via = ns.Source:Via()
  if not via then
    return report
  end
  report.ready, report.via = true, via

  local entries
  if via == "tsm" then
    entries = FromPSLString(report)
  else
    entries = FromRecipeList(report)
  end

  report.text = table.concat(entries, ";")
  report.pages = Paginate(entries)
  return report
end

-- One or two lines describing a report.
function Builder:Describe(report)
  if not report.ready then
    return "Profession Shopping List isn't loaded."
  end
  if report.loading then
    return "Loading item info from the game..."
  end
  if report.listed == 0 then
    return "Profession Shopping List isn't tracking any recipes."
  end
  if report.toBuy == 0 then
    return ("Nothing to buy (%d reagents)."):format(report.listed)
  end

  local line = ("%d to buy"):format(report.toBuy)
  if report.haveEnough > 0 then
    line = line .. (", %d already owned"):format(report.haveEnough)
  end
  if report.skipped > 0 then
    line = line .. (", %d skipped"):format(report.skipped)
  end
  line = line .. "."
  if #report.pages > 1 then
    line = line .. ("\n|cffffd100Too long for one search: paste the %d parts one at a time.|r"):format(#report.pages)
  end
  return line
end
