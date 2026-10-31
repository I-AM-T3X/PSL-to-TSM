local ADDON, ns = ...

-- The in-game changelog, shown on its own Changelog page under PSL to TSM
-- in the Settings window.
--
-- Newest version first. `date` is the release date in ISO 8601
-- (YYYY-MM-DD). The newest `version` must match "## Version" in the TOC
-- (without the "v"); the tests check both.
--
-- Each entry has a tag (New, Changed, Fix, Removed or Upkeep), a short
-- title, and optionally a line of detail.

ns.CHANGELOG = {
  {
    version = "1.1.0",
    date = "2026-10-31",
    entries = {
      { tag = "New", title = "TSM tab on Profession Shopping List's window",
        detail = "PSL's window now has Shopping List and TSM tabs. The TSM tab shows the search string "
          .. "ready to copy, so you can grab it while TSM's Auction House window is open." },
      { tag = "Changed", title = "Uses PSL's own TSM string",
        detail = "With PSL v12.1.5-02 or newer, the string comes straight from PSL, so it follows PSL's "
          .. "own rules for amounts and what to leave out." },
      { tag = "Changed", title = "Changelog has its own page",
        detail = "It's now under PSL to TSM in the Settings list, with each version on its own." },
      { tag = "Changed", title = "Warbound items left out on older PSL versions",
        detail = "Account-bound reagents can't be bought, so they're skipped like soulbound ones." },
      { tag = "Removed", title = "The PSL to TSM tab on the Auction House window",
        detail = "Use the TSM tab on PSL's window instead, or /psltsm convert for a window of its own." },
    },
  },
  {
    version = "1.0.0",
    date = "2026-10-29",
    entries = {
      { tag = "New", title = "Profession Shopping List to TSM",
        detail = "Turns the reagents PSL is tracking into a TSM search string of exact item IDs, "
          .. "on the PSL to TSM Auction House tab or in a window anywhere with /psltsm convert." },
      { tag = "New", title = "Only buy what you're missing",
        detail = "Amounts subtract what you already own, and reagents you have enough of are left out, "
          .. "as are soulbound and quest items. Can be switched to the full amount in settings." },
      { tag = "New", title = "Live updates",
        detail = "The string updates on its own when your tracked recipes or bags change, "
          .. "and long strings are split into parts to paste one at a time." },
    },
  },
}
