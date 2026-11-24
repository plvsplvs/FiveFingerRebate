Five Finger Rebate 1.5.0-beta.2

For WoW Forever 1.60.1 (interface 16001). No dependencies.

INSTALL
The internal folder remains PocketChange to preserve existing saved data.
Copy PocketChange into the Forever client's Interface/AddOns folder. Restart
WoW for a first install; /reload is enough to update an existing installation.

TRACKER
Click the bag icon in your minimap button bar, or type /ffr.
Report a bug opens a copyable GitHub issue link; /ffr report does the same.
Review the report and submit it in your browser. No data is sent automatically.
It includes versions, locale, and up to 15 recognized tracking notes, but no
character/account names, bags, realm names, or saved-variable files.
Session: the current session, continued across reloads and logins.
All time: all recorded earnings and items for this character.
Recent runs: the last 20 sessions finished with New session; click to inspect.
New session archives the current run and starts a fresh one.
Drag the panel to move it; Escape closes it. MBB collects the icon automatically.
Use /mbb rescan if the button is missing. Right-click it to toggle chat summaries.

Item rows show icons, quantities, loot share, and vendor estimates. Hover for
the item tooltip; modified clicks use WoW's normal item-link behavior. Click
an item to expand/collapse its mob/source breakdown. Search by item name,
item ID, or mob name. Sort cycles through name, quantity, and total vendor value.
Uncached items use their saved name and a placeholder icon until metadata loads.

LOOT SHARES AND MOB SOURCES
An item's loot share is its quantity divided by all collected item units in
the selected session, all-time totals, or saved run. Search does not change
that denominator. Coins are excluded; stack quantities count as multiple units.
Source percentages show how much of that particular item came from each mob.
These are observed loot shares, not per-attempt drop chances. Rounding can make
displayed percentages sum to slightly more or less than 100%.

Mob sources are recorded for new loot under version 1.4.0. Mobs are grouped by
NPC type ID, not individual spawn. Readable mob names are captured at casting
or matched from the loot source; hidden names fall back to NPC ID. Unknown
sources and older items are labeled explicitly, never guessed. Battered
Junkbox contents are grouped under Battered Junkbox: the original mob that
supplied a box is not inferred. Source counts persist with sessions and runs.

EARNINGS
Earned = looted coins + net recorded vendor sales + collected AH sale proceeds.
Pocket coins and Battered Junkbox coins are shown separately.
Older coins whose source was never recorded remain labeled as unknown source.
Loot vendor estimate is the historical vendor value of collected items, not an
inventory valuation. It is never added to Earned. Battered Junkboxes themselves
are excluded from that estimate because their contents are valued separately.
Unavailable prices are reported instead of silently treated as known zeroes.

Gold/hour uses actual earnings and logged-in session time, including idle time.
It appears after one minute. Offline time does not count. The session ends only
when you click New session or use /pc reset. Saved runs include loot locations,
duration, pocket counts, item quantities, and earnings. Sales belong to the
session in which payment is received, even if the item was stolen earlier.

VENDOR AND AUCTION SALES
Sale attribution starts with item quantities collected under version 1.3.0.
Older loot totals are not assumed to be stock you still own.
Vendor sales require bag quantity reductions and a matching coin increase at
an open vendor. Buybacks of tracked sales restore tracked stock and deduct
proceeds; a buyback in a later session can make that session's sales negative.
Rapidly mixing repairs, purchases, destruction, and sales can prevent a match;
the tracker reports an unconfirmed transaction rather than inventing proceeds.

AH proceeds count when seller-invoice mail disappears or loses its attached
money AND your wallet receives the payout. Ordinary mail, purchases, pending
sales, and cancelled auctions are not income. Returned auction deposits are
excluded; the auction cut is already removed from the received payment.
Lost deposits from expired/cancelled auctions are not tracked, so this is sales
income rather than a full profit-and-loss ledger. Closing mail before payment
and inbox updates arrive can prevent confirmation; keep the mailbox open until
collection completes. Incomplete invoices are not attributed.

WoW can merge identical items into stacks. Attribution uses a per-item-type
quantity pool: recorded stolen units are assigned to matching sales first,
up to the number tracked. It does not prove which physical copy was sold.
If you mix purchased, gifted, consumed, or traded copies of the same item, sale
attribution may be approximate. An unmatched item name or ambiguous invoice is
not credited. The addon does not automate selling or posting auctions.

PICKPOCKETS AND JUNKBOXES
Battered Junkbox contents (item 16882) contribute coins and items without adding
another pocket. Boxes already in your bags, or obtained from other players,
also qualify; other containers are excluded.
A Pick Pocket cast arms the next loot window for two seconds. Collected loot
is held until cast success, including when auto-loot finishes first. Readable
target GUIDs must match loot sources. When dungeon restrictions hide target
identity, creature loot after confirmed Pick Pocket is accepted in that window.
Junkboxes are matched by bag item ID and GUID, without a recent cast requirement.
Slots count only when cleared, so full bags and uncollected items do not count.

The status line shows tracking, rejected loot, and sale-confirmation problems.
Restricted spell/loot data, unusual event order, and high latency can still miss
loot. An empty pickpocket followed immediately by corpse loot can be ambiguous
when the target identity is hidden. /pc debug shows the last 30 loot diagnostics;
it stores event names/reasons/counts, never target names or GUIDs.

COMMANDS
/ffr                   Open or close the tracker
/ffr report            Prepare a GitHub bug report
/fivefingerrebate       Alias for /ffr
The /ffr prefix also accepts items, session, quiet, debug, and reset.
Legacy commands remain available:
/pc                    Session and all-time totals
/pcui                  Open or close the tracker
/pc items              All-time item links and quantities
/pc session            Current session totals and items
/pc quiet              Toggle chat summaries
/pc debug              Recent loot diagnostics
/pc reset              Archive this session and start another
/pc reset all confirm  Permanently erase all totals, runs, and sale attribution
/pocketchange          Alias for /pc

Data is per character and saved by WoW at logout or /reload. Updates preserve
existing totals. Previously missed loot or sales cannot be recovered. Crashes
can lose changes since WoW last saved its variables.

VERIFICATION
luajit tests/pocket_change_test.lua
luajit tests/ui_test.lua
luajit tests/sales_test.lua

Tests use mocked WoW events/APIs. Live verification still required: pickpocket
in a dungeon, loot a junkbox, sell a tracked item and buy it back, collect an AH
payout, search for an item, and confirm a session survives /reload. Check that
ordinary corpse loot and unrelated sales do not change tracked earnings.

API references: Blizzard UI source, Forever branch
https://github.com/Gethe/wow-ui-source/tree/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated
https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MailFrame/MailFrame.lua
https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/MerchantFrame.lua
