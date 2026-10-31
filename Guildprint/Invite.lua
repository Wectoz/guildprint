-- "Invite to Guild" in the right-click menu of player names (chat, friends, targets).
local _, ns = ...

local function AddInvite(_, rootDescription, contextData)
  if not CanGuildInvite() or not contextData or not contextData.name then return end
  -- Blizzard's own helper: handles realm and Forever surname formats
  local name = UnitPopupSharedUtil.GetFullPlayerName(contextData) or contextData.name
  if name == UnitNameUnmodified("player") or C_GuildInfo.MemberExistsByName(name) then return end
  rootDescription:CreateDivider()
  rootDescription:CreateButton("Invite to Guild", function()
    ns.Invite(name)
    ns.Print("Guild invite sent to " .. name .. ".")
  end)
end

Menu.ModifyMenu("MENU_UNIT_FRIEND", AddInvite)
Menu.ModifyMenu("MENU_UNIT_PLAYER", AddInvite)
