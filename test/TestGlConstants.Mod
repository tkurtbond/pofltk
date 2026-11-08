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
  Same(FlGl.Light0, "GL_LIGHT0");
  Same(FlGl.Light1, "GL_LIGHT1");
  Same(FlGl.Light2, "GL_LIGHT2");
  Same(FlGl.Light3, "GL_LIGHT3");
  Same(FlGl.Light4, "GL_LIGHT4");
  Same(FlGl.Light5, "GL_LIGHT5");
  Same(FlGl.Light6, "GL_LIGHT6");
  Same(FlGl.Light7, "GL_LIGHT7");
  Same(FlGl.Normalize, "GL_NORMALIZE");
  Same(FlGl.ColorMaterial, "GL_COLOR_MATERIAL");
  Same(FlGl.Ambient, "GL_AMBIENT");
  Same(FlGl.Diffuse, "GL_DIFFUSE");
  Same(FlGl.Specular, "GL_SPECULAR");
  Same(FlGl.Emission, "GL_EMISSION");
  Same(FlGl.Shininess, "GL_SHININESS");
  Same(FlGl.AmbientAndDiffuse, "GL_AMBIENT_AND_DIFFUSE");
  Same(FlGl.Position, "GL_POSITION");
  Same(FlGl.SpotDirection, "GL_SPOT_DIRECTION");
  Same(FlGl.SpotExponent, "GL_SPOT_EXPONENT");
  Same(FlGl.SpotCutoff, "GL_SPOT_CUTOFF");
  Same(FlGl.ConstantAttenuation, "GL_CONSTANT_ATTENUATION");
  Same(FlGl.LinearAttenuation, "GL_LINEAR_ATTENUATION");
  Same(FlGl.QuadraticAttenuation, "GL_QUADRATIC_ATTENUATION");
  Same(FlGl.LightModelAmbient, "GL_LIGHT_MODEL_AMBIENT");
  Same(FlGl.LightModelLocalViewer, "GL_LIGHT_MODEL_LOCAL_VIEWER");
  Same(FlGl.LightModelTwoSide, "GL_LIGHT_MODEL_TWO_SIDE");
  Same(FlGl.Front, "GL_FRONT");
  Same(FlGl.Back, "GL_BACK");
  Same(FlGl.FrontAndBack, "GL_FRONT_AND_BACK");
  Same(FlGl.Never, "GL_NEVER");
  Same(FlGl.Less, "GL_LESS");
  Same(FlGl.Equal, "GL_EQUAL");
  Same(FlGl.Lequal, "GL_LEQUAL");
  Same(FlGl.Greater, "GL_GREATER");
  Same(FlGl.Notequal, "GL_NOTEQUAL");
  Same(FlGl.Gequal, "GL_GEQUAL");
  Same(FlGl.Always, "GL_ALWAYS");
  Same(FlGl.Modelview, "GL_MODELVIEW");
  Same(FlGl.Projection, "GL_PROJECTION");
  Same(FlGl.Texture, "GL_TEXTURE");
  Same(FlGl.ModelviewMatrix, "GL_MODELVIEW_MATRIX");
  Same(FlGl.ProjectionMatrix, "GL_PROJECTION_MATRIX");
  Same(FlGl.ViewportArea, "GL_VIEWPORT");
  Same(FlGl.MatrixModeNow, "GL_MATRIX_MODE");
  Same(FlGl.RenderModeNow, "GL_RENDER_MODE");
  Same(FlGl.NameStackDepth, "GL_NAME_STACK_DEPTH");
  Same(FlGl.Compile, "GL_COMPILE");
  Same(FlGl.CompileAndExecute, "GL_COMPILE_AND_EXECUTE");
  Same(FlGl.Render, "GL_RENDER");
  Same(FlGl.Select, "GL_SELECT");
  Same(FlGl.Feedback, "GL_FEEDBACK");
  Same(FlGl.CurrentBit, "GL_CURRENT_BIT");
  Same(FlGl.EnableBit, "GL_ENABLE_BIT");
  Same(FlGl.LightingBit, "GL_LIGHTING_BIT");
  Same(FlGl.PolygonBit, "GL_POLYGON_BIT");
  Same(FlGl.TransformBit, "GL_TRANSFORM_BIT");
  Same(FlGl.ViewportBit, "GL_VIEWPORT_BIT");
  Same(FlGl.AllAttribBits, "GL_ALL_ATTRIB_BITS");
  Check.Check((wrong = 0) & (checked = 96), "each of 96 constants and values is FLTK's");
  Check.Summary
END TestGlConstants.
