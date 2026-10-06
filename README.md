# Oak LFG Sorter Forever

A compact Oak browser for WoW Forever's shared player and group listings.
Targets interface 16001; reviewed against Blizzard UI source for 1.60.1.70235.

Browse players and groups together in a familiar Oak window, then whisper a
leader or invite a solo player using Forever's native group finder flow.

## Features

- One sortable list with All, Groups, and Players filters.
- Role, activity, text, and new-player-friendly filtering.
- Class-colored member names, levels, classes, and roles in tooltips.
- A pinned row for your own listing.
- Native whisper and invitation actions, plus access to Blizzard's listing editor.
- Draggable minimap button, keybinding, saved window position, and scale options.

[Download releases](https://github.com/Smokenoaken/OakLFGSorterForever/releases)
| [Report an issue](https://github.com/Smokenoaken/OakLFGSorterForever/issues)

Tagged GitHub releases publish through the marketplace workflow to CurseForge
project 1729476 and Wago project rNkg0BNa. The repository needs `CF_API_TOKEN`
and `WAGO_API_TOKEN` Actions secrets; the workflow warns separately if either
one is missing.

## Use

- `/sorter` or `/oaklfgforever`: open or close the window.
- `/sorter reset`: reset position and scale.
- Keybindings: under Oak LFG Sorter - Forever, bind Open / Close Sorter.
- Minimap button: left-click to toggle, right-click for options, drag to reposition.
- Choose a category and one or more activities, then browse the results.
- All / Groups / Players filters share one list. Your listing stays pinned first.
- Click column headings to sort; click again to reverse. Scroll for more rows.
- Role filters match a player's advertised roles or roles already in a group.
- The text box filters loaded names, activities, notes, and playstyles.
- Select a listing and click Whisper to open an unsent chat draft.
- Invite is available for eligible solo listings, subject to native permissions,
  group capacity, and combat. It does not use Retail applications.
- List yourself / Edit listing opens Blizzard's listing editor. Blizzard opens
  its normal browser. Use `/sorter` to return.
- Options includes scale, beginner-friendly listings, Blizzard's level filter,
  and an optional auto-open setting. Auto-open defaults off.

The default window is 660 x 484 with nine pooled rows, Oak's font and portrait,
gray panels, class-colored names, and blue activity text. Drag the title bar to
move it. Escape closes it when the search box does not have keyboard focus.

## Installation

Place the `OakLFGSorterForever` folder in:
`World of Warcraft/_classic_beta_/Interface/AddOns/`.

Enable **OAK LFG Sorter - Forever** in the AddOns list. Reload the UI; if the new
addon is not listed, restart the client. This has its own SavedVariables and
does not depend on the Retail OakLFGSorter addon or EllesmereUI.

## Validation

- Lua 5.1 syntax checked for the addon files.
- 32 data/action/lifecycle checks passed with mocked WoW APIs.
- 16 UI startup/menu/scroll/state checks passed with mocked frames.
- The browser has been shown in-game on Forever. Automated checks use mocked
  game APIs and do not establish server invitation behavior or taint safety.

Live checks: open the window; search an activity with both players and groups;
change filters and sort order; refresh after selecting a row; whisper a group
leader; invite an eligible solo player; edit your listing; close/reopen; reload
and verify saved position. Check alongside EllesmereUI's finder skin.

## Implementation references

Blizzard's extracted UI source, pinned to build 70235:
https://github.com/Gethe/wow-ui-source/tree/a84e2b1b41d3d4137127c07e4da448aa3251d6f1/Interface/AddOns/Blizzard_GroupFinder_VanillaStyle

Uses the native search controls and invite helper. No application queue,
automatic whispers, automatic invites, polling, or replacement scripts on
Blizzard frames. The UI is built on first open, and search events are registered
only while the Oak window is shown. Existing Oak font and logo assets are used.

Engineering approach informed by Ellesmere's contribution guidance:
https://github.com/EllesmereGaming/EllesmereUI/blob/main/.github/CONTRIBUTING.md
