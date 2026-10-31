# v1.1.0
2026-10-31

## New
- Profession Shopping List's window now has Shopping List and TSM tabs. The TSM tab shows the search string ready to copy, so you can grab it while TSM's Auction House window is open.

## Changed
- With Profession Shopping List v12.1.5-02 or newer, the string comes straight from PSL, so it follows PSL's own rules for amounts and what to leave out.
- The changelog now has its own page under PSL to TSM in the Settings list.
- On older PSL versions, warbound reagents are now left out like soulbound ones, since they can't be bought.

## Removed
- The PSL to TSM tab on the Auction House window. Use the TSM tab on PSL's window instead, or /psltsm convert for a window of its own.

# v1.0.0
2026-10-29

## New
- Turns the reagents Profession Shopping List is tracking into a TradeSkillMaster search string of exact item IDs, on the PSL to TSM Auction House tab or in a window anywhere with /psltsm convert.
- Only buys what you're missing: amounts subtract what you already own, and reagents you have enough of are left out, as are soulbound and quest items. Can be switched to the full amount in settings.
- Updates on its own when your tracked recipes or bags change, and splits long strings into parts to paste one at a time.
