function test_fill_guild()   assert(L.FillPlaceholders("{guild} rocks", "Iron Oath") == "Iron Oath rocks") end
function test_fill_noguild() assert(L.FillPlaceholders("{guild}!", nil) == "our guild!") end
function test_fill_trunc()   assert(#L.FillPlaceholders(("x"):rep(250) .. "{guild}", "Iron Oath") == 255) end
function test_active_none()  assert(L.ActiveAdText({ ads = {}, activeAd = 1 }) == nil) end
function test_active_blank() assert(L.ActiveAdText({ ads = { { name = "a", text = "  " } }, activeAd = 1 }) == nil) end
function test_active_ok()    assert(L.ActiveAdText({ ads = { { name = "a", text = "hi" } }, activeAd = 1 }) == "hi") end
function test_prompt_cool()  assert(L.ShouldPrompt(1000, 900, 15, false) == false) end
function test_prompt_ok()    assert(L.ShouldPrompt(2000, 1000, 15, false) == true) end
function test_prompt_block() assert(L.ShouldPrompt(5000, 0, 15, true) == false) end
function test_channels()
  local list = { 1, "General - Durotar", false, 2, "Trade - City", false, 4, "LookingForGroup", false, 5, "MyGuildChan", false }
  local ids = L.FindChannelIds(list, { General = true, Trade = true, LookingForGroup = false, MyGuildChan = true })
  assert(#ids == 3 and ids[1] == 1 and ids[2] == 2 and ids[3] == 5)
end
function test_channels_none()     assert(#L.FindChannelIds({ 1, "General - Durotar", false }, { Trade = true }) == 0) end
function test_channels_disabled() assert(#L.FindChannelIds({ 2, "Trade - City", true }, { Trade = true }) == 0) end
function test_who_ok()  assert(L.WhoQuery("10", 30) == "10-30") end
function test_who_bad()
  assert(L.WhoQuery("", 30) == nil and L.WhoQuery("abc", 30) == nil and L.WhoQuery(40, 30) == nil
    and L.WhoQuery(0, 30) == nil and L.WhoQuery(10, 61) == nil)
end
function test_prune()
  local h = { ["A-R"] = 100, ["B-R"] = 1e6 }
  L.PruneHistory(h, 1e6, 7)
  assert(h["A-R"] == nil and h["B-R"])
end
function test_filter_who()
  local rows = L.FilterWho({
    { name = "A-R", guild = "", level = 10 }, { name = "B-R", guild = "Foo", level = 12 }, { name = "C-R", guild = "", level = 14 },
  }, { ["C-R"] = 1e6 - 3600 }, 1e6, 7)
  assert(#rows == 2 and rows[1].selected == true and rows[2].recent == true and rows[2].selected == false)
end
function test_merge()
  local db = L.MergeDefaults({ cooldownMin = 5, channels = { Trade = false } }, L.DEFAULTS)
  assert(db.cooldownMin == 5 and db.channels.Trade == false and db.channels.General == true and #db.ads == 1)
  assert(db.channels ~= L.DEFAULTS.channels and db.ads ~= L.DEFAULTS.ads)
end
function test_capital() assert(L.IsCapital(1454) and not L.IsCapital(1411)) end
function test_channel_base() assert(L.ChannelBase("General - Durotar") == "General" and L.ChannelBase("Trade") == "Trade") end
function test_recent()
  local h = { ["A-R"] = 1e6 - 3600, ["B-R"] = 100 }
  assert(L.IsRecent(h, "A-R", 1e6, 7) and not L.IsRecent(h, "B-R", 1e6, 7) and not L.IsRecent(h, "C-R", 1e6, 7))
end
function test_fill_utf8_trunc()
  local out = L.FillPlaceholders(("x"):rep(254) .. "ö", nil)  -- ö is 2 bytes, cut lands inside it
  assert(out == ("x"):rep(254), "partial UTF-8 char left at end")
end
function test_fill_newlines() assert(L.FillPlaceholders("line one\nline two", nil) == "line one line two") end
function test_has_text() assert(L.HasText("hi") and not L.HasText("  ") and not L.HasText("") and not L.HasText(nil)) end
function test_capital_retail_ids() assert(L.IsCapital(84) and L.IsCapital(85)) end
