# Changelog

## 0.2.0 — 2026-10-31

### Added
- When a player you whispered replies, a popup shows their reply with an Invite button.
- Players who decline your invite or reply "no thanks", "not interested" and similar are never
  contacted again (English replies only).
- Welcome message in guild chat when someone you invited joins. Edit or clear it on the Whisper page.
- `{name}` placeholder: the player's name in whispers and welcome messages.
- At most 100 whispers a day, counted across all your characters.
- When a /who search hits its 50-player limit, Search continues one level per click so you see everyone.
- Key bindings for "Invite next player" and "Post guild ad" (Options → Keybindings → AddOns).
- `/gp next` sends the next queued invite.

### Changed
- "Invite selected" sends one invite per click, key press or `/gp next`. Blizzard requires a click
  or key press for each invite.
- Whispers pause during Blizzard's chat lockdown and continue afterwards.
- A joined Trade channel now also counts as being in a capital city for the auto-prompt.

### Fixed
- Whisper history from 0.1.0 is converted on login, so nobody you whispered in the last 7 days
  gets a second whisper.

## 0.1.0 — 2026-10-28

First release.
- Post your guild ad to Trade, General, LookingForGroup or any joined channel.
- Auto-prompt to post when entering a capital city or a new zone.
- Find Players: /who a level range, then whisper or invite players without a guild.
- "Invite to Guild" in the right-click menu on player names.
- Up to 6 ads and a whisper text, with a `{guild}` placeholder.
