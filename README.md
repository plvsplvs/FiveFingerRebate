# Five Finger Rebate

A rogue's ledger for **WoW Forever**: track stolen coins, pocket loot, junkbox contents, and the proceeds from selling your haul.

**Beta:** tested with mocked WoW events and APIs; live gameplay verification is ongoing. Other WoW editions are not supported.

## Features

- Sessions that survive reloads and logins, with online time and gold per hour.
- Separate pocket coins, Battered Junkbox coins, vendor sales, and collected AH proceeds.
- Item icons, tooltips, search, quantity/value sorting, and expandable mob-source breakdowns.
- Observed loot percentages, historical vendor estimates, and the last 20 completed runs.
- Standard WoW frames and buttons with dagger details, gold headings, and subtle poison-green accents; minimap button and MinimapButtonBag compatibility.
- An in-game bug reporter that prepares a GitHub issue link for you to review and submit.

## Install

Extract an installable release ZIP into your Forever client's `Interface/AddOns` directory. It must contain `PocketChange/PocketChange.toc`. Restart WoW for a first install, or `/reload` after updating.

The internal folder is still **PocketChange** to preserve data from earlier versions. Do not rename it or install two copies. Existing coins and item totals migrate automatically; source information that was never recorded stays unknown.

Open the bag icon or type `/ffr`. Use **New session** to finish and save a run. Click an item for its mob-source breakdown. Search matches item names, IDs, and mob names.

| Command | Action |
| --- | --- |
| `/ffr` | Open the tracker |
| `/ffr report` | Prepare a bug report |
| `/ffr session` | Print session totals and items |
| `/ffr items` | Print all-time items |
| `/ffr quiet` | Toggle chat summaries |
| `/ffr reset` | Archive this run and start another |
| `/ffr reset all confirm` | Permanently erase all recorded data |

Older `/pc`, `/pcui`, and `/pocketchange` commands still work.

## Reporting bugs

Use **Report a bug** or `/ffr report`. Copy the selected link into your browser, review the prefilled diagnostics, add reproduction steps, and submit using your GitHub account. You can also [open the bug form directly](https://github.com/plvsplvs/FiveFingerRebate/issues/new?template=bug_report.yml).

The addon makes no network requests and does not create issues automatically. It never stores GitHub credentials. The report contains addon/client versions, locale, and up to 15 recognized event notes. It excludes character/account names, bag inventories, realm names, and saved-variable files. Review screenshots and error messages before attaching them to a public issue.

## What the numbers mean

**Earned** combines looted coins, recorded vendor proceeds minus tracked buybacks, and collected auction proceeds excluding returned deposits. Vendor-value estimates are shown separately and never added to earnings. Lost auction deposits are not tracked, so this is not a full profit-and-loss ledger.

Sale attribution matches recorded stolen quantities by item type. WoW can merge identical items into stacks; mixing purchased, gifted, consumed, or traded copies can make that attribution approximate. Previous sales are not reconstructed. Keep the mailbox open until collection completes.

Item percentages are shares of collected item units, **not drop chances**. Restricted dungeon data may hide mob names; readable NPC IDs are used when possible. Junkbox contents are attributed to the box, not an inferred original mob.

Read [the full behavior and limitations](PocketChange/README.txt) before interpreting totals. Sessions include logged-in idle time and exclude offline time. WoW saves data at logout or reload; crashes can lose unsaved changes.

## Development

Lua 5.1 or LuaJIT, Python 3, and Luacheck 1.2.0 are sufficient:

```sh
luacheck PocketChange tests
lua tests/pocket_change_test.lua
lua tests/ui_test.lua
lua tests/sales_test.lua
python3 scripts/package.py
```

The package is written to `dist/`. CI runs the same checks and uploads an installable ZIP. GitHub's automatic source-code ZIP is not the installable addon package.

See [RELEASING.md](RELEASING.md) for CurseForge preparation and the live test checklist.

## License

[MIT](LICENSE). Blizzard-owned in-game textures are referenced by path, not distributed in this repository. This is an independent addon, not affiliated with Blizzard Entertainment.
