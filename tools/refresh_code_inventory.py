"""Refresh exact CODE inventories and link the compiled objects against a pinned reference."""

import argparse
import json
from hashlib import sha256
from pathlib import Path
import subprocess
import sys

from build_fate_exe import TARGET_SHA256
from verify_ci_build import INPUTS, ROOT, TOOLS, verify_inputs
from restoration_build import assert_fresh


def run(script, *args):
    subprocess.run([sys.executable, TOOLS / script, *args], cwd=ROOT, check=True)


def preserve_object_hashes(report, previous):
    # Watcom embeds timestamps in some OMF records. Retain provenance when
    # the object name and verified machine-code span are unchanged.
    def key(row):
        return row["raw_offset"], row.get("object"), row.get("sha256")

    for group in ("spans", "non_routine_code_spans"):
        hashes = {
            key(row): row["object_sha256"]
            for row in previous[group] if "object_sha256" in row
        }
        for row in report[group]:
            if key(row) in hashes:
                row["object_sha256"] = hashes[key(row)]


def refresh(build, reference):
    expected = reference.read_bytes()
    if sha256(expected).hexdigest() != TARGET_SHA256:
        raise ValueError("Reference executable does not match the pinned SHA-256")
    verify_inputs()
    assert_fresh(build)

    assembly = build / "asm"
    c_report = build / "c.json"
    assembly_report = build / "assembly.json"
    executable = build / "FATE.EXE"
    if executable == reference:
        raise ValueError("Reference and build output must be separate files")
    run("build_assembly.py", INPUTS / "nasm/nasm.exe", assembly)
    run("verify_c_suite.py", reference, build, "--output", c_report)
    run("verify_assembly_suite.py", reference, assembly, c_report, "--output", assembly_report)

    inventory_dir = TOOLS / "data"
    c_inventory = inventory_dir / "matching-routines.json"
    assembly_inventory = inventory_dir / "matching-assembly.json"
    originals = {path: path.read_bytes() for path in (c_inventory, assembly_inventory)}
    c = json.loads(c_report.read_bytes())
    asm = json.loads(assembly_report.read_bytes())
    preserve_object_hashes(c, json.loads(originals[c_inventory]))

    try:
        for path, report in ((c_inventory, c), (assembly_inventory, asm)):
            path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8", newline="\n")
        run("build_fate_exe.py", build, assembly, INPUTS / "demo/dos-stub.bin", executable)
        if executable.read_bytes() != expected:
            raise ValueError("Linked executable differs from the pinned reference")
    except BaseException:
        for path, content in originals.items():
            path.write_bytes(content)
        raise

    c_bytes = c["unique_code_bytes"]
    run("restoration_coverage.py", "--write")
    asm_bytes = asm["unique_code_bytes"]
    print(f'{c["routines"]} C routines, {c_bytes:,} of {c_bytes + asm_bytes:,} CODE bytes '
          f'({c_bytes / (c_bytes + asm_bytes):.2%})')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("build", type=Path, help="Scratch directory containing Watcom objects")
    parser.add_argument("reference", type=Path, help="Known byte-identical FATE.EXE")
    args = parser.parse_args()
    refresh(args.build.resolve(), args.reference.resolve())


if __name__ == "__main__":
    main()
