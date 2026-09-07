-- Prove that FCEUX loaded generated semantic symbols and can break on one.

local output_path = assert(os.getenv("CASTLE_DEBUG_SYMBOL_RESULT"))
local output = assert(io.open(output_path, "w"))

local expected = {
    Nmi = 0xC569,
    MainFrameLoop = 0x8282,
    DecodeRoom = 0xE830,
    UpdateRuntimeObjects = 0x9583,
    UpdateAudioStreams = 0xB923,
    RuntimeObjectRecords = 0x004A,
    RoomCells = 0x0400,
}

for symbol, expected_address in pairs(expected) do
    local actual_address = debugger.getsymboloffset(symbol)
    output:write(string.format(
        "symbol,%s,%04X,%04X\n", symbol, actual_address, expected_address))
    if actual_address ~= expected_address then
        output:write("FAIL,symbol_lookup\n")
        output:close()
        emu.exit()
        return
    end
end

local frame_loop_address = debugger.getsymboloffset("MainFrameLoop")
local frame_loop_hit = false
memory.registerexecute(frame_loop_address, function()
    frame_loop_hit = true
end)

for _ = 1, 900 do
    if frame_loop_hit then
        break
    end
    emu.frameadvance()
end

if not frame_loop_hit then
    output:write("FAIL,semantic_breakpoint\n")
else
    output:write(string.format(
        "break,MainFrameLoop,%04X,%d\n", frame_loop_address, emu.framecount()))
    output:write("OK\n")
end
output:close()
emu.exit()
