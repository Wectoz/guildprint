# Guildprint

Guild recruiting for World of Warcraft: Forever.

- **Advertise:** post your guild ad to Trade, General, LookingForGroup or any joined channel.
- **Auto-prompt:** entering a capital city or a new zone pops up a one-click "Post Ad" prompt
  (at most once per cooldown, never in combat or instances).
- **Find Players:** search a level range with /who and list players without a guild. When /who hits
  its 50-player limit, Search walks the range one level per click. Whisper the ones you tick (one
  every 3 seconds, at most 100 a day, never the same player twice within 7 days) or step through
  their `/ginvite` lines.
- **Replies:** when someone you whispered answers, a popup shows a `/ginvite` line to copy into chat. "No thanks"
  style replies (English) and declined invites block that player for good.
- **Welcome:** when someone you invited joins, a popup sends your welcome line to guild chat in one click.
- **Invite to Guild:** right-click a player name in chat for their `/ginvite` line.
- **Messages:** write up to 6 ads, a whisper and a welcome text. `{guild}` becomes your guild name,
  `{name}` the player's name.

Channel posts, /who and guild chat need a click or keypress, and guild invites have to be sent by
you — those are Blizzard rules, so Guildprint prompts instead of acting on its own. Whispers are sent automatically once you start them.

## Commands

- `/gp` or `/guildprint` — open the window
- `/gp post` — post the active ad
- `/gp next` — show the next queued player's `/ginvite` line

Both have key bindings under Options → Keybindings → AddOns.

The auto-prompt settings are also under Options → AddOns → Guildprint.

## Development

- `lua5.1 tests/run.lua` — tests for the pure logic in `Guildprint/Logic.lua`
- `./deploy.sh` — copy the addon into the Forever AddOns folder, then `/reload` in game
- `reference/` (git-ignored) — Blizzard's Forever UI source, sparse checkout of
  `Gethe/wow-ui-source` branch `forever`; grep it before guessing an API or template

## Verified on Forever 1.60.1

Target: Forever only. Source checked at `Gethe/wow-ui-source` `forever` commit `3d8abb1`
(1.60.1.70959); every API the addon calls is unchanged since 70532.

Seen on client 1.60.1.70938 (2026-11-17): Interface 16001, the addon loads, saved settings
are written, the zone auto-prompt fires, no Lua errors in BugGrabber.

Still to check in game: posting to several channels with one click, chat menu without taint,
key bindings listed under AddOns, whisper and /who names matching (realm suffix), decline/join
system messages being caught, capital map IDs, the level cap (Find Players assumes 60).
