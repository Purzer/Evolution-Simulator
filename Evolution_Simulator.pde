Board evoBoard;

final int seed = 1101010;
final float noiseStepSize = 0.1;
final int boardWidth = 100;
final int boardHeight = 100;

final int windowWidth = 1366;
final int windowHeight = 786;
final float scale = 50;
final float overallScaleFactor =  ((float)windowHeight)/boardHeight/scale;

final double timeStep = 0.001;
final float minTemp = -0.5;
final float maxTemp = 1.0;

final int numberOfRocks = 0;
final int creatureMin = 100;
final int creatureMax = 1000;

boolean showAxons = false;
float cameraX = boardWidth*0.5;
float cameraY = boardHeight*0.5;
float cameraR = 0;
float zoom = 1;
PFont font;
int dragging = 0;
float prevMouseX;
float prevMouseY;
boolean draggedFar = false;
final String fileName = "Pics";

void setup() {
  colorMode(HSB,1.0);
  font = loadFont("Font.vlw");
  size(1366,786); //windowWidth, windowHeight
  evoBoard = new Board(boardWidth, boardHeight, noiseStepSize, minTemp, maxTemp, 
  numberOfRocks, creatureMin, creatureMax, seed, fileName, timeStep);
  resetZoom();
}
void draw() {
  for (int iteration = 0; iteration < evoBoard.playSpeed; iteration++) {
    evoBoard.iterate(timeStep);
  }
  if (dist(prevMouseX, prevMouseY, mouseX, mouseY) > 5) {
    draggedFar = true;
  }
  if (dragging == 1) {
    cameraX -= toWorldXCoordinate(mouseX, mouseY)-toWorldXCoordinate(prevMouseX, prevMouseY);
    cameraY -= toWorldYCoordinate(mouseX, mouseY)-toWorldYCoordinate(prevMouseX, prevMouseY);
  } 
  else if (dragging == 2) {
    if (evoBoard.setMinTemp(1.0-(mouseY-30)/530.0)) {
      dragging = 3;
    }
  } 
  else if (dragging == 3) {
    if (evoBoard.setMaxTemp(1.0-(mouseY-30)/530.0)) {
      dragging = 2;
    }
  }
  if (evoBoard.selectedCreature != null) {
    cameraX = (float)evoBoard.selectedCreature.px;
    cameraY = (float)evoBoard.selectedCreature.py;
    cameraR = -PI/2.0-(float)evoBoard.selectedCreature.rotation;
  }
  else{
    cameraR = 0;
  }
  pushMatrix();
  scale(overallScaleFactor);
  evoBoard.drawBlankBoard(scale);
  translate(boardWidth*0.5*scale, boardHeight*0.5*scale);
  scale(zoom);
  if (evoBoard.selectedCreature != null) {
    rotate(cameraR);
  }
  translate(-cameraX*scale, -cameraY*scale);
  evoBoard.drawBoard(scale, zoom, (int)toWorldXCoordinate(mouseX, mouseY), (int)toWorldYCoordinate(mouseX, mouseY));
  popMatrix();
  evoBoard.drawUI(scale, timeStep, windowHeight, 0, windowWidth, windowHeight, font);

  evoBoard.fileSave();
  prevMouseX = mouseX;
  prevMouseY = mouseY;
}
void mouseWheel(MouseEvent event) {
  float delta = event.getCount();
  if (delta >= 0.5) {
    setZoom(zoom*0.90909, mouseX, mouseY);
  }
  else if (delta <= -0.5) {
    setZoom(zoom*1.1, mouseX, mouseY);
  }
}
void mousePressed() {
  if (mouseX < windowHeight) {
    dragging = 1;
  } 
  else {
    if (abs(mouseX-(windowHeight+65)) <= 60 && abs(mouseY-147) <= 60 && evoBoard.selectedCreature != null) {
        cameraX = (float)evoBoard.selectedCreature.px;
        cameraY = (float)evoBoard.selectedCreature.py;
        zoom = 16;
    }
    else if (mouseY >= 95 && mouseY < 135 && evoBoard.selectedCreature == null) {
      if (mouseX >= windowHeight+10 && mouseX < windowHeight+230) {
        resetZoom();
      } 
      else if (mouseX >= windowHeight+240 && mouseX < windowHeight+460) {
        evoBoard.creatureRankMetric = (evoBoard.creatureRankMetric+1)%8;
      }
    }
    else if (mouseY >= 370 && evoBoard.selectedCreature == null) {
      float x = (mouseX-(windowHeight+10));
      float y = (mouseY-370);
      boolean clickedOnLeft = (x%230 < 110);
      if (x >= 0 && x < 2*230 && y >= 0 && y < 4*50 && x%230 < 220 && y%50 < 40) {
        int mX = (int)(x/230);
        int mY = (int)(y/50);
        int buttonNum = mX+mY*2;
        //if (buttonNum == 0) {
        //  evoBoard.userControl = !evoBoard.userControl;
        //}
        if (buttonNum == 1) {
          if (clickedOnLeft) {
            evoBoard.creatureMinimum -= evoBoard.creatureMinimumIncrement;
          } 
          else {
            evoBoard.creatureMinimum += evoBoard.creatureMinimumIncrement;
          }
        }
        else if (buttonNum == 2) {
          evoBoard.prepareForFileSave(0);
        }
        else if (buttonNum == 3) {
          if (clickedOnLeft) {
            evoBoard.imageSaveInterval *= 0.5;
          }
          else {
            evoBoard.imageSaveInterval *= 2.0;
          }
          if (evoBoard.imageSaveInterval >= 0.7) {
            evoBoard.imageSaveInterval = Math.round(evoBoard.imageSaveInterval);
          }
        } 
        else if (buttonNum == 4) {
          evoBoard.prepareForFileSave(2);
        }
        else if (buttonNum == 5) {
          if (clickedOnLeft) {
            evoBoard.textSaveInterval *= 0.5;
          } 
          else {
            evoBoard.textSaveInterval *= 2.0;
          }
          if (evoBoard.textSaveInterval >= 0.7) {
            evoBoard.textSaveInterval = Math.round(evoBoard.textSaveInterval);
          }
        } 
        else if(buttonNum == 6){
          if (clickedOnLeft) {
            if(evoBoard.playSpeed >= 2){
              evoBoard.playSpeed /= 2;
            }
            else{
              evoBoard.playSpeed = 0;
            }
          } 
          else {
            if(evoBoard.playSpeed == 0){
              evoBoard.playSpeed = 1;
            }
            else{
              evoBoard.playSpeed *= 2;
            }
          }
        } 
        else if(buttonNum == 7){
          if(clickedOnLeft){
            evoBoard.creatureMaximum -= evoBoard.creatureMaximumIncrement;
          }
          else{
            evoBoard.creatureMaximum += evoBoard.creatureMaximumIncrement;
          } 
        }  
      }
    }
    else if (mouseX >= height+10 && mouseX < width-50 && evoBoard.selectedCreature == null){
      int listIndex = (mouseY-150)/70;
      if (listIndex >= 0 && listIndex < evoBoard.listSlots) {
        evoBoard.selectedCreature = evoBoard.list[listIndex];
        cameraX = (float)evoBoard.selectedCreature.px;
        cameraY = (float)evoBoard.selectedCreature.py;
        zoom = 16;
      }
    }
    else if(1110 <= mouseX && mouseX <= 1210 && 15 <= mouseY && mouseY <= 45){
       showAxons = !showAxons;
    }
    else if(1185 <= mouseX && mouseX <= 1285 && 450 <= mouseY && mouseY <= 490){
      evoBoard.selectedCreature.userControl = !evoBoard.selectedCreature.userControl;  
    }
    if (mouseX >= width-50){
      float toClickTemp = (mouseY-30)/530.0;
      float lowTemp = 1.0-evoBoard.getLowTempProportion();
      float highTemp = 1.0-evoBoard.getHighTempProportion();
      if (abs(toClickTemp-lowTemp) < abs(toClickTemp-highTemp)) {
        dragging = 2;
      }
      else {
        dragging = 3;
      }
    }
  }
  draggedFar = false;
}
void mouseReleased(){
  if (!draggedFar){
    if (mouseX < windowHeight){
      dragging = 1;
      float mX = toWorldXCoordinate(mouseX, mouseY);
      float mY = toWorldYCoordinate(mouseX, mouseY);
      int x = (int)(floor(mX));
      int y = (int)(floor(mY));
      evoBoard.unselect();
      cameraR = 0;
      if (x >= 0 && x < boardWidth && y >= 0 && y < boardHeight) {
        for (int i = 0; i < evoBoard.softBodiesInPositions[x][y].size (); i++) {
          SoftBody body = (SoftBody)evoBoard.softBodiesInPositions[x][y].get(i);
          if (body.isCreature) {
            float distance = dist(mX, mY, (float)body.px, (float)body.py);
            if (distance <= body.getRadius()) {
              evoBoard.selectedCreature = (Creature)body;
              zoom = 16;
            }
          }
        }
      }
    }
  }
  dragging = 0;
}
void resetZoom() {
  cameraX = boardWidth*0.5;
  cameraY = boardHeight*0.5;
  zoom = 1;
}
void setZoom(float target, float x, float y) {
  float grossX = grossify(x, boardWidth);
  cameraX -= (grossX/target-grossX/zoom);
  float grossY = grossify(y, boardHeight);
  cameraY -= (grossY/target-grossY/zoom);
  zoom = target;
}
float grossify(float input, float total) {
  return (input/overallScaleFactor-total*0.5*scale)/scale;
}
float toWorldXCoordinate(float x, float y) {
  float w = windowHeight/2;
  float angle = atan2(y-w, x-w);
  float dist = dist(w, w, x, y);
  return cameraX+grossify(cos(angle-cameraR)*dist+w, boardWidth)/zoom;
}
float toWorldYCoordinate(float x, float y) {
  float w = windowHeight/2;
  float angle = atan2(y-w, x-w);
  float dist = dist(w, w, x, y);
  return cameraY+grossify(sin(angle-cameraR)*dist+w, boardHeight)/zoom;
}
