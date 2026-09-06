-- Direct Castlequest startup and three-entry sub-command runtime scenario.

local result_path = assert(os.getenv("CASTLEQUEST_RUNTIME_RESULT"))
local addresses = {
    main = 0x8282,
    handle_sub_command = 0xF9AD,
    open_sub_command = 0xF9CC,
    update_sub_command = 0xFA74,
    load_sub_command = 0xFB71,
    save_sub_command = 0xFB74,
}

local main_seen = false
local menu_open = false
local menu_input_frames = 0
local selections = {}
local previous_selection = nil
local wrapped = false
local load_hit = false
local save_hit = false
local lives = -1
local room = -1

memory.registerexecute(addresses.main, function()
    if not main_seen then
        main_seen = true
        lives = memory.readbyte(0x0013)
        room = memory.readbyte(0x0037)
    end
end)

memory.registerexecute(addresses.handle_sub_command, function()
    if main_seen and not menu_open then
        memory.writebyte(0x0776, 0x01)
        memory.writebyte(0x0778, 0x00)
    end
end)

memory.registerexecute(addresses.open_sub_command, function()
    menu_open = true
end)

memory.registerexecute(addresses.update_sub_command, function()
    local selection = memory.readbyte(0x001D)
    if selection ~= previous_selection then
        selections[#selections + 1] = selection
        if previous_selection == 2 and selection == 0 then
            wrapped = true
        end
        previous_selection = selection
    end
end)

memory.registerexecute(addresses.load_sub_command, function()
    load_hit = true
end)

memory.registerexecute(addresses.save_sub_command, function()
    save_hit = true
end)

local start_frame = emu.framecount()
while emu.framecount() - start_frame < 900 and not wrapped do
    local frame = emu.framecount() - start_frame
    local buttons = {}
    if frame >= 30 and frame < 32 then
        buttons.start = true
    elseif menu_open then
        menu_input_frames = menu_input_frames + 1
        -- The menu polls inside its own vblank loop. Hold each edge for three
        -- frames and leave a long release interval so every poll sees both.
        if menu_input_frames % 20 < 3 then
            buttons.down = true
        end
    end
    joypad.set(1, buttons)
    emu.frameadvance()
end

joypad.set(1, {})
local status = "ok"
if not main_seen or not menu_open or not wrapped or load_hit or save_hit then
    status = "incomplete"
end
local result = assert(io.open(result_path, "w"))
result:write(string.format(
    "status=%s lives=%d room=%d menu_open=%d selections=%s load=%d save=%d frame=%d\n",
    status,
    lives,
    room,
    menu_open and 1 or 0,
    table.concat(selections, ","),
    load_hit and 1 or 0,
    save_hit and 1 or 0,
    emu.framecount()
))
result:close()
emu.exit()
