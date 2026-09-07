-- Deterministic boot/gameplay CDL capture for Castle Excellent (Japan).

local output_path = assert(os.getenv("CASTLE_CDL_OUTPUT"))
local metadata_path = assert(os.getenv("CASTLE_CDL_METADATA"))
local max_frames = assert(tonumber(os.getenv("CASTLE_CDL_MAX_FRAMES")))
local start_frame = emu.framecount()

-- The Win32 backend allocates CDL buffers when its logger window is created.
assert(cdlog.docdlogger() ~= 0, "cannot initialize FCEUX code/data logger")
cdlog.resetcdlog()
cdlog.startcdlogging()

while emu.framecount() - start_frame < max_frames do
    local frame = emu.framecount() - start_frame
    local buttons = {}
    if frame >= 30 and frame < 32 then
        buttons.start = true
    elseif frame >= 180 and frame < 300 then
        buttons.right = true
    elseif frame >= 300 and frame < 302 then
        buttons.A = true
        buttons.right = true
    elseif frame >= 420 and frame < 500 then
        buttons.left = true
    elseif frame >= 540 and frame < 542 then
        buttons.B = true
    end
    joypad.set(1, buttons)
    emu.frameadvance()
end

joypad.set(1, {})
cdlog.pausecdlogging()
cdlog.savecdlogfileas(output_path)

local metadata = assert(io.open(metadata_path, "w"))
metadata:write(string.format("start_frame=%d\n", start_frame))
metadata:write(string.format("end_frame=%d\n", emu.framecount()))
metadata:write(string.format("frames=%d\n", emu.framecount() - start_frame))
metadata:write("scenario=boot-gameplay\n")
metadata:close()
emu.exit()
