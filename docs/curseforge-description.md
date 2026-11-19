# Guildprint

Guild recruiting for World of Warcraft: Forever. Write your ad once, post it in a click, and find players who don't have a guild yet.

## Features

**Advertise**
Post your guild ad to Trade, General, LookingForGroup or any other channel you've joined, with one click or keybind.

**Auto-prompt**
When you enter a capital city or a new zone, a small popup asks if you want to post your ad. It shows up at most once per cooldown and never in combat or instances.

**Find Players**
Search a level range with /who and get a list of players without a guild. If /who hits its 50-player limit, Guildprint walks the range one level per click so you see everyone. Tick the ones you want: Guildprint whispers them one every 3 seconds (at most 100 a day), or you step through their `/ginvite` lines and paste each into chat. Anyone you whispered in the last 7 days is skipped, so nobody gets spammed.

**Replies and welcomes**
When someone you whispered writes back, a popup shows a `/ginvite` line to copy and paste into chat. Players who say "no thanks" or decline an invite are never contacted again ("no thanks" replies are recognised in English; declined invites in every client language). When someone you invited joins, a popup sends your welcome to guild chat with one click.

**Invite to Guild**
Right-click a player's name in chat and pick "Invite to Guild" to get their `/ginvite` line.

**Messages**
Keep up to 6 ads, a whisper and a welcome text. `{guild}` is replaced with your guild name, `{name}` with the player's name.

## Commands

- `/gp` or `/guildprint` opens the window
- `/gp post` posts your active ad
- `/gp next` shows the next queued player's `/ginvite` line

Both have key bindings under Options → Keybindings → AddOns.

The auto-prompt settings are also in Options → AddOns → Guildprint.

## Why does posting need a click?

Blizzard only lets addons post to channels, run /who and write in guild chat from a click or keypress, and doesn't let addons send guild invites at all. That's why Guildprint asks instead of posting on its own, and gives you a `/ginvite` line to paste for each invite. Whispers run by themselves once you start them.

## Feedback

Found a bug or have an idea? Leave a comment on this page or open an issue on [GitHub](https://github.com/Wectoz/guildprint/issues).

Source and changelog: [github.com/Wectoz/guildprint](https://github.com/Wectoz/guildprint). MIT licensed.
