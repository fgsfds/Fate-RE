# Restoration workflow comparison — 2026-11-24

The four-role workflow did not demonstrate a benefit for short mechanical
assignments. Keep those operations with the integrator and retain independent
research and review. This changes orchestration, not restoration acceptance.
The broader restoration goal remains paused; no additional production functions
or native bytes are claimed for this comparison.

## Compared workflows

| Workflow | Roles | What the evidence supports |
| --- | --- | --- |
| Earlier configuration at `a86064a` | Seven: scout, probe, verifier, writer, CI monitor, research, review | Overlapping assignments; no controlled timing or token comparison was recorded |
| Current baseline at `bb51f08` | Four: probe, CI monitor, research, review | Previous two-function trial passed, but probe and CI needed correction; parent finished CI observation |
| Revised workflow | Two: research and review | Integrator executes ready probes and observes CI directly; children supply independent judgment or useful overlap |

Research remains available for an unresolved compiler question; this test does
not establish its speed or value on new research. Retiring a role does not mean
its model is incapable of every task.

## Controlled short-probe comparison

Both paths executed the same script and frozen production/tool inputs, using
the same pinned Watcom flags and reference, isolated scratch, and an exclusive
windowless DOSBox lease. Each forced fresh `gamrow` and `statpent` compilation,
with zero cache hits, then checked the same selected CODE spans and LE bindings.
Input snapshots, script hash and exact span results matched. They requalified
preserved candidates; this is not a fresh function-rewrite benchmark.

| Observation | Integrator direct | Dedicated probe child |
| --- | ---: | ---: |
| Fresh compiler time | 2.47 s | 2.42 s |
| Script time from saved report | 4.32 s | 4.32 s |
| Dispatch to observed completion | 5.04 s | 116.35 s |
| First response | Complete | Incomplete at 47.65 s |
| Parent intervention | None | One diagnostic request and one corrective retry |
| Final exact output files | 3/3 | 3/3 after repair |

The child constructed an absolute path without the `Fate-RE` component and
reported the script missing. The packet's cwd/path was correct; parent diagnosis
identified the omitted component and supplied the ready command again.
End-to-end time includes parent observation latency, diagnosis and correction;
it is not the worker's isolated model execution time. This is one paired trial,
not a statistically established speed ratio. Execution itself was essentially
identical; the observed difference was orchestration and recovery.

After routing ready probes directly, a fresh retest completed in **5.32 s**
including the tool call, **4.51 s** inside the script and **2.56 s** compiling,
with 2 compiled objects, zero cache hits, all outputs and no correction. Test
configuration changed between this retest and the pair; production C and compiler
flags did not. There was no useful independent work requiring a mechanical child.

## Independent review retest

A fresh reviewer received two scratch alternatives and a domain/ABI contract,
without expected labels or the seeded fault. It blocked candidate A for signed
left-shift and addition overflow after callbacks change `panel_top`, and accepted
candidate B's unsigned arithmetic for source review. Final exact gates remained
the integrator's responsibility.

The only seeded change was this expression:

```c
/* B */ ((long)(((unsigned long)panel_top + (extra)) << 16))
/* A */ ((long)((panel_top + (extra)) << 16))
```

The invalid alternative was also compiled in isolated scratch. All six selected
entry phases and their full private-context byte/fixup guards still matched the
valid object. This is a concrete reason to retain independent C-validity review:
byte identity alone did not detect the seeded language-level defect. The invalid
scratch object is not production input or coverage eligible. It was never linked
into an accepted executable. This demonstrates one review capability, not a bug
found in production or a measured overall defect reduction.

The reviewer correctly assigned a ready probe/JSON extraction to the integrator,
an unresolved EBP allocation hypothesis to research, and exact-SHA CI observation
to the integrator. It found a missing link to this report; the report now exists.

## Validation and limits

The three skills pass the official validator. The two retained TOMLs and documented
routes pass the profile tests; all 12 local routing/skill links exist. Full current-input
validation passed **406 tests and 144 fixtures**. The 741,347-byte executable matches
SHA-256 `61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
Final CI is tracked separately for the exact published SHA by the integrator.
Acceptance retains current provenance, byte/LE checks, full context guards,
appropriate regression fixtures and honest attribution.

Per-agent token counters are not exposed. Profile count, instruction word count,
model price and cumulative goal usage do not establish token or cost savings.
This evidence supports removing unnecessary coordination for short probes and
retaining review for a distinct correctness check. It does not establish a general
rewrite-speed improvement or the long-run performance of either retained role.

Raw local evidence (ignored, not required to understand this report):

- `work/workflow-comparison/run_probe.py` and `results.json`.
- `work/workflow-direct-a/experiment.json` and `work/workflow-delegated-a/experiment.json`.
- `work/workflow-direct-b/experiment.json`.
- `work/workflow-comparison/review/contract.md`, `candidate-a.c`, `candidate-b.c`.
- `work/workflow-ub-probe/negative-control.json`.
