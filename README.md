# Guildprint

Guild recruiting for World of Warcraft: Forever.

- **Advertise:** post your guild ad to Trade, General, LookingForGroup or any joined channel.
- **Auto-prompt:** entering a capital city or a new zone pops up a one-click "Post Ad" prompt
  (at most once per cooldown, never in combat or instances).
- **Find Players:** search a level range with /who, list players without a guild, and whisper or
  invite the ones you tick. Sends one every 3 seconds and never re-whispers someone within 7 days.
- **Invite to Guild:** right-click a player name in chat.
- **Messages:** write up to 6 ads and a whisper text. `{guild}` becomes your guild name.

Channel posts and /who need a click or keypress — that's a Blizzard rule, so auto triggers prompt
instead of posting. Whispers and invites are sent automatically once you start them.

## Commands

- `/gp` or `/guildprint` — open the window
- `/gp post` — post the active ad (put it in a macro to bind it to a key)

Settings are also under Options → AddOns → Guildprint.

## Development

- `lua5.1 tests/run.lua` — tests for the pure logic in `Guildprint/Logic.lua`
- `./deploy.sh` — copy the addon into the Forever AddOns folder, then `/reload` in game
- `reference/` (git-ignored) — Blizzard's Forever UI source, sparse checkout of
  `Gethe/wow-ui-source` branch `forever`; grep it before guessing an API or template

## Verified on Forever 1.60.1

Pending the first in-game run: Interface number, posting to several channels with one click,
addon messaging limits, invite throttling, chat menu without taint.
