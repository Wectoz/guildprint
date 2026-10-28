# Guildprint — design

Date: 2026-10-28
Target: World of Warcraft: Forever (client build `1.60.1.70658`, installed at
`C:\Program Files (x86)\World of Warcraft\_forever_`, WSL path
`/mnt/c/Program Files (x86)/World of Warcraft/_forever_`).

## Intent

A guild-recruiting addon for WoW: Forever. The user recruits by posting an ad
in public chat, whispering players who have no guild, and inviting people who
respond. Today that is all manual typing. Guildprint makes it a few clicks:
it remembers the ad, reminds you to post it at the right moments, finds
unguilded players, and puts "Invite to Guild" one right-click away.

It should feel like part of the Forever client, not a bolted-on tool.

## Goals

1. **Post the guild ad** to chosen public channels, with a "Post Ad Now" button.
2. **Auto-prompt** to post when entering a capital city and/or a new zone, as a
   one-click popup (see Constraints: channel posts need a hardware event).
3. **Right-click a player name in chat → "Invite to Guild"**.
4. **Find Players**: search for players with no guild, filtered by level range,
   show results, and **whisper all selected** with a recruiting whisper
   (fully automatic sending once clicked). Also "Invite selected".
5. **Custom messages**: the player writes their own ads in settings, can keep
   several, and picks one as active. Repeating the same ad is fine.
6. **Forever look**: gold/bronze, matching the Forever Options panel (see
   Visual design).

## Non-goals

- No automatic rotation between ads (user said repeat is fine; multiple ads
  are selectable manually).
- No LocalDefense or /say /yell posting. ("Local" was raised and dropped.)
- No auto-reply to incoming whispers, no guild roster management, no
  officer-note tools, no minimap button. *(My call — not asked for.)*
- No custom-drawn art copied from Blizzard; use in-game templates/textures.

## Anti-goals (would be failure even if it works)

- **Getting the user reported or silenced for spam.** Whisper-all must trickle
  and must skip recently-whispered players.
- **Bypassing Blizzard's hardware-event rule** by any trick. Channel posts
  always come from a real click/keypress.
- **Tainting or breaking Blizzard UI** (e.g. hooking the unit popup in a way
  that causes "action blocked" errors).
- Looking like a generic grey addon window that clashes with the client.

## Constraints

- **Low performance cost is very important (user).** No `OnUpdate` running
  while idle, no polling; react to events only, register only the events in
  use, create windows lazily on first open, use timers (`C_Timer`) only while
  a prompt or whisper queue is active, and keep memory/garbage low (no
  per-frame table churn).

- **Language/format:** Lua + a `.toc` (XML optional). Standard addon folder
  `Interface/AddOns/Guildprint/`. The Forever AddOns folder is currently empty.
- **Engine:** Forever runs on the **modern retail engine** (new Settings panel,
  HUD Edit Mode, Cooldown Manager, Damage Meter, Housing logs), despite the
  1.x version number. Build against the modern retail API, not Classic Era.
  The exact `## Interface:` number is unknown: get it in-game with
  `/dump select(4, GetBuildInfo())`.
- **Hardware-event rule:** `SendChatMessage` to `CHANNEL` (Trade, General,
  LFG, custom), `SAY`, `YELL` requires a hardware event. `WHISPER`, `PARTY`,
  `GUILD` do not (outside instances). `/who` (`C_FriendList.SendWho`) also
  requires a hardware event and returns at most 50 results.
- **Retail-era addon restrictions** (combat/instance messaging limits) may
  exist. Recruiting happens in the open world/cities so impact is expected to
  be nil — verify in-game.
- Trade channel exists only in capital cities.
- Guild invite needs invite rights; hide/disable invite actions when
  `CanGuildInvite()` is false.

## Decided by the user

- Channels: **Trade and General** are the main ones (on by default). The user
  can also enable LookingForGroup or any other joined custom channel.
- Auto triggers: entering a **city**, entering a **new zone**. A one-click
  prompt is acceptable; hands-off would be better but is not possible for
  channels.
- Find Players: **anyone without a guild**, **level-range filter**, "send all"
  invite whisper.
- Messages: player-authored in settings; multiple allowed.
- Theme: Forever gold/bronze, fits the Forever UI. User accepts the in-game
  result will differ from the browser mockups.

## Feature behaviour

### Advertise
- Active ad = one of the saved messages.
- "Post Ad Now" sends the active ad to every enabled channel the player is
  currently in (skip channels not joined, e.g. Trade outside cities).
- Also reachable by slash command `/guildprint post` *(my call)* so it can be
  bound to a macro/key.

### Auto-prompt
- Triggers: entering a capital city; entering a new zone. Each toggleable.
  "New zone" means any zone change, not only zones never visited before
  *(my call)*; the cooldown keeps it from spamming.
- Shows a small popup: "Welcome to <Zone>", which ad and channels, buttons
  **Post Ad** / **Not Now**, closes by itself after ~30 s with a draining bar.
- Cooldown between prompts, default 15 min, adjustable *(my call)*. "Not Now"
  also starts the cooldown *(my call)*.
- No prompt in combat or instances *(my call)*.

### Invite to Guild (chat right-click)
- Adds "Invite to Guild" to the player context menu opened from a chat name.
- Use the modern `Menu.ModifyMenu` API (not old `UnitPopup` table edits) to
  avoid taint.
- Hidden when the player can't invite or the target is already in your guild.

### Find Players
- Inputs: min/max level. **Search** sends a `/who` for that range (one click).
- Results list: name (class-coloured), level, class, zone; only players whose
  guild is empty. All ticked by default.
- Players whispered by Guildprint in the last N days (default 7, *my call*) are
  shown greyed and unticked.
- **Whisper selected (n)**: sends the recruiting whisper to each selected
  player, one every ~3 s *(my call)*, with progress and a Stop button. Records
  each name + time.
- **Invite selected**: guild-invites selected players (same trickle).
- The 50-result cap: tell the user when hit and suggest narrowing the range.

### Settings
- Lives in **Options → AddOns → Guildprint** (modern Settings API) and in a
  standalone window opened with `/guildprint` *(my call)*.
- Pages: Advertise (active ad, channels, triggers, cooldown), Find Players,
  Messages (new/edit/delete ads), Whisper (whisper text).
- Settings saved per character via SavedVariables *(my call)*. Whisper
  history is account-wide *(my call)* so switching alts doesn't re-whisper the
  same people. Default ad/whisper text
  includes the guild name via a `{guild}` placeholder *(my call)*.

## Visual design

Reference: browser mockup `.superpowers/brainstorm/*/content/overview-v3.html`
and the user's four Forever screenshots (Options panel, Raid Frames settings,
HUD Edit Mode import dialog, Nameplates settings), kept locally only and not
published.

- Build from Blizzard's own templates and atlases so it matches automatically:
  Settings-panel style frame, gold `GameFontNormal`, white section headers with
  a thin gold rule, grey beveled buttons with gold text, **red buttons with gold
  border for primary actions** (Post Ad, Whisper All, Defaults), big gold
  checkmarks, diamond slider knobs, yellow arrow selectors.
- Main window: dark charcoal, bronze double border, small centered title bar,
  red ✕; left sidebar of pages with gold highlight on the selected one.
- Player names class-coloured as in the game.
- The "Prompt style" selector shown in mockup v3 is **dropped** *(my call)*.

## Left to the builder

- File/module layout, frame template choice, how to detect "capital city"
  (e.g. Trade channel becoming available vs. a map-ID list).
- Exact menu tags for chat-name menus, who-result API calls, and the
  modern-vs-legacy function names (`C_GuildInfo.Invite` vs `GuildInvite`,
  `C_ChatInfo.SendChatMessage` vs `SendChatMessage`) — verify in the Forever
  client.
- How the addon is deployed during development (copy vs. symlink into
  `_forever_/Interface/AddOns`).
- Test approach: pure logic (cooldowns, filters, whisper history, placeholder
  fill) as a small Lua self-check; UI and APIs via an in-game checklist.

## Must verify in-game (plan should include this checklist)

- The `## Interface:` number.
- One click can post to several channels at once (one hardware event, multiple
  `SendChatMessage` calls). If not, Post Ad sends one channel per click.
- Retail-era addon messaging limits don't block whispers/posts in the open
  world.
- Bulk guild invites in a trickle are allowed and not throttled away.
- Chat-name right-click menu shows "Invite to Guild" without taint errors.
