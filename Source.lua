local ADDON, ns = ...

-- Where the shopping list comes from.
--
-- ns.Source:Read() returns PSL's list as
--   { [itemID] = { need = number, have = number }, ... }
-- plus how it was read:
--
--   "api"      Profession Shopping List's own GetShoppingList(). Used
--              whenever the installed PSL has it.
--   "recipes"  For PSL releases that don't have it yet. Works the list out
--              from the recipes PSL is tracking (read from PSL's saved
--              data) and the game's own recipe information, using these
--              rules:
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

local Source = {}
ns.Source = Source

local BASIC_REAGENT = (Enum and Enum.CraftingReagentType and Enum.CraftingReagentType.Basic) or 1

local function OwnedCount(itemID)
  local ok, count = pcall(C_Item.GetItemCount, itemID, true, false, true, true)
  return ok and count or 0
end

local function PSLHasApi()
  return type(ProfessionShoppingList) == "table" and type(ProfessionShoppingList.GetShoppingList) == "function"
end

local function TrackedRecipes()
  local data = ProfessionShoppingList_Data
  if type(data) == "table" and type(data.Recipes) == "table" then
    return data.Recipes
  end
  return nil
end

-- "api", "recipes", or nil when PSL isn't there to read.
function Source:Via()
  if PSLHasApi() then
    return "api"
  end
  if type(ProfessionShoppingList) == "table" and TrackedRecipes() then
    return "recipes"
  end
  return nil
end

----------------------------------------------------------------------
-- The "recipes" way
----------------------------------------------------------------------

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

----------------------------------------------------------------------
-- The "api" way
----------------------------------------------------------------------

-- PSL's API answers { required, owned }; this addon calls them need/have.
local function ReadFromApi()
  local ok, answer = pcall(ProfessionShoppingList.GetShoppingList, ProfessionShoppingList)
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

function Source:Read()
  local via = self:Via()
  if via == "api" then
    local list = ReadFromApi()
    if list then
      return list, via
    end
  elseif via == "recipes" then
    local ok, list = pcall(ReadFromRecipes)
    if ok and list then
      return list, via
    end
  end
  return nil
end
