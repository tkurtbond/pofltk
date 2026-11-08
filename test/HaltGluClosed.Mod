MODULE HaltGluClosed; (* a closed quadric's methods halt with Fl.ClosedResource, 73 *)
IMPORT FlGlu;
  VAR q: FlGlu.Quadric;
BEGIN
  q := FlGlu.NewQuadric();
  q.Close;
  q.Sphere(1.0D0, 8, 8)
END HaltGluClosed.
