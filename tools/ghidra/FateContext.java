// Decompile a single Fate span in an analysis project.
// @category Fate
import ghidra.app.cmd.disassemble.DisassembleCommand;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSet;
import ghidra.program.model.listing.Function;

public class FateContext extends GhidraScript {
    @Override
    protected void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length != 2) {
            throw new IllegalArgumentException("Usage: FateContext.java ENTRY SPAN_BYTES");
        }
        long offset = Long.decode(args[0]);
        int size = Integer.decode(args[1]);
        if (size <= 0) {
            throw new IllegalArgumentException("Expected a positive span size");
        }
        Address entry = toAddr(offset);
        Address last = entry.add(size - 1L);
        AddressSet span = new AddressSet(entry, last);
        if (!currentProgram.getMemory().contains(entry, last)) {
            throw new IllegalArgumentException("Span is outside the imported image");
        }
        DisassembleCommand command = new DisassembleCommand(entry, span, true);
        if (!command.applyTo(currentProgram, monitor)) {
            throw new IllegalStateException("Disassembly failed at " + entry);
        }
        Function function = getFunctionAt(entry);
        if (function == null) {
            function = createFunction(entry, null);
        }
        if (function == null || !span.contains(function.getBody())) {
            throw new IllegalStateException("No function lies wholly inside the selected span");
        }

        DecompInterface decompiler = new DecompInterface();
        try {
            if (!decompiler.openProgram(currentProgram)) {
                throw new IllegalStateException(decompiler.getLastMessage());
            }
            DecompileResults result = decompiler.decompileFunction(function, 30, monitor);
            if (!result.decompileCompleted() || result.getDecompiledFunction() == null) {
                throw new IllegalStateException(result.getErrorMessage());
            }
            String draft = result.getDecompiledFunction().getC();
            int limit = 12000;
            println("Fate analysis draft at " + entry + "\n" + draft.substring(0, Math.min(draft.length(), limit)));
            if (draft.length() > limit) {
                println("[Draft truncated at " + limit + " characters]");
            }
        } finally {
            decompiler.dispose();
        }
    }
}
