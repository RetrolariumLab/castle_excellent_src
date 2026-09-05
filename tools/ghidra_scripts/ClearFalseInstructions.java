// Remove proven false-positive instruction starts before evidence disassembly.
//@category CastleExcellent

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.Listing;
import ghidra.program.model.mem.MemoryBlock;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

public class ClearFalseInstructions extends GhidraScript {
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
            throw new IllegalArgumentException("expected false-instruction registry path");
        }
        List<String> lines = Files.readAllLines(
            Path.of(args[0]).toAbsolutePath(), StandardCharsets.UTF_8
        );
        MemoryBlock prg = findPrg();
        if (prg == null) {
            throw new IllegalStateException("initialized 32 KiB PRG block not found");
        }
        Listing listing = currentProgram.getListing();
        int registered = 0;
        int cleared = 0;
        for (String raw : lines) {
            String line = raw.trim();
            if (line.isEmpty() || line.startsWith("#")) {
                continue;
            }
            String[] fields = line.split("\\s+");
            if (fields.length != 3 || !fields[0].equals("instruction")) {
                throw new IllegalArgumentException(
                    "invalid false-instruction line: " + raw
                );
            }
            long offset = Long.parseLong(fields[1], 16);
            if (offset < 0x8000 || offset > 0xffff) {
                throw new IllegalArgumentException(
                    "invalid false-instruction address: " + raw
                );
            }
            Address address = prg.getStart().getAddressSpace().getAddress(offset);
            Instruction instruction = listing.getInstructionAt(address);
            if (instruction != null) {
                clearListing(instruction.getMinAddress(), instruction.getMaxAddress());
                cleared++;
            }
            registered++;
        }
        println(
            "[OK] cleared " + cleared + " of " + registered +
            " registered false-positive instruction starts"
        );
    }
}
