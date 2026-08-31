// Remove false-positive instructions from evidence-backed PRG data ranges.
//@category CastleExcellent

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSet;
import ghidra.program.model.listing.InstructionIterator;
import ghidra.program.model.mem.MemoryBlock;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

public class ClearKnownData extends GhidraScript {
    private MemoryBlock findPrg() {
        for (MemoryBlock block : currentProgram.getMemory().getBlocks()) {
            if (block.isInitialized() && block.isExecute() && block.getSize() == 0x8000 &&
                block.getStart().getOffset() == 0x8000) {
                return block;
            }
        }
        return null;
    }

    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length != 1) {
            throw new IllegalArgumentException("expected typed data ranges path");
        }
        List<String> lines = Files.readAllLines(
            Path.of(args[0]).toAbsolutePath(), StandardCharsets.UTF_8
        );
        MemoryBlock prg = findPrg();
        if (prg == null) {
            throw new IllegalStateException("initialized 32 KiB PRG block not found");
        }
        int rangeCount = 0;
        int instructionCount = 0;
        for (String raw : lines) {
            String line = raw.trim();
            if (line.isEmpty() || line.startsWith("#")) {
                continue;
            }
            String[] fields = line.split("\\s+");
            if (fields.length != 4) {
                throw new IllegalArgumentException("invalid typed data line: " + raw);
            }
            long start = Long.parseLong(fields[1], 16);
            long end = Long.parseLong(fields[2], 16);
            if (start < 0x8000 || end > 0xffff || end < start) {
                throw new IllegalArgumentException("invalid typed PRG range: " + raw);
            }
            Address first = prg.getStart().getAddressSpace().getAddress(start);
            Address last = prg.getStart().getAddressSpace().getAddress(end);
            InstructionIterator instructions = currentProgram.getListing().getInstructions(
                new AddressSet(first, last), true
            );
            while (instructions.hasNext()) {
                instructions.next();
                instructionCount++;
            }
            clearListing(first, last);
            rangeCount++;
        }
        println(
            "[OK] cleared " + rangeCount + " typed data ranges and " +
            instructionCount + " false-positive instructions"
        );
    }
}
