MODULE TestGlConstants; (* pofltk's constants are FLTK's *)

(* Written by tools/gen-constants.py: one check per constant, against the
   value the installed FLTK's headers give (CGlConstants). A failure means
   FLTK's headers changed: run the script again, and see what moved. *)

IMPORT SYSTEM, Out, FlGl, Check, CGlConstants;

VAR checked, wrong: INTEGER;

PROCEDURE Same(oberon: INTEGER; c-: ARRAY OF CHAR);
  VAR v: INTEGER;
BEGIN
  INC(checked);
  IF ~CGlConstants.Value(c, v) OR (v # oberon) THEN
    INC(wrong); Out.String("  differs from C: "); Out.String(c); Out.Ln
  END
END Same;

BEGIN
  checked := 0; wrong := 0;
  Same(FlGl.Rgb, "FL_RGB");
  Same(FlGl.Index, "FL_INDEX");
  Same(FlGl.Single, "FL_SINGLE");
  Same(FlGl.Double, "FL_DOUBLE");
  Same(FlGl.Accum, "FL_ACCUM");
  Same(FlGl.Alpha, "FL_ALPHA");
  Same(FlGl.Depth, "FL_DEPTH");
  Same(FlGl.Stencil, "FL_STENCIL");
  Same(FlGl.Rgb8, "FL_RGB8");
  Same(FlGl.Multisample, "FL_MULTISAMPLE");
  Same(FlGl.Stereo, "FL_STEREO");
  Same(FlGl.FakeSingle, "FL_FAKE_SINGLE");
  Same(FlGl.OpenGL3, "FL_OPENGL3");
  Same(FlGl.ColorBufferBit, "GL_COLOR_BUFFER_BIT");
  Same(FlGl.DepthBufferBit, "GL_DEPTH_BUFFER_BIT");
  Same(FlGl.StencilBufferBit, "GL_STENCIL_BUFFER_BIT");
  Same(FlGl.Points, "GL_POINTS");
  Same(FlGl.Lines, "GL_LINES");
  Same(FlGl.LineLoop, "GL_LINE_LOOP");
  Same(FlGl.LineStrip, "GL_LINE_STRIP");
  Same(FlGl.Triangles, "GL_TRIANGLES");
  Same(FlGl.TriangleStrip, "GL_TRIANGLE_STRIP");
  Same(FlGl.TriangleFan, "GL_TRIANGLE_FAN");
  Same(FlGl.Quads, "GL_QUADS");
  Same(FlGl.QuadStrip, "GL_QUAD_STRIP");
  Same(FlGl.Polygon, "GL_POLYGON");
  Same(FlGl.DepthTest, "GL_DEPTH_TEST");
  Same(FlGl.Blend, "GL_BLEND");
  Same(FlGl.CullFace, "GL_CULL_FACE");
  Same(FlGl.ScissorTest, "GL_SCISSOR_TEST");
  Same(FlGl.Lighting, "GL_LIGHTING");
  Same(FlGl.Flat, "GL_FLAT");
  Same(FlGl.Smooth, "GL_SMOOTH");
  Same(FlGl.Zero, "GL_ZERO");
  Same(FlGl.One, "GL_ONE");
  Same(FlGl.SrcAlpha, "GL_SRC_ALPHA");
  Same(FlGl.OneMinusSrcAlpha, "GL_ONE_MINUS_SRC_ALPHA");
  Same(FlGl.NoError, "GL_NO_ERROR");
  Check.Check((wrong = 0) & (checked = 38), "each of 38 constants and values is FLTK's");
  Check.Summary
END TestGlConstants.
