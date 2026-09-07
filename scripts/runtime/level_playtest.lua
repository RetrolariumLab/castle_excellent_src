-- Enter an authored Castle Excellent room and place the player at an editor point.

local function setting(name, minimum, maximum)
    local value = tonumber(os.getenv(name) or "")
    if value == nil or value < minimum or value > maximum then
        error(name .. " must be in range " .. minimum .. ".." .. maximum)
    end
    return value
end

local room = setting("CASTLE_PLAYTEST_ROOM", 1, 100)
local player_x = setting("CASTLE_PLAYTEST_X", 0, 319)
local player_y = setting("CASTLE_PLAYTEST_Y", 0, 159)
local initialize_new_game = 0xA2B1
local main_frame_loop = 0x8282
assert(memory.readbyte(initialize_new_game) == 0xA9,
    "InitializeNewGame layout no longer matches the playtest contract")
assert(memory.readbyte(initialize_new_game + 2) == 0x85,
    "CurrentRoomNumber store no longer matches the playtest contract")

local entered_gameplay = false

-- The hook follows LDA #InitialRoomNumber / STA CurrentRoomNumber. This keeps
-- the authored ROM unchanged and lets the normal LoadRoom path do all setup.
memory.registerexecute(initialize_new_game + 4, function()
    memory.writebyte(0x0037, room)
end)

memory.registerexecute(main_frame_loop, function()
    if not entered_gameplay then
        memory.writebyte(0x0038, player_x % 256)
        memory.writebyte(0x0039, math.floor(player_x / 256))
        memory.writebyte(0x003A, player_y)
        entered_gameplay = true
    end
end)

local start_frame = emu.framecount()
while not entered_gameplay and emu.framecount() - start_frame < 900 do
    local frame = emu.framecount() - start_frame
    local buttons = {}
    if frame >= 30 and frame < 32 then
        buttons.start = true
    end
    joypad.set(1, buttons)
    emu.frameadvance()
end

joypad.set(1, {})
assert(entered_gameplay, "Castle Excellent playtest did not enter gameplay")

local result_path = os.getenv("CASTLE_PLAYTEST_RESULT")
if result_path ~= nil and result_path ~= "" then
    local result = assert(io.open(result_path, "w"))
    result:write(string.format(
        "status=ok room=%d x=%d y=%d frame=%d\n",
        memory.readbyte(0x0037),
        memory.readbyte(0x0038) + 256 * memory.readbyte(0x0039),
        memory.readbyte(0x003A),
        emu.framecount()
    ))
    result:close()
end

if os.getenv("CASTLE_PLAYTEST_EXIT") == "1" then
    emu.exit()
end
