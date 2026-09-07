-- Observe the fixed-layout starting-room variant through the normal boot path.

local result_path = assert(os.getenv("CASTLE_FIXED_LAYOUT_RESULT"))
local main_frame_loop = 0x8282
local entered_gameplay = false

memory.registerexecute(main_frame_loop, function()
    entered_gameplay = true
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
local result = assert(io.open(result_path, "w"))
result:write(string.format(
    "status=%s room=%d frame=%d\n",
    entered_gameplay and "ok" or "timeout",
    memory.readbyte(0x0037),
    emu.framecount()
))
result:close()
emu.exit()
