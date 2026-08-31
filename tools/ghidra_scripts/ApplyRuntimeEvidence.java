// Apply execution-proven code ranges before exporting instruction facts.
//@category CastleExcellent

import ghidra.app.cmd.disassemble.DisassembleCommand;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.Listing;
import ghidra.program.model.mem.MemoryBlock;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.ArrayList;

public class ApplyRuntimeEvidence extends GhidraScript {
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
            throw new IllegalArgumentException("expected runtime evidence path");
        }
        List<String> lines = Files.readAllLines(
            Path.of(args[0]).toAbsolutePath(), StandardCharsets.UTF_8
        );
        Listing listing = currentProgram.getListing();
        MemoryBlock prg = findPrg();
        if (prg == null) {
            throw new IllegalStateException("initialized 32 KiB PRG block not found");
        }
        List<long[]> codeRanges = new ArrayList<>();
        int created = 0;
        for (String raw : lines) {
            String line = raw.trim();
            if (line.isEmpty() || line.startsWith("#")) {
                continue;
            }
            String[] fields = line.split("\\s+");
            if (fields.length != 3) {
                throw new IllegalArgumentException("invalid evidence line: " + raw);
            }
            if (!fields[0].equals("code")) {
                continue;
            }
            long start = Long.parseLong(fields[1], 16);
            long end = Long.parseLong(fields[2], 16);
            if (start < 0x8000 || end > 0xffff || end < start) {
                throw new IllegalArgumentException("invalid PRG code range: " + raw);
            }
            codeRanges.add(new long[] { start, end });
        }

        // Auto-analysis may have created multi-byte data units. Clear all such
        // units before disassembly so an instruction can flow across them.
        for (long[] range : codeRanges) {
            long offset = range[0];
            while (offset <= range[1]) {
                Address address = prg.getStart().getAddressSpace().getAddress(offset);
                Data data = listing.getDataContaining(address);
                if (data == null) {
                    offset++;
                    continue;
                }
                long next = data.getMaxAddress().getOffset() + 1;
                clearListing(data.getMinAddress(), data.getMaxAddress());
                offset = next;
            }
        }

        for (long[] range : codeRanges) {
            long start = range[0];
            long end = range[1];
            long offset = start;
            while (offset <= end) {
                Address address = prg.getStart().getAddressSpace().getAddress(offset);
                Instruction existing = listing.getInstructionContaining(address);
                if (existing != null) {
                    offset = existing.getMaxAddress().getOffset() + 1;
                    continue;
                }
                DisassembleCommand command = new DisassembleCommand(address, null, true);
                command.applyTo(currentProgram, monitor);
                Instruction instruction = listing.getInstructionAt(address);
                if (instruction == null) {
                    printerr("could not disassemble execution-proven address " + address);
                    offset++;
                } else {
                    created++;
                    offset = instruction.getMaxAddress().getOffset() + 1;
                }
            }
        }
        println("[OK] applied " + codeRanges.size() + " runtime code ranges; created " + created + " instructions");
    }
}
