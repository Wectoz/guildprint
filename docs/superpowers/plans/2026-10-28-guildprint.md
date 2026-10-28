# Guildprint Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A WoW: Forever addon that posts guild ads (manual + one-click auto-prompt on city/zone entry), adds "Invite to Guild" to chat-name menus, and finds/whispers/invites unguilded players, in the Forever gold/bronze look.

**Architecture:** One event frame dispatches only the events in use. All decision logic lives in a pure-Lua `Logic.lua` (no WoW API) that is unit-tested outside the game with `lua5.1`. Feature files call WoW APIs and build UI lazily on first open from Blizzard templates. A single page container is shared by the standalone window and the Options → AddOns canvas.

**Reference:** `reference/wow-ui-source` = Gethe/wow-ui-source `forever` branch (1.60.1.70532), sparse checkout. Verified there: `C_ChatInfo.SendChatMessage(msg, chatType, lang, target)` (HasRestrictions), `C_FriendList.SendWho(filter, origin?)` (HasRestrictions), `GetWhoInfo(i)` -> `{fullName, fullGuildName, level, classStr, area, filename}`, `C_GuildInfo.Invite(name)`, `C_GuildInfo.MemberExistsByName(name)`, chat-name menu tag `MENU_UNIT_FRIEND`, `Settings.RegisterCanvasLayoutCategory/RegisterAddOnCategory`. Grep it before guessing any API or template.

**Tech Stack:** Lua 5.1 (WoW dialect), `.toc`, modern retail API (`Settings`, `Menu`, `C_FriendList`, `C_GuildInfo`, `C_Timer`), `lua5.1` for local tests.

**Spec:** `docs/superpowers/specs/2026-10-28-guildprint-design.md`

## Global Constraints

- Low performance cost is a hard requirement: no `OnUpdate` scripts, no polling; event-driven only; `C_Timer` only while a prompt or whisper queue is active; frames created lazily on first show; no table creation in hot paths.
- Addon folder is `Guildprint/` at the repo root; deployed by copying to `/mnt/c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/Guildprint`.
- Namespace: the `local addonName, ns = ...` table only; the sole globals are `GuildprintDB`, `GuildprintCharDB`, `SLASH_GUILDPRINT1`, `SLASH_GUILDPRINT2`.
- SavedVariables: `GuildprintDB` (account: whisper history), `GuildprintCharDB` (per character: everything else).
- Channel posts only from a click/keypress (hardware event). Never attempt to bypass.
- Look: Blizzard templates/atlases/fonts only (gold `GameFontNormal`, `GameFontHighlight` headers, `UIPanelButtonTemplate`, red button for primary actions, `UICheckButtonTemplate`/settings checkbox, `InputBoxTemplate`). Match `docs/superpowers/specs/assets/1.png`–`4.png`. Inspect real Forever frames with `/fstack` to pick templates.
- Chat message max 255 chars.
- Default channels: Trade on, General on, LookingForGroup off. Prompt cooldown default 15 min. Prompt auto-close 30 s. Whisper/invite queue interval 3 s. Whisper history window 7 days. Who results cap 50.
- Slash: `/guildprint` (alias `/gp`) opens the window; `/guildprint post` posts the active ad.

## Review Focus

1. Trade not joined (outside a capital) or no enabled channel joined → Post Ad skips missing channels silently and prints one line saying where it posted, or "No enabled channel joined" if none. → Task 1 `FindChannelIds` tests + Task 4 check.
2. All ads deleted or active ad text empty → Post Ad does nothing and prints why; never sends an empty message. → Task 1 `ActiveAdText` test.
3. `{guild}` expansion pushes text over 255 chars → text is truncated to 255. → Task 1 `FillPlaceholders` test.
4. Cross-realm names: history and dedupe key on `Name-Realm`. A bare name gets the player's realm. → Task 1 `FullName` tests.
5. Bad level input (empty, non-number, min > max, outside 1–60) → no `/who` is sent and the field shows an error. → Task 1 `WhoQuery` tests.

---

### Task 1: Repo, test runner, pure logic

**Files:**
- Create: `.gitignore` (contains `.superpowers/` and `reference/`)
- Create: `Guildprint/Logic.lua`
- Create: `tests/run.lua`, `tests/test_logic.lua`

**Interfaces:**
- Produces (all on `ns.Logic`, also returned by the file when loaded outside WoW via `local ns = select(2, ...) or {}` then `return ns.Logic`):
  - `Logic.DEFAULTS` — table: `{ ads={{name="Main ad", text="{guild} is recruiting all levels! /w me for an invite."}}, activeAd=1, channels={Trade=true, General=true, LookingForGroup=false}, triggers={city=true, zone=true}, cooldownMin=15, whisper="Hi! {guild} is recruiting, want an invite?", minLevel=1, maxLevel=60, lastPromptAt=0 }`
  - `Logic.MergeDefaults(db: table|nil, defaults: table) -> table` — deep-fills missing keys, keeps existing values (arrays like `ads` are not merged element-wise).
  - `Logic.FillPlaceholders(text: string, guildName: string|nil) -> string` — replaces `{guild}` with `<guildName>` or `our guild`; truncates to 255.
  - `Logic.ActiveAdText(db) -> string|nil` — nil when no ad or blank text.
  - `Logic.ShouldPrompt(now: number, lastPromptAt: number, cooldownMin: number, blocked: boolean) -> boolean`
  - `Logic.FindChannelIds(list: table, enabled: table) -> table` — `list` is the flat `GetChannelList()` result `{id, name, disabled, ...}`; returns ids whose base name (text before `" - "`) is enabled and not disabled, ordered as in `list`.
  - `Logic.WhoQuery(minLevel: any, maxLevel: any) -> string|nil` — `"10-30"` for valid integers in 1–60 with min ≤ max, else nil.
  - `Logic.FullName(name: string, realm: string) -> string`
  - `Logic.PruneHistory(history: table, now: number, days: number)` — removes entries older than `days`, in place.
  - `Logic.FilterWho(results: table, history: table, now: number, days: number) -> table` — input rows `{name, guild, level, classFile, class, zone}`; keeps rows with `guild == ""`; adds `recent` (in history within `days`) and `selected = not recent`.
  - `Logic.CAPITALS` (set of uiMapIDs `{[1453]=true,[1454]=true,[1455]=true,[1456]=true,[1457]=true,[1458]=true}`) and `Logic.IsCapital(mapID) -> boolean`.

- [ ] **Step 1: `git init`, add `.gitignore`. Install the test interpreter if missing: `sudo apt-get install -y lua5.1` (ask the user to run it with `! sudo apt-get install -y lua5.1` if sudo prompts).**

- [ ] **Step 2: Write `tests/run.lua`** — loads `Guildprint/Logic.lua` with `loadfile(path)("Guildprint", ns)`, runs every `test_*` function in `tests/test_logic.lua`, prints `PASS n` / failures, `os.exit(1)` on any failure.

- [ ] **Step 3: Write failing tests in `tests/test_logic.lua`**

```lua
function test_fill_guild()   assert(L.FillPlaceholders("{guild} rocks", "Iron Oath") == "Iron Oath rocks") end
function test_fill_noguild() assert(L.FillPlaceholders("{guild}!", nil) == "our guild!") end
function test_fill_trunc()   assert(#L.FillPlaceholders(("x"):rep(250).."{guild}", "Iron Oath") == 255) end
function test_active_none()  assert(L.ActiveAdText({ads={}, activeAd=1}) == nil) end
function test_active_blank() assert(L.ActiveAdText({ads={{name="a", text="  "}}, activeAd=1}) == nil) end
function test_active_ok()    assert(L.ActiveAdText({ads={{name="a", text="hi"}}, activeAd=1}) == "hi") end
function test_prompt_cool()  assert(L.ShouldPrompt(1000, 900, 15, false) == false) end
function test_prompt_ok()    assert(L.ShouldPrompt(2000, 1000, 15, false) == true) end
function test_prompt_block() assert(L.ShouldPrompt(5000, 0, 15, true) == false) end
function test_channels()
  local list = {1,"General - Durotar",false, 2,"Trade - City",false, 4,"LookingForGroup",false, 5,"MyGuildChan",false}
  local ids = L.FindChannelIds(list, {General=true, Trade=true, LookingForGroup=false, MyGuildChan=true})
  assert(#ids == 3 and ids[1] == 1 and ids[2] == 2 and ids[3] == 5)
end
function test_channels_none() assert(#L.FindChannelIds({1,"General - Durotar",false}, {Trade=true}) == 0) end
function test_channels_disabled() assert(#L.FindChannelIds({2,"Trade - City",true}, {Trade=true}) == 0) end
function test_who_ok()       assert(L.WhoQuery("10", 30) == "10-30") end
function test_who_bad()      assert(L.WhoQuery("", 30) == nil and L.WhoQuery("abc", 30) == nil and L.WhoQuery(40, 30) == nil and L.WhoQuery(0, 30) == nil and L.WhoQuery(10, 61) == nil) end
function test_fullname()     assert(L.FullName("Bob", "Realm") == "Bob-Realm" and L.FullName("Bob-Other", "Realm") == "Bob-Other") end
function test_prune()        local h = {["A-R"]=100, ["B-R"]=1e6}; L.PruneHistory(h, 1e6, 7); assert(h["A-R"] == nil and h["B-R"]) end
function test_filter_who()
  local rows = L.FilterWho({
    {name="A-R", guild="", level=10}, {name="B-R", guild="Foo", level=12}, {name="C-R", guild="", level=14},
  }, {["C-R"]=1e6 - 3600}, 1e6, 7)
  assert(#rows == 2 and rows[1].selected == true and rows[2].recent == true and rows[2].selected == false)
end
function test_merge()
  local db = L.MergeDefaults({cooldownMin=5, channels={Trade=false}}, L.DEFAULTS)
  assert(db.cooldownMin == 5 and db.channels.Trade == false and db.channels.General == true and #db.ads == 1)
end
function test_capital()      assert(L.IsCapital(1454) and not L.IsCapital(1411)) end
```

- [ ] **Step 4: Run `lua5.1 tests/run.lua`** — Expected: FAIL (Logic functions missing).

- [ ] **Step 5: Implement `Guildprint/Logic.lua`** per the Interfaces block. `MergeDefaults` must copy default tables (never share the `DEFAULTS` tables with the saved DB).

- [ ] **Step 6: Run `lua5.1 tests/run.lua`** — Expected: `PASS 19`, exit 0.

- [ ] **Step 7: Commit** `git add -A && git commit -m "feat: pure recruiting logic with tests"`

---

### Task 2: Addon core, events, slash, deploy

**Files:**
- Create: `Guildprint/Guildprint.toc`, `Guildprint/Core.lua`, `deploy.sh`

**Interfaces:**
- Consumes: `ns.Logic.MergeDefaults`, `ns.Logic.DEFAULTS`, `ns.Logic.PruneHistory`.
- Produces:
  - `ns.db` (per-char settings), `ns.history` (= `GuildprintDB.history`, keyed by `Name-Realm` → `time()`).
  - `ns.On(event: string, fn: function)` — registers the event on the single frame the first time a handler is added; `ns.Off(event, fn)` unregisters when no handlers remain.
  - `ns.Print(msg: string)` — prefixes `|cffffd200Guildprint|r: `.
  - `ns.slash[sub] = fn(rest)` — sub-command table; empty sub calls `ns.OpenWindow()` (defined in Task 3).

- [ ] **Step 1: Write `Guildprint.toc`**: `## Interface:` set to the value from the user running `/dump select(4, GetBuildInfo())` in Forever (ask the user; until then use the number they give, or leave the addon loaded via "Load out of date AddOns"). `## Title: Guildprint`, `## SavedVariables: GuildprintDB`, `## SavedVariablesPerCharacter: GuildprintCharDB`. File order: `Logic.lua, Core.lua, UI\Widgets.lua, UI\Window.lua, Advertise.lua, Prompt.lua, FindPlayers.lua, Invite.lua`.

- [ ] **Step 2: Implement `Core.lua`**: on `ADDON_LOADED` for this addon: merge defaults into `GuildprintCharDB`, init `GuildprintDB.history`, prune it with 7 days, then `ns.Off("ADDON_LOADED")`. Register `/guildprint` and `/gp`.

- [ ] **Step 3: Write `deploy.sh`**: `rsync -a --delete Guildprint/ "/mnt/c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/Guildprint/"` (fallback `cp -r` if rsync missing). Make it executable.

- [ ] **Step 4: Verify** — `lua5.1 tests/run.lua` still passes; `luac5.1 -p Guildprint/*.lua` (or `lua5.1 -e 'assert(loadfile(...))'`) parses every file. Run `./deploy.sh`; ask the user to `/reload` in game and confirm: no Lua error, `/gp` prints nothing broken (window comes in Task 3).

- [ ] **Step 5: Commit** `feat: addon core, events, slash, deploy`

---

### Task 3: Themed window, shared pages, Options → AddOns, Messages and Whisper pages

**Files:**
- Create: `Guildprint/UI/Widgets.lua`, `Guildprint/UI/Window.lua`

**Interfaces:**
- Consumes: `ns.db`, `ns.slash`.
- Produces:
  - Widgets (`ns.UI`): `Button(parent, text, w, red: boolean) -> Button`, `Check(parent, label, get: fn()->bool, set: fn(bool)) -> CheckButton`, `Edit(parent, w, maxLetters, multiline: boolean) -> EditBox`, `Header(parent, text) -> FontString` (white header with thin gold rule), `Slider(parent, min, max, step, get, set, fmt) -> Slider`.
  - `ns.OpenWindow(page: string|nil)` — lazily creates the window (title "Guildprint", close ✕, left sidebar: Recruiting → Advertise, Find Players; Settings → Messages, Whisper) and shows `page` (default `"advertise"`).
  - `ns.RegisterPage(key: string, label: string, section: "Recruiting"|"Settings", build: fn(parent: Frame))` — `build` runs once, on first view of that page.
  - Options → AddOns entry via `Settings.RegisterCanvasLayoutCategory` + `Settings.RegisterAddOnCategory`; its canvas `OnShow` reparents the shared page container into the canvas, the window's `OnShow` reparents it back.
- Pages built here:
  - **Messages**: list of ads (name + preview) with radio-style active selection, New / Edit / Delete; editor = name `Edit` (32 chars) + text `Edit` (255 chars, multiline). Changes write to `ns.db.ads` / `ns.db.activeAd` (clamp `activeAd` after delete).
  - **Whisper**: one `Edit` (255) bound to `ns.db.whisper`, hint "{guild} becomes your guild name".

- [ ] **Step 1: Implement Widgets and Window.** Nothing is created at load except the Options category stub; the window, sidebar and each page build on first open.

- [ ] **Step 2: Deploy and verify in game** (ask user): `/gp` opens the window matching the screenshots' style; Messages: add, edit, delete, select active, survive `/reload`; text boxes stop at 255 chars; Options → AddOns → Guildprint shows the same pages; closing the window and opening Options shows content (reparenting works); no Lua errors.

- [ ] **Step 3: Commit** `feat: themed window, options panel, messages and whisper pages`

---

### Task 4: Advertise (post, channels, auto-prompt)

**Files:**
- Create: `Guildprint/Advertise.lua`, `Guildprint/Prompt.lua`

**Interfaces:**
- Consumes: `Logic.ActiveAdText`, `Logic.FillPlaceholders`, `Logic.FindChannelIds`, `Logic.ShouldPrompt`, `Logic.IsCapital`, `ns.On`, `ns.RegisterPage`, `ns.UI.*`.
- Produces:
  - `ns.PostAd()` — must be called from a click/keypress. Builds text with `GetGuildInfo("player")`, sends `SendChatMessage(text, "CHANNEL", nil, id)` (use `C_ChatInfo.SendChatMessage` if present) for each id from `FindChannelIds({GetChannelList()}, ns.db.channels)`, prints "Posted to Trade, General" or the reason nothing was sent. `ns.slash.post = ns.PostAd`.
  - `ns.ShowPrompt(zoneName: string)` in `Prompt.lua`.
- **Advertise page**: active ad dropdown/label, channel checkboxes for Trade, General, LookingForGroup plus any other currently joined channel (read `GetChannelList()` when the page is shown, not on load), triggers "Entering a capital city" / "Entering a new zone", cooldown slider 5–60 min, red **Post Ad Now** button, hint "Channel posts need one click (Blizzard rule)."
- **Triggers**: only while at least one trigger is on, listen to `ZONE_CHANGED_NEW_AREA`. On event: `blocked = InCombatLockdown() or IsInInstance()`; city = `Logic.IsCapital(C_Map.GetBestMapForUnit("player"))`; fire if (city and triggers.city) or (not city and triggers.zone) and `ShouldPrompt(time(), db.lastPromptAt, db.cooldownMin, blocked)`. Set `db.lastPromptAt` when shown.
- **Prompt**: small themed frame (lazy): "Welcome to <zone>", `Post "<ad name>" to <channels>?`, red **Post Ad**, grey **Not Now**, ✕. Auto-hides via one `C_Timer.NewTimer(30)` (cancel on hide). Draining bar = texture with a `Scale` animation (x 1→0 over 30 s) — no OnUpdate.

- [ ] **Step 1: Implement Advertise.lua and Prompt.lua.**
- [ ] **Step 2: `lua5.1 tests/run.lua` passes; deploy.**
- [ ] **Step 3: Verify in game** (ask user): Post Ad Now in Orgrimmar posts to Trade + General (if only the first channel posts, change PostAd to post one channel per click and note it); outside a city it posts only to General and says so; no ads → prints reason, nothing sent; entering a city shows the prompt, Post Ad sends, the prompt closes after 30 s with the bar draining; second zone change within 15 min shows nothing; no prompt in combat/instance; `/gp post` in a macro works; turning both triggers off unregisters the event (`/run print(...)` check optional).
- [ ] **Step 4: Commit** `feat: advertise page, posting and auto-prompt`

---

### Task 5: Find Players (who search, whisper/invite queue)

**Files:**
- Create: `Guildprint/FindPlayers.lua`

**Interfaces:**
- Consumes: `Logic.WhoQuery`, `Logic.FilterWho`, `Logic.FullName`, `Logic.FillPlaceholders`, `ns.history`, `ns.On/Off`, `ns.RegisterPage`, `ns.UI.*`.
- Produces: page `"find"`; `ns.QueueSend(names: table, kind: "whisper"|"invite")`.
- **Search**: level min/max inputs (defaults `db.minLevel`/`db.maxLevel`, saved on change); Search button → `WhoQuery`; nil → red error text under the inputs, no request. Else `C_FriendList.SetWhoToUi(true)`, register `WHO_LIST_UPDATE` (only for this one reply, then `Off`), `C_FriendList.SendWho(query)`. On reply read `C_FriendList.GetNumWhoResults()` / `GetWhoInfo(i)` into rows (`fullName` via `FullName`, `fullGuildName`, `level`, `filename` as classFile, `classStr`, `area`), `FilterWho` with 7 days, show list. If total ≥ 50 show "Showing first 50, narrow the level range." Prevent the default Who window from popping open (verify; hide `FriendsFrame` only if this addon caused it).
- **List**: one `ScrollBox`/`FauxScrollFrame` with recycled rows: checkbox, class-coloured name (`C_ClassColor.GetClassColor(classFile)`), level, class, zone; recent rows greyed + "whispered Nd ago". Buttons: red **Whisper selected (n)**, grey **Invite selected** (disabled when `not CanGuildInvite()`), **Stop** while a queue runs, progress "3 / 12".
- **Queue**: one `C_Timer.NewTicker(3, ...)` sends the next item (`SendChatMessage(FillPlaceholders(db.whisper, guild), "WHISPER", nil, name)` or `C_GuildInfo.Invite(name)`), records `ns.history[name] = time()` for whispers, cancels itself when empty or stopped. Starting a new queue while one runs is refused with a message.

- [ ] **Step 1: Implement FindPlayers.lua.**
- [ ] **Step 2: Tests pass; deploy.**
- [ ] **Step 3: Verify in game** (ask user): bad level inputs show error and send nothing; search 10–30 lists only unguilded players with class colours; Whisper selected sends ~3 s apart with progress, Stop halts it; whispered players appear greyed after a new search and after `/reload`; Invite selected sends invites (note any server throttle); Who window does not pop open.
- [ ] **Step 4: Commit** `feat: find players with throttled whisper and invite`

---

### Task 6: "Invite to Guild" in chat-name menu

**Files:**
- Create: `Guildprint/Invite.lua`

**Interfaces:**
- Consumes: `Logic.FullName`.
- Produces: menu entry only.

- [ ] **Step 1: Implement** `Menu.ModifyMenu(tag, fn)` for `"MENU_UNIT_FRIEND"` (chat names) and `"MENU_UNIT_PLAYER"`: when `CanGuildInvite()` and the target (`contextData.name`, `contextData.server`) is not in your guild (`C_GuildInfo.MemberExistsByName(name)` false), add `rootDescription:CreateButton("Invite to Guild", function() C_GuildInfo.Invite(FullName(name, server or GetNormalizedRealmName())) end)`. No `UnitPopup` table edits.
- [ ] **Step 2: Deploy; verify in game** (ask user): right-click a name in Trade → "Invite to Guild" appears and sends the invite; absent on a guild-mate and on a character without invite rights; no "action blocked" / taint errors after using the menu and then entering combat.
- [ ] **Step 3: Commit** `feat: invite to guild from chat name menu`

---

### Task 7: In-game verification pass and README

**Files:**
- Create: `README.md` (install via `deploy.sh`, slash commands, features, the one-click rule)

- [ ] **Step 1: Run the spec's "Must verify in-game" checklist with the user** and record results in `README.md` under "Verified on Forever 1.60.1": Interface number, multi-channel post per click, messaging limits, bulk invite throttle, menu taint.
- [ ] **Step 2: Performance check** (ask user): with the window closed and no queue running, `/run UpdateAddOnCPUUsage() UpdateAddOnMemoryUsage() print(GetAddOnMemoryUsage("Guildprint"))` after a few minutes of play shows stable memory (no steady growth); `grep -rn "OnUpdate" Guildprint/` returns nothing.
- [ ] **Step 3: Commit** `docs: readme and verification results`
