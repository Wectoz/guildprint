# Guildprint

Guild recruiting for World of Warcraft: Forever.

- **Advertise:** post your guild ad to Trade, General, LookingForGroup or any joined channel.
- **Auto-prompt:** entering a capital city or a new zone pops up a one-click "Post Ad" prompt
  (at most once per cooldown, never in combat or instances).
- **Find Players:** search a level range with /who and list players without a guild. When /who hits
  its 50-player limit, Search walks the range one level per click. Whisper the ones you tick (one
  every 3 seconds, at most 100 a day, never the same player twice within 7 days) or invite them
  one click at a time.
- **Replies:** when someone you whispered answers, a popup offers a one-click invite. "No thanks"
  style replies (English) and declined invites block that player for good.
- **Welcome:** says a welcome line in guild chat when someone you invited joins.
- **Invite to Guild:** right-click a player name in chat.
- **Messages:** write up to 6 ads, a whisper and a welcome text. `{guild}` becomes your guild name,
  `{name}` the player's name.

Channel posts, /who and guild invites need a click or keypress — that's a Blizzard rule, so auto
triggers prompt instead of posting. Whispers are sent automatically once you start them.

## Commands

- `/gp` or `/guildprint` — open the window
- `/gp post` — post the active ad
- `/gp next` — send the next queued guild invite

Both have key bindings under Options → Keybindings → AddOns.

Settings are also under Options → AddOns → Guildprint.

## Development

- `lua5.1 tests/run.lua` — tests for the pure logic in `Guildprint/Logic.lua`
- `./deploy.sh` — copy the addon into the Forever AddOns folder, then `/reload` in game
- `reference/` (git-ignored) — Blizzard's Forever UI source, sparse checkout of
  `Gethe/wow-ui-source` branch `forever`; grep it before guessing an API or template

## Verified on Forever 1.60.1

Pending the first in-game run: Interface number, posting to several channels with one click,
addon messaging limits, chat menu without taint, key bindings listed under AddOns, whisper and
/who names matching (realm suffix), decline/join system messages being caught, capital detection
(map IDs or the Trade channel).
