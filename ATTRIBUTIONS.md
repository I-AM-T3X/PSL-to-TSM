# Attributions

## Embedded libraries

These are included unmodified in `Libs/`, under their own licenses.

- **LibStub** (`Libs/LibStub/`): public domain.
  https://www.wowace.com/projects/libstub
- **LibAHTab-1.0** (`Libs/LibAHTab/`): MIT License, Copyright (c) 2022
  plusmouse. The license text is in `Libs/LibAHTab/LICENSE`.
  https://github.com/Auctionator/LibAHTab

## Works with

- **Profession Shopping List**: required. PSL to TSM reads its tracked
  reagents through its public `GetShoppingList()` API, or for older PSL
  releases, its saved list of tracked recipes. No PSL code is included.
  https://www.curseforge.com/wow/addons/profession-shopping-list
- **TradeSkillMaster**: the search string is written in TSM's search
  syntax. PSL to TSM never calls TSM itself.
  https://www.tradeskillmaster.com/
