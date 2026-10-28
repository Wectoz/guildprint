-- Runs pure-logic tests outside the game: lua5.1 tests/run.lua
local ns = {}
assert(loadfile("Guildprint/Logic.lua"))("Guildprint", ns)

local env = setmetatable({ L = ns.Logic }, { __index = _G })
local chunk = assert(loadfile("tests/test_logic.lua"))
setfenv(chunk, env)
chunk()

local names = {}
for k, v in pairs(env) do
  if type(v) == "function" and k:match("^test_") then names[#names + 1] = k end
end
table.sort(names)

local passed, failed = 0, 0
for _, name in ipairs(names) do
  local ok, err = pcall(env[name])
  if ok then passed = passed + 1 else failed = failed + 1; print("FAIL " .. name .. ": " .. tostring(err)) end
end
print(("PASS %d, FAIL %d"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
