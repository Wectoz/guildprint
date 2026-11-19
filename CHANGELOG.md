# Changelog

## 0.2.3 — 2026-11-19

Forever does not let addons send guild invites or post in guild chat on their own.
Guildprint now works with that instead of running into "action blocked".

### Changed
- Invites: the reply popup, Find Players and the right-click entry now show a `/ginvite Name`
  line to copy and paste into chat, instead of an Invite button that Blizzard blocks.
- Welcome message: when someone you invited joins, a popup offers to send your welcome with
  one click. It also works for players you invited by typing `/ginvite` yourself.

### Fixed
- The first `/gp` after logging in could show an error instead of the window.
- The same player could be whispered twice if they appeared twice in one list.
- A reply like "my friend is not interested, but I'd love an invite" no longer blocks that player.
- An open reply popup closes if the player then says "no thanks".
- A /who search that gets no answer gives up after 10 seconds instead of taking your next
  own /who as its result.
- A whisper to a player who had just logged off no longer counts as sent.

## 0.2.2 — 2026-11-18

### Changed
- Options → AddOns → Guildprint is now a plain settings list (auto-prompt toggles and
  timing) with a button that opens the Guildprint window. The squeezed copy of the whole
  window is gone.
- The window has a darker background, is a little wider so the channel checkboxes fit,
  and opens on the Advertise page every time.
- All buttons use the red style.

### Fixed
- Sidebar section titles in the window no longer overlap the page names.

## 0.2.1 — 2026-11-18

Checked against Forever 1.60.1 (build 70959). No game changes affect Guildprint.

### Fixed
- Declined invites and new members are now recognised in client languages that write the
  player's name as `%1$s` in system messages.
- Long replies with accented or non-Latin letters no longer show a broken character in the popup.
- "Change" on the Advertise page no longer opens a second window when you are in
  Options → AddOns → Guildprint.
- Converting whisper history from 0.1.0 could skip players or stop with an error.

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
