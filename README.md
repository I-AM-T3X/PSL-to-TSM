# PSL to TSM

A World of Warcraft addon that turns the reagents
[Profession Shopping List](https://www.curseforge.com/wow/addons/profession-shopping-list)
(PSL) is tracking into a [TradeSkillMaster](https://www.tradeskillmaster.com/)
search string you can paste straight into TSM.

Built for Midnight (retail, interface 120007 / 120100 / 120105).

## What it does

- Every reagent becomes an exact `i:<itemID>/x<amount>` entry, quality rank
  included, so TSM searches for exactly the right item. No name searches,
  no Auction House lookups.
- By default each amount is what you're still missing after what you own.
  Reagents you already have enough of are left out, and so are soulbound and
  quest items, since they can't be bought.
- The string updates on its own when you track or untrack recipes in PSL, or
  when your bags change.
- Long lists are split into parts that fit TSM's search box. `<` and `>` page
  through them, and each part is selected as you go.

## Using it

- **PSL to TSM tab** on the Blizzard Auction House window.
- **`/psltsm convert`** opens the string in a small window anywhere,
  including over TSM's own Auction House window.
- **Addon menu** by the minimap: left-click for the string (the tab at the
  Auction House, the window anywhere else), right-click for settings.

Click **Select All**, press Ctrl+C (Cmd+C on Mac), and paste into TSM.

### Commands

| Command | What it does |
| --- | --- |
| `/psltsm` | Open the settings |
| `/psltsm convert` | Show the string in a window |
| `/psltsm tab` | Switch to the PSL to TSM tab (Auction House open) |
| `/psltsm owned on\|off` | Only buy what you're missing |
| `/psltsm login on\|off` | Version message at login |
| `/psltsm status` | Settings and PSL connection |
| `/psltsm reset` | Default settings |
| `/psltsm help` | List the commands |

`/psltotsm` works too.

### Settings

| Setting | Default | Saved as |
| --- | --- | --- |
| Only buy what I'm missing | On | `missingOnly` |
| Show a message when I log in | Off | `loginMessage` |

Stored account-wide in `PSLtoTSMDB.settings`.

## Requirements

- **Profession Shopping List** (required). Newer releases share their list
  through `ProfessionShoppingList:GetShoppingList()`, and that's what gets
  used. Releases without it (v12.1.5-01 and older) still work: the addon
  works the list out from the recipes PSL is tracking instead (see below).
- **TradeSkillMaster** to paste the string into. Not needed to run, and
  never called by this addon.

## How it works

`Source.lua` reads PSL in one of two ways and hands back
`{ [itemID] = { need, have } }`:

- **`api`**: PSL's own `GetShoppingList()`, whenever the installed PSL has
  it. These numbers match PSL's window exactly.
- **`recipes`**: for older PSL releases. Reads PSL's saved list of tracked
  recipes (`ProfessionShoppingList_Data.Recipes`) and asks the game for each
  recipe's reagents. Rules:
  - every basic reagent, times how many of that recipe are tracked
  - quality rank from PSL's "minimum reagent quality" setting, or the
    highest rank the reagent has if that's lower
  - recipes PSL tracked from a CraftSim simulation use CraftSim's exact picks
  - "have" is your count of that exact item across bags, reagent bag, bank
    and Warband bank

  This is simpler than PSL's own math. It doesn't count higher ranks toward
  lower ones, or subtract reagents a crafting order's customer provides, so
  those amounts can differ from PSL's window. It switches to `api` on its own
  once PSL is updated. No PSL code is used, only its saved data.

`Builder.lua` turns that into the string: sorted by item ID so it's the same
every refresh, amounts rounded up, owned and unbuyable items left out, then
cut into pages of up to 1000 characters between entries.

Changes come from PSL's `ProfessionShoppingList.OnTrackedRecipesChanged`
event and `BAG_UPDATE_DELAYED`. Whatever is on screen rebuilds once things
have been quiet for half a second, without taking keyboard focus or
jumping you off the part you're on.

## Files

| File | What's in it |
| --- | --- |
| `PSLtoTSM.toc` | Metadata and load order |
| `Init.lua` | Namespace, saved settings, event hub, change notifications |
| `Source.lua` | Reading PSL (`api` and `recipes`) |
| `Builder.lua` | The TSM string, skip rules, splitting into parts |
| `Style.lua` | Flat dark panels, buttons and checkboxes |
| `TextView.lua` | The copy box: paging, read-only guard, Select All |
| `AuctionTab.lua` | The Auction House tab (via LibAHTab) |
| `Window.lua` | The standalone window |
| `Settings.lua` | The settings page |
| `Slash.lua` | Slash commands and the addon menu entry |
| `Libs/` | LibStub and LibAHTab, unmodified upstream copies |
| `Tests/run.lua` | Offline tests |

The Auction House tab only uses LibAHTab's public functions. If the tab row
is too crowded, our tab moves down to a second row under Blizzard's first
tab; the window and other addons' tabs are never touched.

## Development

```sh
lua Tests/run.lua   # offline tests, no game client needed
luacheck .          # lint, configured in .luacheckrc
```

The tests fake the WoW API and PSL, and cover settings, both ways of reading
PSL, the string builder, the change debounce and the slash commands. The UI
files need the game to run.

## Releasing

1. Bump `## Version` in `PSLtoTSM.toc` (SemVer).
2. Add the entry to `CHANGELOG.md`: `# vX.X.X`, the date on the next line,
   then the entries.
3. Zip the `PSLtoTSM` folder without `Tests/` and `.luacheckrc`, and upload
   it to CurseForge.

## License

MIT, see `LICENSE`. The libraries in `Libs/` keep their own licenses, see
`ATTRIBUTIONS.md`.
