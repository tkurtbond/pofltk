MODULE TestKeys; (* FlText: an editor's key bindings, its own and the global ones *)

IMPORT Fl, FlText, FlTest, Check;

CONST
  CtrlA = 01X; CtrlB = 02X; CtrlK = 0BX; CtrlU = 15X; CtrlN = 0EX; CtrlD = 04X;

VAR
  win: Fl.Window;
  b: FlText.TextBuffer;
  e: FlText.TextEditor;
  proc, pFirst, pSecond, pGlobal, pDefault: FlText.KeyProc;  (* procedure names can't be compared *)
  s: ARRAY 64 OF CHAR;
  first, second, any, global, dflt, adder, lastKey: INTEGER;
  ok: BOOLEAN;

PROCEDURE First(e: FlText.TextEditor; key: INTEGER): BOOLEAN;
BEGIN INC(first); lastKey := key; RETURN TRUE
END First;

PROCEDURE Second(e: FlText.TextEditor; key: INTEGER): BOOLEAN;
BEGIN INC(second); RETURN TRUE
END Second;

PROCEDURE Any(e: FlText.TextEditor; key: INTEGER): BOOLEAN;
BEGIN INC(any); RETURN TRUE
END Any;

PROCEDURE Global(e: FlText.TextEditor; key: INTEGER): BOOLEAN;
BEGIN INC(global); RETURN TRUE
END Global;

PROCEDURE Default(e: FlText.TextEditor; key: INTEGER): BOOLEAN;
BEGIN INC(dflt); lastKey := key; RETURN TRUE
END Default;

(* goes home through FLTK's own function *)
PROCEDURE Home(e: FlText.TextEditor; key: INTEGER): BOOLEAN;
BEGIN RETURN e.Builtin(FlText.KfHome, Fl.KeyHome)
END Home;

(* binds Ctrl+n and removes its own binding, as it runs *)
PROCEDURE Adder(e: FlText.TextEditor; key: INTEGER): BOOLEAN;
BEGIN
  INC(adder);
  e.AddKeyBinding(ORD("n"), Fl.Ctrl, First);
  e.RemoveKeyBinding(ORD("d"), Fl.Ctrl);
  RETURN TRUE
END Adder;

(* a binding that deletes its editor's window *)
PROCEDURE Closer(e: FlText.TextEditor; key: INTEGER): BOOLEAN;
BEGIN win.Delete; RETURN TRUE
END Closer;

PROCEDURE Ctrl(c: CHAR; text: CHAR): BOOLEAN;
  VAR t: ARRAY 2 OF CHAR;
BEGIN t[0] := text; t[1] := 0X; RETURN FlTest.Key(Fl.EvKeyDown, ORD(c), Fl.Ctrl, t)
END Ctrl;

BEGIN
  pFirst := First; pSecond := Second; pGlobal := Global; pDefault := Default;
  NEW(win); Fl.OpenWindow(win, 300, 200, "TestKeys");
  NEW(e); FlText.OpenTextEditor(e, 0, 0, 300, 200, "");
  win.End;
  NEW(b); FlText.OpenBuffer(b); b.SetText("hello"); e.SetBuffer(b);
  ok := e.TakeFocus();

  (* the program's bindings *)
  e.AddKeyBinding(ORD("a"), Fl.Ctrl, First);
  ok := Ctrl("a", CtrlA);
  b.GetText(s);
  Check.Check(ok & (first = 1) & (lastKey = ORD("a")) & (s = "hello"), "a binding of Ctrl+a, over FLTK's select-all");
  e.AddKeyBinding(ORD("a"), Fl.Ctrl, Second);
  ok := Ctrl("a", CtrlA);
  Check.Check((first = 1) & (second = 1), "the newest binding of a key wins");
  Check.Check((e.BoundKey(ORD("a"), Fl.Ctrl, proc) = FlText.KfProgram) & (proc = pSecond), "BoundKey of the program's");
  e.RemoveKeyBinding(ORD("a"), Fl.Ctrl);
  ok := Ctrl("a", CtrlA);
  Check.Check((first = 2) & (second = 1), "removing it uncovers the one before");
  Check.Check((e.BoundKey(ORD("a"), Fl.Ctrl, proc) = FlText.KfProgram) & (proc = pFirst), "BoundKey after the removal");
  ok := FlTest.Key(Fl.EvKeyDown, ORD("a"), Fl.Ctrl + Fl.Shift, CtrlA);
  Check.Check(first = 2, "a Ctrl binding isn't Ctrl+Shift's");
  e.AddKeyBinding(ORD("b"), FlText.AnyState, Any);
  ok := FlTest.Key(Fl.EvKeyDown, ORD("b"), Fl.Ctrl + Fl.Shift, CtrlB);
  Check.Check(any = 1, "AnyState matches any state");

  (* FLTK's own functions *)
  e.BindBuiltin(ORD("k"), Fl.Ctrl, FlText.KfEnd);
  e.SetInsertPosition(0);
  ok := Ctrl("k", CtrlK);
  Check.Check((e.InsertPosition() = 5) & (e.BoundKey(ORD("k"), Fl.Ctrl, proc) = FlText.KfEnd) & (proc = NIL),
    "a key bound to FLTK's KfEnd");
  e.AddKeyBinding(ORD("k"), Fl.Ctrl, Home);
  ok := Ctrl("k", CtrlK);
  Check.Check(e.InsertPosition() = 0, "a binding calling FLTK's KfHome (Builtin)");
  Check.Check(e.BoundKey(Fl.KeyBackSpace, {}, proc) = FlText.KfBackspace, "FLTK's default binding of BackSpace");
  Check.Check(e.BoundKey(ORD("j"), Fl.Ctrl, proc) = FlText.KfNone, "a key bound to nothing");
  e.SetInsertPosition(5);
  ok := FlTest.Key(Fl.EvKeyDown, ORD("x"), {}, "x");
  b.GetText(s);
  Check.Check(s = "hellox", "typed");
  e.BindBuiltin(ORD("u"), Fl.Ctrl, FlText.KfUndo);
  ok := Ctrl("u", CtrlU);
  b.GetText(s);
  Check.Check(s = "hello", "a key bound to FLTK's KfUndo");

  (* the default key function *)
  Check.Check(e.DefaultKeyFunction(proc) = FlText.KfDefault, "the default key function is FLTK's KfDefault");
  e.SetDefaultKeyFunction(Default);
  Check.Check((e.DefaultKeyFunction(proc) = FlText.KfProgram) & (proc = pDefault), "SetDefaultKeyFunction");
  ok := FlTest.Key(Fl.EvKeyDown, Fl.KeyF + 1, {}, "");
  Check.Check((dflt = 1) & (lastKey = 0), "the default key function, for F1, with no text");
  ok := FlTest.Key(Fl.EvKeyDown, ORD("q"), {}, "q");
  b.GetText(s);
  Check.Check((dflt = 1) & (s = "helloq"), "a key that types text is typed, not given the default (147)");
  e.SetDefaultKeyFunction(NIL);
  Check.Check(e.DefaultKeyFunction(proc) = FlText.KfNone, "no default key function");
  e.SetDefaultBuiltin(FlText.KfDefault);
  Check.Check((e.DefaultKeyFunction(proc) = FlText.KfDefault) & (proc = NIL), "SetDefaultBuiltin");

  (* the global bindings, before an editor's own *)
  FlText.AddGlobalKeyBinding(ORD("a"), Fl.Ctrl, Global);
  ok := Ctrl("a", CtrlA);
  Check.Check((global = 1) & (first = 2), "a global binding comes before the editor's");
  Check.Check((FlText.GlobalBoundKey(ORD("a"), Fl.Ctrl, proc) = FlText.KfProgram) & (proc = pGlobal), "GlobalBoundKey");
  FlText.RemoveGlobalKeyBinding(ORD("a"), Fl.Ctrl);
  ok := Ctrl("a", CtrlA);
  Check.Check((global = 1) & (first = 3) & (FlText.GlobalBoundKey(ORD("a"), Fl.Ctrl, proc) = FlText.KfNone),
    "a global binding removed");
  FlText.BindGlobalBuiltin(ORD("k"), Fl.Ctrl, FlText.KfEnd);
  e.SetInsertPosition(0);
  ok := Ctrl("k", CtrlK);
  Check.Check((e.InsertPosition() = 6) & (FlText.GlobalBoundKey(ORD("k"), Fl.Ctrl, proc) = FlText.KfEnd),
    "a global binding to FLTK's own");
  FlText.RemoveAllGlobalKeyBindings;
  Check.Check(FlText.GlobalBoundKey(ORD("k"), Fl.Ctrl, proc) = FlText.KfNone, "RemoveAllGlobalKeyBindings");

  (* Tab *)
  Check.Check(~e.TabNav(), "Tab is typed to start with");
  e.SetTabNav(TRUE);
  Check.Check(e.TabNav() & (e.BoundKey(Fl.KeyTab, {}, proc) = FlText.KfIgnore), "SetTabNav binds Tab to KfIgnore");
  e.SetTabNav(FALSE);
  Check.Check(~e.TabNav(), "SetTabNav(FALSE)");

  (* a binding changing the bindings as it runs *)
  e.AddKeyBinding(ORD("d"), Fl.Ctrl, Adder);
  ok := Ctrl("d", CtrlD); ok := Ctrl("d", CtrlD);
  Check.Check((adder = 1) & (e.BoundKey(ORD("d"), Fl.Ctrl, proc) = FlText.KfNone), "a binding removing itself");
  ok := Ctrl("n", CtrlN);
  Check.Check(first = 4, "a binding another added");

  (* every binding gone, and FLTK's back *)
  e.RemoveAllKeyBindings;
  Check.Check(e.BoundKey(Fl.KeyBackSpace, {}, proc) = FlText.KfNone, "RemoveAllKeyBindings");
  ok := Ctrl("a", CtrlA);
  Check.Check(first = 4, "a removed binding isn't called");
  e.AddDefaultKeyBindings;
  Check.Check(e.BoundKey(Fl.KeyBackSpace, {}, proc) = FlText.KfBackspace, "AddDefaultKeyBindings");

  (* a global binding left at the end, which the C++ part frees, and an
     editor deleted by its own binding *)
  FlText.AddGlobalKeyBinding(ORD("g"), Fl.Ctrl, Global);
  e.AddKeyBinding(ORD("w"), Fl.Ctrl, Closer);
  ok := Ctrl("w", 17X);
  ok := Fl.Check();
  Check.Check(Fl.OpenWidgets() = 0, "an editor deleted by its own binding");
  b.Close;
  Check.Summary
END TestKeys.
