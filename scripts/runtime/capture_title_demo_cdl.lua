-- Deterministic title/attract-mode CDL capture for Castle Excellent (Japan).

local output_path = assert(os.getenv("CASTLE_CDL_OUTPUT"))
local metadata_path = assert(os.getenv("CASTLE_CDL_METADATA"))
local max_frames = assert(tonumber(os.getenv("CASTLE_CDL_MAX_FRAMES")))
local start_frame = emu.framecount()

assert(cdlog.docdlogger() ~= 0, "cannot initialize FCEUX code/data logger")
cdlog.resetcdlog()
cdlog.startcdlogging()

while emu.framecount() - start_frame < max_frames do
    joypad.set(1, {})
    emu.frameadvance()
end

cdlog.pausecdlogging()
cdlog.savecdlogfileas(output_path)

local metadata = assert(io.open(metadata_path, "w"))
metadata:write(string.format("start_frame=%d\n", start_frame))
metadata:write(string.format("end_frame=%d\n", emu.framecount()))
metadata:write(string.format("frames=%d\n", emu.framecount() - start_frame))
metadata:write("scenario=title-demo\n")
metadata:close()
emu.exit()
