-- Deterministic Source 1.0 runtime-path capture for Castle Excellent (Japan).

local output_path = assert(os.getenv("CASTLE_CDL_OUTPUT"))
local metadata_path = assert(os.getenv("CASTLE_CDL_METADATA"))
local max_frames = assert(tonumber(os.getenv("CASTLE_CDL_MAX_FRAMES")))
local scenario = assert(os.getenv("CASTLE_RUNTIME_SCENARIO"))
local start_frame = emu.framecount()

local scenarios = {
    ["room-transition"] = {
        required = {
            "TransitionToRoomAbove",
            "LoadRoom",
            "FinishRoomTransition",
        },
    },
    ["death-game-over"] = {
        required = {
            "StartPlayerDeathTransition",
            "CompletePlayerTransition",
            "RunGameOverSequence",
        },
    },
    ["completion-ending"] = {
        required = {
            "HandleRuntimeType82PlayerCollision",
            "RunType82CompletionSequence",
        },
    },
    ["save-load-entry"] = {
        required = {
            "OpenSubCommandMenu",
            "SaveGameState",
            "SendSaveDataSignature",
            "LoadGameState",
            "HandleLoadFailure",
        },
    },
}

local selected = assert(scenarios[scenario], "unknown runtime scenario")
local hits = {}
local hit_frames = {}
local main_loop_seen = false
local injected = false
local menu_stage = "open-save"
local menu_open_count = 0

local function symbol(name)
    local address = debugger.getsymboloffset(name)
    assert(address >= 0, "missing debugger symbol: " .. name)
    return address
end

local function record(name)
    if not hits[name] then
        hits[name] = true
    end
    -- Keep the latest hit so setup-time calls cannot masquerade as the
    -- state-injected path that follows them.
    hit_frames[name] = emu.framecount()
end

for _, name in ipairs(selected.required) do
    memory.registerexecute(symbol(name), function()
        record(name)
    end)
end

memory.registerexecute(symbol("MainFrameLoop"), function()
    main_loop_seen = true
end)

if scenario == "death-game-over" then
    memory.registerexecute(symbol("UpdatePlayerCollisionState"), function()
        if main_loop_seen and not injected then
            -- Inject the post-sampling hazard latch at the collision entry.
            memory.writebyte(0x077C, 0xFF)
            memory.writebyte(0x000D, 0x00)
            injected = true
        end
    end)
    memory.registerexecute(symbol("StartPlayerDeathTransition"), function()
        record("StartPlayerDeathTransition")
        -- Make this deterministic death consume the final life.
        memory.writebyte(0x0013, 0x00)
    end)
elseif scenario == "save-load-entry" then
    memory.registerexecute(symbol("HandleSubCommandInput"), function()
        if main_loop_seen and (menu_stage == "open-save" or menu_stage == "open-load") then
            -- Inject the controller-2 edge after NMI polling, immediately before
            -- the game's normal sub-command gate consumes it.
            memory.writebyte(0x0776, 0x01)
            memory.writebyte(0x0778, 0x00)
        end
    end)
    memory.registerexecute(symbol("OpenSubCommandMenu"), function()
        record("OpenSubCommandMenu")
        menu_open_count = menu_open_count + 1
        if menu_open_count == 1 then
            menu_stage = "select-save"
        else
            menu_stage = "select-load"
        end
    end)
    memory.registerexecute(symbol("UpdateSubCommandMenu"), function()
        if menu_stage == "select-save" then
            memory.writebyte(0x001D, 0x03)
            memory.writebyte(0x001C, 0xFF)
        elseif menu_stage == "select-load" then
            memory.writebyte(0x001D, 0x02)
            memory.writebyte(0x001C, 0xFF)
        end
    end)
    memory.registerexecute(symbol("SaveGameState"), function()
        record("SaveGameState")
        menu_stage = "saving"
    end)
    memory.registerexecute(symbol("ExitSubCommandMenu"), function()
        if hits["SendSaveDataSignature"] then
            menu_stage = "open-load"
        end
    end)
end

if scenario == "completion-ending" then
    memory.registerexecute(symbol("UpdatePlayerCollisionState"), function()
        if main_loop_seen and not injected then
            -- Insert the terminal object after its update pass and directly before
            -- the seven normal player collision probes consume the object pool.
            memory.writebyte(0x004A, 0x82)
            memory.writebyte(0x004B, memory.readbyte(0x0038))
            memory.writebyte(0x004C, memory.readbyte(0x0039))
            -- Type $82's interaction anchor is 15 pixels above the player origin:
            -- this overlaps the top probes and satisfies its |objectY+16-playerY|<4
            -- proximity contract.
            memory.writebyte(0x004D, (memory.readbyte(0x003A) - 15) % 256)
            memory.writebyte(0x004E, 0x00)
            memory.writebyte(0x004F, 0x00)
            injected = true
        end
    end)
end

local function complete()
    for _, name in ipairs(selected.required) do
        if not hits[name] then
            return false
        end
    end
    return true
end

assert(cdlog.docdlogger() ~= 0, "cannot initialize FCEUX code/data logger")
cdlog.resetcdlog()
cdlog.startcdlogging()

while emu.framecount() - start_frame < max_frames and not complete() do
    local relative_frame = emu.framecount() - start_frame
    local pad1 = {}
    local pad2 = {}

    if relative_frame >= 30 and relative_frame < 32 then
        pad1.start = true
    end

    if main_loop_seen and not injected then
        if scenario == "room-transition" then
            -- Room $47 has an above neighbour; Y=0 takes the normal boundary path.
            memory.writebyte(0x003A, 0x00)
            injected = true
        elseif scenario == "save-load-entry" then
            injected = true
        end
    end

    if scenario == "save-load-entry" and main_loop_seen then
        if menu_stage == "open-save" or menu_stage == "open-load" then
            pad2.A = true
        elseif menu_stage == "select-save" or menu_stage == "select-load" then
            -- Start selects the finite expansion-port transport; A also acknowledges
            -- the expected no-device load error without an emulator-side hang.
            pad1.start = true
            pad1.A = true
        end
    end

    joypad.set(1, pad1)
    joypad.set(2, pad2)
    emu.frameadvance()
end

joypad.set(1, {})
joypad.set(2, {})
cdlog.pausecdlogging()
cdlog.savecdlogfileas(output_path)

local metadata = assert(io.open(metadata_path, "w"))
metadata:write(string.format("start_frame=%d\n", start_frame))
metadata:write(string.format("end_frame=%d\n", emu.framecount()))
metadata:write(string.format("frames=%d\n", emu.framecount() - start_frame))
metadata:write(string.format("scenario=%s\n", scenario))
metadata:write(string.format("status=%s\n", complete() and "ok" or "incomplete"))
metadata:write(string.format("state_injection=%s\n", injected and "yes" or "no"))
for _, name in ipairs(selected.required) do
    if hits[name] then
        metadata:write(string.format("hit=%s@%d\n", name, hit_frames[name]))
    else
        metadata:write(string.format("miss=%s\n", name))
    end
end
metadata:close()
emu.exit()
