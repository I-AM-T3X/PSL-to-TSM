local ADDON, ns = ...

-- Where the shopping list comes from.
--
-- ns.Source:Via() says how Profession Shopping List can be read:
--
--   "tsm"      PSL v12.1.5-02 and newer. PSL builds the TSM search string
--              itself (GetTSMSearchString), using its own rules, and
--              GetMerchantShoppingList gives the numbers behind it.
--   "recipes"  Older PSL releases. The list is worked out from the recipes
--              PSL is tracking (read from PSL's saved data) and the game's
--              own recipe information, using these rules:
--                - every basic reagent of each tracked recipe, times how
--                  many of that recipe are tracked
--                - the quality rank is PSL's "minimum reagent quality"
--                  setting, or the highest rank the reagent has if lower
--                - a recipe PSL tracked from a CraftSim simulation uses the
--                  exact reagents CraftSim picked
--                - "have" is how many of that exact item you own across
--                  bags, reagent bag, bank and Warband bank
--              Simpler than PSL's own math in a couple of places (it doesn't
--              count higher ranks toward lower ones, or subtract reagents a
--              crafting order's customer provides), so amounts can differ
--              from PSL's window there.
--   nil        PSL isn't there to read.

local Source = {}
ns.Source = Source

local BASIC_REAGENT = (Enum and Enum.CraftingReagentType and Enum.CraftingReagentType.Basic) or 1

local function PSLHas(method)
  return type(ProfessionShoppingList) == "table" and type(ProfessionShoppingList[method]) == "function"
end

local function TrackedRecipes()
  local data = ProfessionShoppingList_Data
  if type(data) == "table" and type(data.Recipes) == "table" then
    return data.Recipes
  end
  return nil
end

function Source:Via()
  if PSLHas("GetTSMSearchString") then
    return "tsm"
  end
  if type(ProfessionShoppingList) == "table" and TrackedRecipes() then
    return "recipes"
  end
  return nil
end

----------------------------------------------------------------------
-- The "tsm" way: PSL's own API
----------------------------------------------------------------------

-- PSL's string, or nil. PSL returns nothing both when there's nothing to
-- buy and when some item's details haven't loaded yet.
function Source:TSMString()
  local ok, text = pcall(ProfessionShoppingList.GetTSMSearchString, ProfessionShoppingList)
  if ok and type(text) == "string" and text ~= "" then
    return text
  end
  return nil
end

-- PSL's numbers as { [itemID] = { need, have } }, or nil. Called before
-- TSMString because it also brings PSL's reagent totals up to date.
function Source:MerchantList()
  if not PSLHas("GetMerchantShoppingList") then
    return nil
  end
  local ok, answer = pcall(ProfessionShoppingList.GetMerchantShoppingList, ProfessionShoppingList)
  if not ok or type(answer) ~= "table" then
    return nil
  end
  local list = {}
  for itemID, entry in pairs(answer) do
    if type(itemID) == "number" and type(entry) == "table" then
      list[itemID] = { need = tonumber(entry.required) or 0, have = tonumber(entry.owned) or 0 }
    end
  end
  return list
end

----------------------------------------------------------------------
-- The "recipes" way: older PSL releases
----------------------------------------------------------------------

local function OwnedCount(itemID)
  local ok, count = pcall(C_Item.GetItemCount, itemID, true, false, true, true)
  return ok and count or 0
end

-- PSL keys a tracked recipe by its recipe ID, or a crafting order by
-- "order:<orderID>:<recipeID>". Anything else (vendor items, currencies)
-- isn't bought on the Auction House and is skipped.
local function RecipeIDFromKey(key)
  if type(key) == "number" then
    return key
  end
  if type(key) == "string" then
    return tonumber(key:match("^order:%d+:(%d+)$"))
  end
  return nil
end

local function AddTo(totals, itemID, amount)
  if type(itemID) == "number" and itemID > 0 and amount > 0 then
    totals[itemID] = (totals[itemID] or 0) + amount
  end
end

local function AddRecipe(totals, recipeID, times, recraft, wantedRank)
  local ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, recraft and true or false)
  if not ok or type(schematic) ~= "table" then
    return
  end
  for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
    local ranks = slot.reagents
    if slot.reagentType == BASIC_REAGENT and type(ranks) == "table" and #ranks > 0 then
      local pick = ranks[math.min(wantedRank, #ranks)]
      AddTo(totals, pick and pick.itemID, (slot.quantityRequired or 0) * times)
    end
  end
end

local function ReadFromRecipes()
  local recipes = TrackedRecipes()
  if not recipes then
    return nil
  end

  local settings = type(ProfessionShoppingList_Settings) == "table" and ProfessionShoppingList_Settings or {}
  local cache = type(ProfessionShoppingList_Cache) == "table" and ProfessionShoppingList_Cache or {}
  local simulated = type(cache.SimulatedRecipes) == "table" and cache.SimulatedRecipes or {}
  local wantedRank = tonumber(settings.reagentQuality) or 1

  local totals = {}
  for key, tracked in pairs(recipes) do
    local recipeID = RecipeIDFromKey(key)
    if recipeID and type(tracked) == "table" then
      local times = tonumber(tracked.quantity) or 1
      local picked = tracked.simRecipe and simulated[key]
      if type(picked) == "table" then
        for itemID, amount in pairs(picked) do
          AddTo(totals, itemID, (tonumber(amount) or 0) * times)
        end
      else
        AddRecipe(totals, recipeID, times, tracked.recraft, wantedRank)
      end
    end
  end

  local list = {}
  for itemID, need in pairs(totals) do
    list[itemID] = { need = need, have = OwnedCount(itemID) }
  end
  return list
end

-- The worked-out list as { [itemID] = { need, have } }, or nil.
function Source:RecipeList()
  local ok, list = pcall(ReadFromRecipes)
  if ok then
    return list
  end
  return nil
end
