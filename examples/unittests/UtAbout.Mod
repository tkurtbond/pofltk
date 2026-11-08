MODULE UtAbout; (* FLTK's test/unittest_about.cxx in Oberon-2 *)

IMPORT FlHelp, Ut;

CONST Label* = "About...";

PROCEDURE Create*(): FlHelp.HelpView;
  VAR v: FlHelp.HelpView; text: ARRAY 2048 OF CHAR;
BEGIN
  NEW(v); FlHelp.OpenHelpView(v, Ut.X, Ut.Y, Ut.W, Ut.H, "");
  text := "<htmL><body><h2>About Unit Testing...</h2>|The Unit Testing application can be used to verify correct graphics rendering on the current platform. The core developer team uses this program to make sure that the FLTK user experience is identical on all supported graphics systems.<h3>The UI Designer</h3>|<p>Designing a good user interface is an art. Widgets must be selected and carefully positioned to create a consistent look and feel for the user. Text must fit into given boxes and graphic elements must be correctly aligned. A good UI library will give consistent results on any supported platform and render all graphics in the way the UI designer intended.</p>|<p>FLTK supports a large collection of platforms and graphics drivers. This unit testing application contains modules which will test rendering and alignment for most FLTK core graphics functions.</p>|<h3>The Developer</h3>|<p>Unittest is also a great help when implementing new graphics drivers. The tests are sorted in the same order in which a new graphics driver could be implemented. Most tests rely on the previous test to function correctly, so sticking to the given order is a good idea.</p>|<h3>Conventions</h3>|<p>Two layers of graphics are drawn for most tests. The lower layer contains red and green pixels. The upper layer contains black pixels. The test is rendered correctly if all red pixels are covered, but none of the green pixels. The top graphics layer can be switched on and off.</p></body></html>";
  Ut.Lines(text); v.SetValue(text);
  RETURN v
END Create;

END UtAbout.
