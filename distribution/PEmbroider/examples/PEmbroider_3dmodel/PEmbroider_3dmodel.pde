PShape model;
import processing.embroider.*;
PEmbroiderGraphics E;

String[] modelPaths = {
  "cube.obj", 
  "spot.obj", 
  "teapot.obj", 
  "bunny.obj", 
};
float[] modelScalings = {
  0.5, 
  1.0, 
  1.2, 
  1.0, 
};
int modelIndex = 0;

float rotx = 0.4;
float roty = 0;
float dz = 5.0;
float focal = 1800;

// normalize model to [-scl,-scl,-scl] and [+scl,+scl,+scl]
void normalize(PShape model, float scl) {

  // calculate bounding box
  float xmin = Float.MAX_VALUE;
  float xmax = -Float.MAX_VALUE;
  float ymin = Float.MAX_VALUE;
  float ymax = -Float.MAX_VALUE;
  float zmin = Float.MAX_VALUE;
  float zmax = -Float.MAX_VALUE;
  for (int i = 0; i < model.getChildCount(); i++) {
    PShape tri = model.getChild(i);
    for (int j = 0; j < tri.getVertexCount(); j++) {
      PVector v = tri.getVertex(j);
      xmin = min(xmin, v.x);
      xmax = max(xmax, v.x);
      ymin = min(ymin, v.y);
      ymax = max(ymax, v.y);
      zmin = min(zmin, v.z);
      zmax = max(zmax, v.z);
    }
  }

  // normalize, keeping axis ratio
  float s = max(max(xmax-xmin, ymax-ymin), zmax-zmin);
  float px = (s - (xmax-xmin)) / 2;
  float py = (s - (ymax-ymin)) / 2;
  float pz = (s - (zmax-zmin)) / 2;

  for (int i = 0; i < model.getChildCount(); i++) {
    PShape tri = model.getChild(i);
    for (int j = 0; j < tri.getVertexCount(); j++) {
      PVector v = tri.getVertex(j);
      tri.setVertex(j, new PVector(
        ((v.x-xmin+px)*2/s-1)*scl, 
        ((v.y-ymin+py)*2/s-1)*scl, 
        ((v.z-zmin+pz)*2/s-1)*scl
        ));
    }
  }
}

// project 3D point onto 2D surface using pinhole camera model
PVector project(PVector p, float rotx, float roty, float dz, float focal) {
  PMatrix3D modelMatrix = new PMatrix3D();
  modelMatrix.translate(0, 0, dz);
  modelMatrix.rotateX(rotx);
  modelMatrix.rotateY(roty);
  modelMatrix.scale(-1);
  PVector q = modelMatrix.mult(p.copy(), null); 
  return new PVector(width/2+focal*q.x/q.z, height/2+focal*q.y/q.z);
}

void setup() {
  size(1000, 1000, P3D);
  model = loadShape(modelPaths[modelIndex]);
  normalize(model, modelScalings[modelIndex]);
  E = new PEmbroiderGraphics(this);
}


void draw() {
  E.clear();
  background(255);

  roty += 0.1;

  // read triangles and use PEmbroider to draw them
  for (int i = 0; i < model.getChildCount(); i++) {
    PShape tri = model.getChild(i);
    PVector a = tri.getVertex(0);
    PVector b = tri.getVertex(1);
    PVector c = tri.getVertex(2);

    PVector A = project(a, rotx, roty, dz, focal);
    PVector B = project(b, rotx, roty, dz, focal);
    PVector C = project(c, rotx, roty, dz, focal);

    E.triangle(
      A.x, A.y, 
      B.x, B.y, 
      C.x, C.y
      );
  }

  E.visualize(true, true, true);
  text("press a key to switch model\nclick to save", 10, 10);
}

void mousePressed() {
  E.setPath(sketchPath("PEmbroider_3dmodel.vp3"));
  E.optimize(3, 300);
  E.endDraw();
}

void keyPressed() {
  modelIndex = (modelIndex + 1) % modelPaths.length;
  model = loadShape(modelPaths[modelIndex]);
  normalize(model, modelScalings[modelIndex]);
}
