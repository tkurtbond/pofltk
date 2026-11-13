(* PLACEHOLDER, not built. A probe run against Peaseblossom's coroutine
   prototype on 2026-11-13 (Peaseblossom's concurrency-survey.md, section
   8.7.1), kept as run until it is rewritten against poc's real Coroutines
   module (Peaseblossom's doc/developer/coroutines.md); README.md says
   what the rewrite changes. *)
MODULE FlScript; (* pattern (a), a script coroutine resumed by
  a button's callback, with a nested Fl.Wait on the script's stack *)
  IMPORT SYSTEM, Fl, FlButtons, Coroutines, GarbageCollectedHeap, Probe, Out;
  CONST steps = 40; listLength = 20000;
  TYPE Node = POINTER TO RECORD next: Node; value: LONGINT; pad: ARRAY 6 OF LONGINT END;
  VAR
    window: Fl.Window; box: Fl.Box; next: FlButtons.Button;
    clicker, churner: Fl.Timer;
    main, script: Coroutines.Coroutine;
    inScript, done: BOOLEAN; refused, clicks, churns, nestedTimerOnScript: LONGINT;
    mainList: Node;

  PROCEDURE Build(n, seed: LONGINT): Node;
    VAR list, x: Node; k: LONGINT;
  BEGIN list := NIL;
    FOR k := 1 TO n DO NEW(x); x.value := seed + k; x.next := list; list := x END;
    RETURN list
  END Build;

  PROCEDURE Bad(list: Node; n, seed: LONGINT): LONGINT;
    VAR k, bad: LONGINT;
  BEGIN bad := 0; k := n;
    WHILE list # NIL DO IF list.value # seed + k THEN INC(bad) END; DEC(k); list := list.next END;
    RETURN bad + ABS(k)
  END Bad;

  PROCEDURE Script;
    VAR k, j: LONGINT; mine: Node; label: ARRAY 32 OF CHAR;
  BEGIN
    mine := Build(listLength, 500000);
    FOR k := 1 TO steps DO
      label := "step  "; label[5] := CHR(ORD("0") + k MOD 10); box.SetLabel(label);
      IF ODD(k) THEN (* a nested event loop on this stack *)
        FOR j := 1 TO 5 DO Fl.Wait(0.002D0) END
      END;
      inScript := FALSE; Coroutines.Transfer(script, main); inScript := TRUE
    END;
    Out.String("script's list: "); Out.Int(Bad(mine, listLength, 500000), 0); Out.String(" bad"); Out.Ln;
    done := TRUE; window.Hide;
    LOOP inScript := FALSE; Coroutines.Transfer(script, main) END
  END Script;

  PROCEDURE Next(w: Fl.Widget);
  BEGIN
    IF inScript THEN INC(refused) (* a click during the script's own Wait *)
    ELSIF ~done THEN INC(clicks); inScript := TRUE; Coroutines.Transfer(main, script)
    END
  END Next;

  PROCEDURE Click(t: Fl.Timer);
  BEGIN next.DoCallback; IF ~done THEN Fl.RepeatTimeout(t, 0.003D0) END
  END Click;

  PROCEDURE Churn(t: Fl.Timer);
    VAR k: LONGINT; x: Node;
  BEGIN
    IF inScript THEN INC(nestedTimerOnScript) END;
    INC(churns); FOR k := 1 TO 100000 DO NEW(x) END;
    IF ~done THEN Fl.RepeatTimeout(t, 0.001D0) END
  END Churn;

  PROCEDURE Report;
    VAR low, high: SYSTEM.ADDRESS;
  BEGIN
    Coroutines.Range(script, low, high);
    Out.String("main's list: "); Out.Int(Bad(mainList, listLength, 0), 0); Out.String(" bad"); Out.Ln;
    Out.String("clicks "); Out.Int(clicks, 0); Out.String(", refused during the script's Wait ");
    Out.Int(refused, 0); Out.String(", churns "); Out.Int(churns, 0);
    Out.String(" (on the script's stack "); Out.Int(nestedTimerOnScript, 0); Out.String(")"); Out.Ln;
    Out.String("collections "); Out.Int(GarbageCollectedHeap.CollectionCount(), 0); Out.Ln;
    Out.String("script's stack touched: "); Out.Int(Probe.Touched(low, high) DIV 1024, 0);
    Out.String(" KiB of "); Out.Int((high - low) DIV 1024, 0); Out.Ln
  END Report;

BEGIN
  Coroutines.mode := 2;
  mainList := Build(listLength, 0);
  Coroutines.Init(Script, 256 * 1024, script);
  NEW(window); Fl.OpenWindow(window, 300, 80, "FlScript");
  NEW(box); Fl.OpenBox(box, 10, 10, 180, 25, "start");
  NEW(next); FlButtons.OpenButton(next, 200, 10, 80, 25, "Next"); next.action := Next;
  window.End; window.Show;
  NEW(clicker); clicker.action := Click; Fl.AddTimeout(clicker, 0.05D0);
  NEW(churner); churner.action := Churn; Fl.AddTimeout(churner, 0.05D0);
  Fl.Run;
  Report
END FlScript.
