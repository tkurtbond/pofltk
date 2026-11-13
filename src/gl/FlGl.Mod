MODULE FlGl; (* OpenGL through FLTK: GlWindow, FLTK's GL drawing, and the part of GL that FLTK's programs use *)

(* A GlWindow is a window drawn with OpenGL: its Draw, sent to Oberon as
   any widget's, finds the window's context current, and FLTK swaps the
   buffers after it. GL calls outside a Draw need MakeCurrent first. FLTK
   leaves it a closed group: widgets for it need its Begin and End, and
   its Draw calling w.Draw^ to show them over the scene.

   GL itself has hundreds of calls. This binds those of FLTK's programs,
   as FlDraw binds fl_draw.H: enough to draw in the old fixed pipeline, and
   to read the result back. A program using more has a C++ part of its own
   (examples/GlThree.cpp). GL's float crosses as a LONGREAL, so a value
   comes through as the REAL it was.

   This is a library of its own, pofltk-gl, so a program using only
   widgets isn't linked with libfltk_gl and libGL, and FLTK can be built
   without them. A program names both libraries' paths.

   FLTK's text calls need a context, or they crash, so Font, Height,
   Descent, Width, Measure and the DrawText procedures halt with
   Fl.OutOfOrder outside one: outside a Draw, without MakeCurrent or
   Start.

   Start and Finish let a plain window's Draw use GL. They crash under
   Wayland, in FLTK, so see CanStart (doc/fltk-issues.md, 109). A GL
   window has an overlay only where CanDoOverlay says so; elsewhere FLTK
   draws it in the window, with DrawOverlay called after Draw.

   The C++ part is FlGl.cpp. *)

IMPORT SYSTEM, Fl;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* a GlWindow's modes (SetMode), added together *)
  Rgb* = 0;
  Index* = 1;
  Single* = 0;
  Double* = 2;
  Accum* = 4;
  Alpha* = 8;
  Depth* = 16;
  Stencil* = 32;
  Rgb8* = 64;
  Multisample* = 128;
  Stereo* = 256;
  FakeSingle* = 512;
  OpenGL3* = 1024;

  (* what Clear clears, added together *)
  ColorBufferBit* = 16384;
  DepthBufferBit* = 256;
  StencilBufferBit* = 1024;

  (* what Begin draws *)
  Points* = 0;
  Lines* = 1;
  LineLoop* = 2;
  LineStrip* = 3;
  Triangles* = 4;
  TriangleStrip* = 5;
  TriangleFan* = 6;
  Quads* = 7;
  QuadStrip* = 8;
  Polygon* = 9;

  (* what Enable and Disable take *)
  DepthTest* = 2929;
  Blend* = 3042;
  CullFace* = 2884;
  ScissorTest* = 3089;
  Lighting* = 2896;

  (* ShadeModel's modes *)
  Flat* = 7424;
  Smooth* = 7425;

  (* BlendFunc's factors *)
  Zero* = 0;
  One* = 1;
  SrcAlpha* = 770;
  OneMinusSrcAlpha* = 771;

  (* GetError's result when there is none *)
  NoError* = 0;

  (* Enable and Disable's caps for lighting *)
  Light0* = 16384;
  Light1* = 16385;
  Light2* = 16386;
  Light3* = 16387;
  Light4* = 16388;
  Light5* = 16389;
  Light6* = 16390;
  Light7* = 16391;
  Normalize* = 2977;
  ColorMaterial* = 2903;

  (* Light's, LightModel's and Material's parameters *)
  Ambient* = 4608;
  Diffuse* = 4609;
  Specular* = 4610;
  Emission* = 5632;
  Shininess* = 5633;
  AmbientAndDiffuse* = 5634;
  Position* = 4611;
  SpotDirection* = 4612;
  SpotExponent* = 4613;
  SpotCutoff* = 4614;
  ConstantAttenuation* = 4615;
  LinearAttenuation* = 4616;
  QuadraticAttenuation* = 4617;
  LightModelAmbient* = 2899;
  LightModelLocalViewer* = 2897;
  LightModelTwoSide* = 2898;

  (* faces, for Material, SetCullFace and SetColorMaterial *)
  Front* = 1028;
  Back* = 1029;
  FrontAndBack* = 1032;

  (* DepthFunc's tests *)
  Never* = 512;
  Less* = 513;
  Equal* = 514;
  Lequal* = 515;
  Greater* = 516;
  Notequal* = 517;
  Gequal* = 518;
  Always* = 519;

  (* MatrixMode's matrices *)
  Modelview* = 5888;
  Projection* = 5889;
  Texture* = 5890;

  (* what GetFloat and GetInteger give *)
  ModelviewMatrix* = 2982;
  ProjectionMatrix* = 2983;
  ViewportArea* = 2978;
  MatrixModeNow* = 2976;
  RenderModeNow* = 3136;
  NameStackDepth* = 3440;

  (* NewList's modes *)
  Compile* = 4864;
  CompileAndExecute* = 4865;

  (* RenderMode's modes *)
  Render* = 7168;
  Select* = 7170;
  Feedback* = 7169;

  (* what PushAttrib saves, added together *)
  CurrentBit* = 1;
  EnableBit* = 8192;
  LightingBit* = 64;
  PolygonBit* = 8;
  TransformBit* = 4096;
  ViewportBit* = 2048;
  AllAttribBits* = -1;
(* END generated constants *)

TYPE
  GlWindow* = POINTER TO GlWindowDesc;
  GlWindowDesc* = RECORD (Fl.WindowDesc) END;

PROCEDURE ["C", "ofl_gl_window_new"] CNew(placed, x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_gl_mode"] CMode(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_drawing_now"] CDrawing(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_draw_state"] CDrawState(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_draw_begin"] CDrawBegin(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_gl_draw_end"] CDrawEnd(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_gl_draw_window"] CDrawWindow(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_gl_set_mode"] CSetMode(w: SYSTEM.ADDRESS; mode: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_can_do"] CCanDo(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_can_do_mode"] CCanDoMode(mode: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_visual"] CVisual(mode: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_use_high_res"] CUseHighRes(on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_valid"] CValid(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_set_valid"] CSetValid(w: SYSTEM.ADDRESS; v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_context_valid"] CContextValid(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_set_context_valid"] CSetContextValid(w: SYSTEM.ADDRESS; v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_invalidate"] CInvalidate(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_gl_make_current"] CMakeCurrent(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_swap_buffers"] CSwapBuffers(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_gl_swap_interval"] CSwapInterval(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_set_swap_interval"] CSetSwapInterval(w: SYSTEM.ADDRESS; i: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_ortho"] COrtho(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_gl_pixel_w"] CPixelW(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_pixel_h"] CPixelH(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_pixels_per_unit"] CPixelsPerUnit(w: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_gl_can_do_overlay"] CCanDoOverlay(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_redraw_overlay"] CRedrawOverlay(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_gl_hide_overlay"] CHideOverlay(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_gl_make_overlay_current"] CMakeOverlayCurrent(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_can_start"] CCanStart(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_start"] CStart(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_finish"] CFinish(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_ready"] CReady(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_color"] CColor(c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_rect"] CRect(x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_rectf"] CRectf(x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_font"] CFont(font, size: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_height"] CHeight(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_descent"] CDescent(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_width"] CWidth(s: ARRAY OF CHAR): LONGREAL;
PROCEDURE ["C", "ofl_gl_measure"] CMeasure(s: ARRAY OF CHAR; VAR w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_draw"] CDraw(s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_gl_draw_at"] CDrawAt(s: ARRAY OF CHAR; x, y: LONGREAL);
PROCEDURE ["C", "ofl_gl_draw_in"] CDrawIn(s: ARRAY OF CHAR; x, y, w, h, align: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_draw_image"] CDrawImage(data: ARRAY OF CHAR; x, y, w, h, d: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_texture_reset"] CTextureReset;
PROCEDURE ["C", "ofl_gl_texture_pile_height"] CTexturePileHeight(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_set_texture_pile_height"] CSetTexturePileHeight(max: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_begin"] CBegin(mode: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_end"] CEnd;
PROCEDURE ["C", "ofl_gl_clear"] CClear(mask: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_clear_color"] CClearColor(r, g, b, a: LONGREAL);
PROCEDURE ["C", "ofl_gl_color3f"] CColor3f(r, g, b: LONGREAL);
PROCEDURE ["C", "ofl_gl_color4f"] CColor4f(r, g, b, a: LONGREAL);
PROCEDURE ["C", "ofl_gl_color3ub"] CColor3ub(r, g, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_enable"] CEnable(cap: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_disable"] CDisable(cap: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_frustum"] CFrustum(l, r, b, t, n, f: LONGREAL);
PROCEDURE ["C", "ofl_gl_load_identity"] CLoadIdentity;
PROCEDURE ["C", "ofl_gl_gl_ortho"] CGlOrtho(l, r, b, t, n, f: LONGREAL);
PROCEDURE ["C", "ofl_gl_push_matrix"] CPushMatrix;
PROCEDURE ["C", "ofl_gl_pop_matrix"] CPopMatrix;
PROCEDURE ["C", "ofl_gl_rotatef"] CRotatef(a, x, y, z: LONGREAL);
PROCEDURE ["C", "ofl_gl_scalef"] CScalef(x, y, z: LONGREAL);
PROCEDURE ["C", "ofl_gl_shade_model"] CShadeModel(mode: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_translatef"] CTranslatef(x, y, z: LONGREAL);
PROCEDURE ["C", "ofl_gl_vertex3f"] CVertex3f(x, y, z: LONGREAL);
PROCEDURE ["C", "ofl_gl_viewport"] CViewport(x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_blend_func"] CBlendFunc(s, d: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_flush"] CFlush;
PROCEDURE ["C", "ofl_gl_get_error"] CGetError(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_read_pixels"] CReadPixels(x, y, w, h: SYSTEM.INT32; VAR data: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_gl_version"] CVersion(VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_new_list"] CNewList(list, mode: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_end_list"] CEndList;
PROCEDURE ["C", "ofl_gl_call_list"] CCallList(list: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_gen_lists"] CGenLists(n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_delete_lists"] CDeleteLists(list, n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_cull_face"] CCullFace(mode: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_depth_func"] CDepthFunc(func: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_clear_depth"] CClearDepth(d: LONGREAL);
PROCEDURE ["C", "ofl_gl_gl_finish"] CGlFinish;
PROCEDURE ["C", "ofl_gl_color_material"] CColorMaterial(face, mode: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_light"] CLight(light, pname: SYSTEM.INT32; v: SYSTEM.ADDRESS; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_light_model"] CLightModel(pname: SYSTEM.INT32; v: SYSTEM.ADDRESS; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_material"] CMaterial(face, pname: SYSTEM.INT32; v: SYSTEM.ADDRESS; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_matrix_mode"] CMatrixMode(mode: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_mult_matrixf"] CMultMatrixf(m: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_gl_normal3f"] CNormal3f(x, y, z: LONGREAL);
PROCEDURE ["C", "ofl_gl_push_attrib"] CPushAttrib(mask: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_pop_attrib"] CPopAttrib;
PROCEDURE ["C", "ofl_gl_get_float"] CGetFloat(pname: SYSTEM.INT32; v: SYSTEM.ADDRESS; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_get_integer"] CGetInteger(pname: SYSTEM.INT32; v: SYSTEM.ADDRESS; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_render_mode_now"] CRenderModeNow(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_select_buffer"] CSelectBuffer(size: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_select_size"] CSelectSize(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_select_value"] CSelectValue(i: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_render_mode"] CRenderMode(mode: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_init_names"] CInitNames;
PROCEDURE ["C", "ofl_gl_load_name"] CLoadName(name: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_push_name"] CPushName(name: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl_pop_name"] CPopName;

(* The window *)

PROCEDURE OpenGlWindow*(win: GlWindow; w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  Fl.EndOpen(win, CNew(0, 0, 0, w, h, title, Fl.BeginOpen(win)))
END OpenGlWindow;

PROCEDURE OpenGlWindowAt*(win: GlWindow; x, y, w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  Fl.EndOpen(win, CNew(1, x, y, w, h, title, Fl.BeginOpen(win)))
END OpenGlWindowAt;

(* The window's mode: a sum of the mode constants. Rgb + Double + Depth,
   to start with. *)
PROCEDURE (w: GlWindow) Mode*(): INTEGER;
BEGIN RETURN CMode(Fl.Live(w))
END Mode;

(* Whether this display has the mode m; if not, the window keeps its mode.
   A shown window takes a new context, and is drawn again. FLTK forbids
   this in a Draw, where it halts with Fl.OutOfOrder. Under Wayland FLTK adds
   Double to the mode of every window, so Mode gives it back with Double.
   OpenGL3 still gives a compatibility context, on X11 and Wayland alike:
   FLTK makes no core one there (doc/fltk-issues.md, 174). *)
PROCEDURE (w: GlWindow) SetMode*(m: INTEGER): BOOLEAN;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(w);
  ASSERT(CDrawing() = 0, Fl.OutOfOrder);
  RETURN CSetMode(h, m) # 0
END SetMode;

(* Whether this display has the window's mode. *)
PROCEDURE (w: GlWindow) CanDo*(): BOOLEAN;
BEGIN RETURN CCanDo(Fl.Live(w)) # 0
END CanDo;

(* Whether this display has the mode m. *)
PROCEDURE CanDoMode*(mode: INTEGER): BOOLEAN;
BEGIN RETURN CCanDoMode(mode) # 0
END CanDoMode;

(* Makes plain windows opened after this use a visual with the mode, so
   that Start works in them. FALSE, and no change, if there is none. *)
PROCEDURE Visual*(mode: INTEGER): BOOLEAN;
BEGIN RETURN CVisual(mode) # 0
END Visual;

(* On a display of high resolution, whether GL windows use all its
   pixels. Call it before any window is shown. *)
PROCEDURE UseHighRes*(on: BOOLEAN);
BEGIN
  IF on THEN CUseHighRes(1) ELSE CUseHighRes(0) END
END UseHighRes;

(* FALSE when the window is new or has changed size, until Draw returns
   or SetValid: a Draw sets up its viewport and projection then. *)
PROCEDURE (w: GlWindow) Valid*(): BOOLEAN;
BEGIN RETURN CValid(Fl.Live(w)) # 0
END Valid;

PROCEDURE (w: GlWindow) SetValid*(v: BOOLEAN);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(w);
  IF v THEN CSetValid(h, 1) ELSE CSetValid(h, 0) END
END SetValid;

(* FALSE when the context is new, until Draw returns or SetContextValid: a
   Draw loads its textures and display lists then. *)
PROCEDURE (w: GlWindow) ContextValid*(): BOOLEAN;
BEGIN RETURN CContextValid(Fl.Live(w)) # 0
END ContextValid;

PROCEDURE (w: GlWindow) SetContextValid*(v: BOOLEAN);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(w);
  IF v THEN CSetContextValid(h, 1) ELSE CSetContextValid(h, 0) END
END SetContextValid;

(* The next Draw is given a new context. *)
PROCEDURE (w: GlWindow) Invalidate*;
BEGIN CInvalidate(Fl.Live(w))
END Invalidate;

(* Makes the window's context current, for GL calls outside Draw. A window
   not shown has none: that halts with Fl.OutOfOrder. *)
PROCEDURE (w: GlWindow) MakeCurrent*;
BEGIN ASSERT(CMakeCurrent(Fl.Live(w)) # 0, Fl.OutOfOrder)
END MakeCurrent;

PROCEDURE (w: GlWindow) SwapBuffers*;
BEGIN CSwapBuffers(Fl.Live(w))
END SwapBuffers;

(* Frames between swaps, or -1 if it can't be told, as on X11 for a
   window not shown. On Wayland it is one value for every GL window, the
   last set on any, or 1 (doc/fltk-issues.md, 165). *)
PROCEDURE (w: GlWindow) SwapInterval*(): INTEGER;
BEGIN RETURN CSwapInterval(Fl.Live(w))
END SwapInterval;

PROCEDURE (w: GlWindow) SetSwapInterval*(i: INTEGER);
BEGIN CSetSwapInterval(Fl.Live(w), i)
END SetSwapInterval;

(* Sets the projection to the window's pixels, 0, 0 at its lower left. *)
PROCEDURE (w: GlWindow) Ortho*;
BEGIN COrtho(Fl.Live(w))
END Ortho;

(* The window's size in the pixels of glViewport, not FLTK's units. *)
PROCEDURE (w: GlWindow) PixelW*(): INTEGER;
BEGIN RETURN CPixelW(Fl.Live(w))
END PixelW;

PROCEDURE (w: GlWindow) PixelH*(): INTEGER;
BEGIN RETURN CPixelH(Fl.Live(w))
END PixelH;

PROCEDURE (w: GlWindow) PixelsPerUnit*(): REAL;
BEGIN RETURN SHORT(CPixelsPerUnit(Fl.Live(w)))
END PixelsPerUnit;

PROCEDURE (w: GlWindow) CanDoOverlay*(): BOOLEAN;
BEGIN RETURN CCanDoOverlay(Fl.Live(w)) # 0
END CanDoOverlay;

PROCEDURE (w: GlWindow) RedrawOverlay*;
BEGIN CRedrawOverlay(Fl.Live(w))
END RedrawOverlay;

PROCEDURE (w: GlWindow) HideOverlay*;
BEGIN CHideOverlay(Fl.Live(w))
END HideOverlay;

(* As MakeCurrent, for the overlay. *)
PROCEDURE (w: GlWindow) MakeOverlayCurrent*;
BEGIN ASSERT(CMakeOverlayCurrent(Fl.Live(w)) # 0, Fl.OutOfOrder)
END MakeOverlayCurrent;

(* FLTK's drawing in a GL window's Draw, as Fl_Gl_Window's own: from
   DrawBegin to DrawEnd, FlDraw draws over the scene, in the window's
   coordinates (y down), and DrawWindow draws the window's box and its
   widgets. w.Draw^ is the three together. A Draw that returns without
   DrawEnd is ended for it. Each halts with Fl.OutOfOrder outside w's own
   Draw, DrawBegin after DrawBegin, and the others before it. *)
PROCEDURE (w: GlWindow) DrawBegin*;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(w);
  ASSERT(CDrawState(h) = 1, Fl.OutOfOrder);
  CDrawBegin(h)
END DrawBegin;

PROCEDURE (w: GlWindow) DrawWindow*;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(w);
  ASSERT(CDrawState(h) = 2, Fl.OutOfOrder);
  CDrawWindow(h)
END DrawWindow;

PROCEDURE (w: GlWindow) DrawEnd*;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(w);
  ASSERT(CDrawState(h) = 2, Fl.OutOfOrder);
  CDrawEnd(h)
END DrawEnd;

(* GL in a plain window's Draw *)

(* Whether Start works here: not under Wayland (doc/fltk-issues.md, 109). *)
PROCEDURE CanStart*(): BOOLEAN;
BEGIN RETURN CCanStart() # 0
END CanStart;

(* Makes GL draw in the window being drawn, in its pixels, until Finish.
   Under Wayland, it halts with Fl.Unsupported; with no window shown and
   current, or twice, with Fl.OutOfOrder. *)
PROCEDURE Start*;
BEGIN
  ASSERT(CanStart(), Fl.Unsupported);
  ASSERT(CStart() # 0, Fl.OutOfOrder)
END Start;

PROCEDURE Finish*;
BEGIN ASSERT(CFinish() # 0, Fl.OutOfOrder)
END Finish;

(* FLTK's GL drawing *)

(* An Fl color. *)
PROCEDURE Color*(c: INTEGER);
BEGIN CColor(c)
END Color;

PROCEDURE Rect*(x, y, w, h: INTEGER);
BEGIN CRect(x, y, w, h)
END Rect;

PROCEDURE Rectf*(x, y, w, h: INTEGER);
BEGIN CRectf(x, y, w, h)
END Rectf;

PROCEDURE Font*(face, size: INTEGER);
BEGIN ASSERT(CReady() # 0, Fl.OutOfOrder); CFont(face, size)
END Font;

PROCEDURE Height*(): INTEGER;
BEGIN ASSERT(CReady() # 0, Fl.OutOfOrder); RETURN CHeight()
END Height;

PROCEDURE Descent*(): INTEGER;
BEGIN ASSERT(CReady() # 0, Fl.OutOfOrder); RETURN CDescent()
END Descent;

PROCEDURE Width*(s-: ARRAY OF CHAR): REAL;
BEGIN ASSERT(CReady() # 0, Fl.OutOfOrder); RETURN SHORT(CWidth(s))
END Width;

(* The size DrawTextIn would take for s. *)
PROCEDURE Measure*(s-: ARRAY OF CHAR; VAR w, h: INTEGER);
  VAR cw, ch: SYSTEM.INT32;
BEGIN
  ASSERT(CReady() # 0, Fl.OutOfOrder);
  cw := 0; ch := 0; CMeasure(s, cw, ch); w := cw; h := ch
END Measure;

(* s at GL's current raster position. *)
PROCEDURE DrawText*(s-: ARRAY OF CHAR);
BEGIN ASSERT(CReady() # 0, Fl.OutOfOrder); CDraw(s)
END DrawText;

(* s at x, y in the current projection. *)
PROCEDURE DrawTextAt*(s-: ARRAY OF CHAR; x, y: REAL);
BEGIN ASSERT(CReady() # 0, Fl.OutOfOrder); CDrawAt(s, x, y)
END DrawTextAt;

(* s in the box x, y, w, h, placed by a set of Fl's Align constants. *)
PROCEDURE DrawTextIn*(s-: ARRAY OF CHAR; x, y, w, h: INTEGER; align: SET);
BEGIN ASSERT(CReady() # 0, Fl.OutOfOrder); CDrawIn(s, x, y, w, h, ORD(align))
END DrawTextIn;

(* An image of w by h pixels of d bytes each (1 gray, 2 gray and alpha, 3
   RGB, 4 RGBA), rows packed, drawn as GL draws pixels: its first row at
   x, y in the current projection, going up, so with Ortho row after row
   from the bottom (as ReadPixels reads them). Not FLTK's gl_draw_image,
   which reads past the data (doc/fltk-issues.md, 170). *)
PROCEDURE DrawImage*(data-: ARRAY OF CHAR; x, y, w, h, d: INTEGER);
BEGIN
  ASSERT((w >= 0) & (h >= 0) & (d >= 1) & (d <= 4), Fl.IndexOutOfRange);
  ASSERT(w * h * d <= LEN(data), Fl.IndexOutOfRange);
  CDrawImage(data, x, y, w, h, d)
END DrawImage;

(* Frees the textures FLTK keeps for text; for a program whose context
   changed under it. *)
PROCEDURE TextureReset*;
BEGIN CTextureReset
END TextureReset;

(* How many strings' textures FLTK keeps for text, 100 to start with. *)
PROCEDURE TexturePileHeight*(): INTEGER;
BEGIN RETURN CTexturePileHeight()
END TexturePileHeight;

(* Frees the textures kept, and keeps max from now on. FLTK takes 0 and
   crashes at the next text drawn (a division by 0), and a negative max
   (doc/fltk-issues.md, 152): max < 1 halts with Fl.Unsupported. *)
PROCEDURE SetTexturePileHeight*(max: INTEGER);
BEGIN ASSERT(max >= 1, Fl.Unsupported); CSetTexturePileHeight(max)
END SetTexturePileHeight;

(* GL *)

PROCEDURE Begin*(mode: INTEGER);
BEGIN CBegin(mode)
END Begin;

PROCEDURE End*;
BEGIN CEnd
END End;

(* mask is a sum of ColorBufferBit, DepthBufferBit and StencilBufferBit. *)
PROCEDURE Clear*(mask: INTEGER);
BEGIN CClear(mask)
END Clear;

PROCEDURE ClearColor*(r, g, b, a: REAL);
BEGIN CClearColor(r, g, b, a)
END ClearColor;

PROCEDURE Color3f*(r, g, b: REAL);
BEGIN CColor3f(r, g, b)
END Color3f;

PROCEDURE Color4f*(r, g, b, a: REAL);
BEGIN CColor4f(r, g, b, a)
END Color4f;

PROCEDURE Color3ub*(r, g, b: INTEGER);
BEGIN CColor3ub(r, g, b)
END Color3ub;

PROCEDURE Enable*(cap: INTEGER);
BEGIN CEnable(cap)
END Enable;

PROCEDURE Disable*(cap: INTEGER);
BEGIN CDisable(cap)
END Disable;

PROCEDURE Frustum*(left, right, bottom, top, near, far: LONGREAL);
BEGIN CFrustum(left, right, bottom, top, near, far)
END Frustum;

PROCEDURE LoadIdentity*;
BEGIN CLoadIdentity
END LoadIdentity;

(* glOrtho; GlWindow.Ortho is FLTK's, for the window's pixels. *)
PROCEDURE Ortho*(left, right, bottom, top, near, far: LONGREAL);
BEGIN CGlOrtho(left, right, bottom, top, near, far)
END Ortho;

PROCEDURE PushMatrix*;
BEGIN CPushMatrix
END PushMatrix;

PROCEDURE PopMatrix*;
BEGIN CPopMatrix
END PopMatrix;

PROCEDURE Rotatef*(angle, x, y, z: REAL);
BEGIN CRotatef(angle, x, y, z)
END Rotatef;

PROCEDURE Scalef*(x, y, z: REAL);
BEGIN CScalef(x, y, z)
END Scalef;

PROCEDURE ShadeModel*(mode: INTEGER);
BEGIN CShadeModel(mode)
END ShadeModel;

PROCEDURE Translatef*(x, y, z: REAL);
BEGIN CTranslatef(x, y, z)
END Translatef;

PROCEDURE Vertex3f*(x, y, z: REAL);
BEGIN CVertex3f(x, y, z)
END Vertex3f;

PROCEDURE Viewport*(x, y, w, h: INTEGER);
BEGIN CViewport(x, y, w, h)
END Viewport;

PROCEDURE BlendFunc*(source, dest: INTEGER);
BEGIN CBlendFunc(source, dest)
END BlendFunc;

PROCEDURE Flush*;
BEGIN CFlush
END Flush;

(* NoError, or GL's oldest error, which is then cleared. *)
PROCEDURE GetError*(): INTEGER;
BEGIN RETURN CGetError()
END GetError;

(* The w by h pixels with lower left x, y, as three bytes each, red, green,
   blue, row after row from the bottom. *)
PROCEDURE ReadPixels*(x, y, w, h: INTEGER; VAR data: ARRAY OF CHAR);
BEGIN
  ASSERT((w >= 0) & (h >= 0), Fl.IndexOutOfRange);
  ASSERT(w * h * 3 <= LEN(data), Fl.IndexOutOfRange);
  CReadPixels(x, y, w, h, data)
END ReadPixels;

(* The version of the current context, as GL gives it; "" with none. *)
PROCEDURE Version*(VAR s: ARRAY OF CHAR);
BEGIN CVersion(s, SHORT(LEN(s)))
END Version;

(* Display lists. mode is Compile or CompileAndExecute. *)
PROCEDURE NewList*(list, mode: INTEGER);
BEGIN CNewList(list, mode)
END NewList;

PROCEDURE EndList*;
BEGIN CEndList
END EndList;

PROCEDURE CallList*(list: INTEGER);
BEGIN CCallList(list)
END CallList;

(* The first of n new list numbers in a row; 0 if there aren't so many. *)
PROCEDURE GenLists*(n: INTEGER): INTEGER;
BEGIN RETURN CGenLists(n)
END GenLists;

PROCEDURE DeleteLists*(list, n: INTEGER);
BEGIN CDeleteLists(list, n)
END DeleteLists;

(* glCullFace: which faces Enable(CullFace) culls, Front, Back or
   FrontAndBack. *)
PROCEDURE SetCullFace*(mode: INTEGER);
BEGIN CCullFace(mode)
END SetCullFace;

PROCEDURE DepthFunc*(func: INTEGER);
BEGIN CDepthFunc(func)
END DepthFunc;

PROCEDURE ClearDepth*(depth: LONGREAL);
BEGIN CClearDepth(depth)
END ClearDepth;

(* glFinish, which waits for GL to finish what it was given; Finish is
   FLTK's. *)
PROCEDURE GlFinish*;
BEGIN CGlFinish
END GlFinish;

(* glColorMaterial: which of face's material parameters follow the
   colour, with Enable(ColorMaterial). *)
PROCEDURE SetColorMaterial*(face, mode: INTEGER);
BEGIN CColorMaterial(face, mode)
END SetColorMaterial;

(* Light, LightModel and Material set a parameter from up to the first 4
   of v, GL's most, the rest 0. *)
PROCEDURE Light*(light, pname: INTEGER; v-: ARRAY OF REAL);
BEGIN CLight(light, pname, SYSTEM.ADR(v), SHORT(LEN(v)))
END Light;

PROCEDURE LightModel*(pname: INTEGER; v-: ARRAY OF REAL);
BEGIN CLightModel(pname, SYSTEM.ADR(v), SHORT(LEN(v)))
END LightModel;

PROCEDURE Material*(face, pname: INTEGER; v-: ARRAY OF REAL);
BEGIN CMaterial(face, pname, SYSTEM.ADR(v), SHORT(LEN(v)))
END Material;

(* mode is Modelview, Projection or Texture. *)
PROCEDURE MatrixMode*(mode: INTEGER);
BEGIN CMatrixMode(mode)
END MatrixMode;

(* m is 16 values, column after column. *)
PROCEDURE MultMatrixf*(m-: ARRAY OF REAL);
BEGIN
  ASSERT(LEN(m) >= 16, Fl.IndexOutOfRange);
  CMultMatrixf(SYSTEM.ADR(m))
END MultMatrixf;

PROCEDURE Normal3f*(x, y, z: REAL);
BEGIN CNormal3f(x, y, z)
END Normal3f;

(* mask is a sum of the attribute bits, or AllAttribBits. *)
PROCEDURE PushAttrib*(mask: INTEGER);
BEGIN CPushAttrib(mask)
END PushAttrib;

PROCEDURE PopAttrib*;
BEGIN CPopAttrib
END PopAttrib;

(* GetFloat and GetInteger put what GL gives for pname into v, as many
   as fit, and are FALSE for a pname GL doesn't know, and for the lists of
   formats, which can be any length. *)
PROCEDURE GetFloat*(pname: INTEGER; VAR v: ARRAY OF REAL): BOOLEAN;
BEGIN RETURN CGetFloat(pname, SYSTEM.ADR(v), SHORT(LEN(v))) # 0
END GetFloat;

PROCEDURE GetInteger*(pname: INTEGER; VAR v: ARRAY OF INTEGER): BOOLEAN;
BEGIN RETURN CGetInteger(pname, SYSTEM.ADR(v), SHORT(LEN(v))) # 0
END GetInteger;

(* Selection. GL keeps the buffer it was given, so SelectBuffer makes a
   new one of size names each time, kept till the program ends, and
   SelectValue reads the last made. It halts with Fl.OutOfOrder in Select
   mode, where GL can't change the buffer. *)
PROCEDURE SelectBuffer*(size: INTEGER);
BEGIN
  ASSERT(size > 0, Fl.IndexOutOfRange);
  ASSERT(CRenderModeNow() # Select, Fl.OutOfOrder);
  CSelectBuffer(size)
END SelectBuffer;

(* The last selection buffer's size; 0 before the first. *)
PROCEDURE SelectSize*(): INTEGER;
BEGIN RETURN CSelectSize()
END SelectSize;

(* The selection buffer's ith value, unsigned in GL, as an INTEGER. *)
PROCEDURE SelectValue*(i: INTEGER): INTEGER;
BEGIN
  ASSERT((i >= 0) & (i < CSelectSize()), Fl.IndexOutOfRange);
  RETURN CSelectValue(i)
END SelectValue;

(* glRenderMode: mode is Render, Select or Feedback. Leaving Select gives
   the number of hit records in the buffer, -1 if it overflowed. *)
PROCEDURE RenderMode*(mode: INTEGER): INTEGER;
BEGIN RETURN CRenderMode(mode)
END RenderMode;

PROCEDURE InitNames*;
BEGIN CInitNames
END InitNames;

PROCEDURE LoadName*(name: INTEGER);
BEGIN CLoadName(name)
END LoadName;

PROCEDURE PushName*(name: INTEGER);
BEGIN CPushName(name)
END PushName;

PROCEDURE PopName*;
BEGIN CPopName
END PopName;

END FlGl.
