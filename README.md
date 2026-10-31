# PSL to TSM

A World of Warcraft addon that turns the reagents
[Profession Shopping List](https://www.curseforge.com/wow/addons/profession-shopping-list)
(PSL) is tracking into a [TradeSkillMaster](https://www.tradeskillmaster.com/)
search string you can paste straight into TSM.

Built for Midnight (retail, interface 120007 / 120100 / 120105).

## What it does

- Adds **Shopping List** and **TSM** tabs to PSL's tracking window. The TSM
  tab shows the search string in place of PSL's list, so you can copy it
  while TSM's own Auction House window is open.
- Every reagent is an exact `i:<itemID>/x<amount>` entry, quality rank
  included, so TSM searches for exactly the right item.
- With PSL v12.1.5-02 or newer, the string is PSL's own
  (`GetTSMSearchString()`), so PSL decides the amounts and what to leave out.
- The string updates on its own when you track or untrack recipes in PSL, or
  when your bags change.
- Long lists are split into parts that fit TSM's search box. `<` and `>` page
  through them, and each part is selected as you go.

## Using it

- **TSM tab** on PSL's tracking window. Click it to swap PSL's list for the
  string; click **Shopping List** to go back.
- **`/psltsm tab`** or left-clicking **PSL to TSM in the addon menu** by the
  minimap opens PSL's window straight on the TSM tab. Right-click the menu
  entry for settings.
- **`/psltsm convert`** opens the string in a window of its own. It's the
  backup if PSL's window ever can't be used.

Click **Select All**, press Ctrl+C (Cmd+C on Mac), and paste into TSM.

### Commands

| Command | What it does |
| --- | --- |
| `/psltsm` | Open the settings |
| `/psltsm tab` | Open PSL's window on the TSM tab |
| `/psltsm convert` | Show the string in a window of its own |
| `/psltsm owned on\|off` | Only buy what you're missing |
| `/psltsm login on\|off` | Version message at login |
| `/psltsm status` | Settings and PSL connection |
| `/psltsm reset` | Default settings |
| `/psltsm help` | List the commands |

`/psltotsm` works too.

### Settings

| Setting | Default | Saved as |
| --- | --- | --- |
| Only buy what I'm missing (older PSL only, see below) | On | `missingOnly` |
| Show a message when I log in | Off | `loginMessage` |

Stored account-wide in `PSLtoTSMDB.settings`. In the game's Settings
window, PSL to TSM expands to show a **Changelog** page with every version.

## Requirements

- **Profession Shopping List** (required). v12.1.5-02 or newer is best,
  since it builds the TSM string itself. Older releases still work: the
  addon works the list out from the recipes PSL is tracking instead (see
  below).
- **TradeSkillMaster** to paste the string into. Not needed to run, and
  never called by this addon.

## How it works

`Source.lua` reads PSL in one of two ways:

- **`tsm`**: PSL v12.1.5-02 and newer. The string is PSL's own
  `GetTSMSearchString()`, and `GetMerchantShoppingList()` gives the numbers
  behind it for the status line. PSL's entries are sorted by item ID so the
  string doesn't reshuffle each time. PSL returns nothing while any item's
  details are still loading; the addon then says "Loading item info", asks
  the game for those items, and rebuilds when they arrive. The "Only buy
  what I'm missing" setting doesn't apply here, since PSL decides amounts.
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
  those amounts can differ from PSL's window. `Builder.lua` writes the string
  here: sorted by item ID, amounts rounded up, owned items and ones that
  can't be bought (soulbound, quest, warbound) left out. It switches to
  `tsm` on its own once PSL is updated. No PSL code is used, only its saved
  data.

Either way, long strings are cut into pages of up to 1000 characters,
between entries.

The tabs hook PSL's window (the global `PSLTrackingWindow`, with
Slackluster's OK). The TSM tab hides the window's `.ScrollFrame`, which
holds everything PSL draws, and shows the string in its place. If that
window can't be found, the tabs don't appear and `/psltsm convert` is used
instead.

Changes come from PSL's `ProfessionShoppingList.OnTrackedRecipesChanged`
event and `BAG_UPDATE_DELAYED`. Whatever is on screen rebuilds once things
have been quiet for half a second, without taking keyboard focus or
jumping you off the part you're on.

## Files

| File | What's in it |
| --- | --- |
| `PSLtoTSM.toc` | Metadata and load order |
| `Init.lua` | Namespace, saved settings, event hub, change notifications |
| `Changelog.lua` | The in-game changelog data |
| `Source.lua` | Reading PSL (`tsm` and `recipes`) |
| `Builder.lua` | The TSM string, skip rules, splitting into parts |
| `Style.lua` | Flat dark panels, buttons and checkboxes |
| `TextView.lua` | The copy box: paging, read-only guard, Select All |
| `PSLWindow.lua` | The Shopping List and TSM tabs on PSL's window |
| `Window.lua` | The standalone window (`/psltsm convert`) |
| `Settings.lua` | The settings page, and the Changelog page under it |
| `Slash.lua` | Slash commands and the addon menu entry |
| `Tests/run.lua` | Offline tests |

## Development

```sh
lua Tests/run.lua   # offline tests, no game client needed
luacheck .          # lint, configured in .luacheckrc
```

The tests fake the WoW API and PSL, and cover settings, both ways of reading
PSL (including the loading state), the string builder, the change debounce,
the slash commands and the version/changelog rules. The UI files need the
game to run.

## Versioning and releasing

Versions are SemVer (`Major.Minor.Patch`): patch for fixes, minor for new
features, major for breaking changes. Never reuse a number. Dates are
ISO 8601 (`YYYY-MM-DD`).

1. Bump `## Version` in `PSLtoTSM.toc`. That's the only place the version
   is set; the addon reads it from there.
2. Add the release to the top of `Changelog.lua` (in-game, shown on the
   Changelog page under PSL to TSM in Settings): the version without the
   `v`, the date, and entries tagged New, Changed, Fix, Removed or Upkeep.
3. Add it to the top of `CHANGELOG.md` (CurseForge): `# vX.X.X`, the date on
   the next line, then `## New` / `## Changed` / `## Fix` / `## Removed`
   sections.
4. Run `lua Tests/run.lua`. It fails if the TOC, `Changelog.lua` and
   `CHANGELOG.md` don't agree on the version and date, or a date isn't
   ISO 8601.
5. Zip the `PSLtoTSM` folder without `Tests/` and `.luacheckrc`, and upload
   it to CurseForge.

## License

MIT, see `LICENSE`. See `ATTRIBUTIONS.md` for the addons this works with.
