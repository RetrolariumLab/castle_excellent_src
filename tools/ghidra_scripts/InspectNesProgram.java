// Inspect the imported NES program and emit a small deterministic JSON report.
//@category CastleExcellent

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import ghidra.program.model.listing.InstructionIterator;
import ghidra.program.model.mem.MemoryBlock;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

public class InspectNesProgram extends GhidraScript {
    private static String quote(String value) {
        return "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\"";
    }

    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length != 1) {
            throw new IllegalArgumentException("expected output JSON path");
        }

        long instructionCount = 0;
        InstructionIterator instructions = currentProgram.getListing().getInstructions(true);
        while (instructions.hasNext()) {
            instructions.next();
            instructionCount++;
        }

        List<String> blocks = new ArrayList<>();
        for (MemoryBlock block : currentProgram.getMemory().getBlocks()) {
            blocks.add(
                "    {\"name\":" + quote(block.getName()) +
                ",\"space\":" + quote(block.getStart().getAddressSpace().getName()) +
                ",\"start\":" + quote(block.getStart().toString()) +
                ",\"end\":" + quote(block.getEnd().toString()) +
                ",\"size\":" + block.getSize() +
                ",\"initialized\":" + block.isInitialized() +
                ",\"execute\":" + block.isExecute() + "}"
            );
        }

        List<String> functions = new ArrayList<>();
        FunctionIterator iterator = currentProgram.getFunctionManager().getFunctions(true);
        while (iterator.hasNext()) {
            Function function = iterator.next();
            Address entry = function.getEntryPoint();
            functions.add(
                "    {\"name\":" + quote(function.getName()) +
                ",\"entry\":" + quote(entry.toString()) + "}"
            );
        }

        String report = "{\n" +
            "  \"program\":" + quote(currentProgram.getName()) + ",\n" +
            "  \"language\":" + quote(currentProgram.getLanguageID().toString()) + ",\n" +
            "  \"compiler\":" + quote(currentProgram.getCompilerSpec().getCompilerSpecID().toString()) + ",\n" +
            "  \"image_base\":" + quote(currentProgram.getImageBase().toString()) + ",\n" +
            "  \"instruction_count\":" + instructionCount + ",\n" +
            "  \"blocks\":[\n" + String.join(",\n", blocks) + "\n  ],\n" +
            "  \"functions\":[\n" + String.join(",\n", functions) + "\n  ]\n" +
            "}\n";
        Path output = Path.of(args[0]).toAbsolutePath();
        Files.createDirectories(output.getParent());
        Files.writeString(output, report, StandardCharsets.UTF_8);
        println("[OK] wrote NES analysis report to " + output);
    }
}
