# Releasing Five Finger Rebate

## Before a beta release

1. Update `## Version` in `PocketChange/PocketChange.toc` and the bundled README.
2. Run Luacheck and all three Lua test scripts. Run `python3 scripts/package.py`.
3. Test in WoW Forever: dungeon pickpocketing, junkboxes, full bags, auto-loot, vendor sale and buyback, AH mail collection, search, mob breakdowns, `/reload` session persistence, and `/ffr report`.
4. Check that ordinary corpse loot and unrelated sales do not increase tracked totals. Check the panel at your UI scale; the automated tests cannot verify rendered layout.
5. Review the ZIP: one `PocketChange/` folder, matching TOC, code, bundled documentation, and license. No saved variables, account data, screenshots, tests, or credentials.
6. Create a GitHub release from the tested commit and attach the generated ZIP. Keep early builds marked as prereleases/beta. Never use GitHub's source archive as the addon upload.

## CurseForge

Create a World of Warcraft project through the [CurseForge author portal](https://authors.curseforge.com/). Use:

- Name: **Five Finger Rebate**
- License: **MIT**
- Source: https://github.com/plvsplvs/FiveFingerRebate
- Issues: https://github.com/plvsplvs/FiveFingerRebate/issues
- Supported game version/flavor: the Forever client actually tested, currently interface `16001`
- Initial file release type: **Beta**

Upload `dist/FiveFingerRebate-<version>.zip` and provide the tested client build, changelog, and known limitations. Do not mark untested game editions as supported. The repository setup does not create a CurseForge project or upload a file automatically.

CurseForge requires the ZIP's root addon folder to match its TOC name; `PocketChange/PocketChange.toc` remains intentional for existing-user save compatibility. See [project submission instructions](https://support.curseforge.com/support/solutions/articles/9000197241) and [package requirements](https://support.curseforge.com/support/solutions/articles/9000196615-curseforge-known-issues).

After CurseForge assigns a project ID, it can be added as `## X-Curse-Project-ID`. If automated uploads are later enabled, keep the API token in GitHub Actions secrets, never addon code or repository files.
