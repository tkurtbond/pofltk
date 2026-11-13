# Pending examples

Examples that wait on something outside pofltk, typically a poc runtime
module that does not exist yet. Nothing here is built by `make` or run by
`make test`. When its dependency arrives, an example is rewritten, moved to
`examples/` and added to `EXAMPLES` in `GNUmakefile`.

## FlScript.Mod

**Waits for** poc's `Coroutines` module (Oakwood's interface; Peaseblossom's
`doc/developer/coroutines.md`, Phase 3).

**What it shows.** Pattern (a) from Peaseblossom's concurrency survey,
section 8.4: a script, written as straight-line code, runs on a coroutine
of its own. A button's callback resumes it, and it transfers back to `main`
after each step. On odd steps the script also runs a nested `Fl.Wait` on
its own stack.

**As run on 2026-11-13** (survey section 8.7.1), against the prototype, on
atla under `Xvfb`:
- A repeating timer clicked the button, and another allocated 100,000 nodes
  each time it fired, to force collections.
- A list held only by `main`'s stack and one held only by the script's were
  intact after 292 collections.
- The script's stack touched 32 KiB of its 256.

**What the rewrite changes:**
- **Prototype-only names.** It uses three things the real interface will
  not have:
  - `Coroutines.mode := 2`, the prototype's switch for scanning every
    stack. The real module always does.
  - `Coroutines.Range`, the bounds of a coroutine's stack.
  - `Probe.Touched`, a `mincore` count of its resident pages.

  The stack measurement goes, and with it `Report`'s last line.
- **The timers.** The click and churn timers were there to drive the probe
  under `Xvfb`. An example should wait for real clicks, and may keep the
  list checks as a self-test.
- **The guard.** `Next` refuses to resume the script while it is already
  running, inside its own nested `Wait`. In the probe no click ever came
  then, because FLTK re-arms a timer only after its callback returns. By
  hand it can, so the guard stays.
- **The nested `Wait` is pattern (b).** It uses FLTK while `main` is
  suspended inside FLTK's dispatch of the click. The survey's rule (8.4)
  forbids that for C libraries in general, and only timers were shown to
  survive it. Either drop the nested `Wait`, or keep it with a comment that
  it is the exception the survey tested.
