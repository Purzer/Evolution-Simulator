import java.io.*;

class Board{
  int boardWidth;
  int boardHeight;
  int creatureMinimum;
  int creatureMaximum;
  Tile[][] tiles;
  double year = 0;
  float minTemp;
  float maxTemp;
  final float thermometerMin = -2;
  final float thermometerMax = 2;
  final int numberOfRocks;
  final float minRockEnergy = 0.8;
  final float maxRockEnergy = 2.5;
  final float minCreatureEnergy = 1.2;
  final float maxCreatureEnergy = 2.0;
  final float rockDensity = 5;
  final float objectTimestepsPerYear = 100;
  final color rockColor = color(0,0,0.5);
  final color backgroundColor = color(0,0,0.1);
  final float minSurvivableSize = 0.06;
  final float creatureStrokeWeight = 0.6;
  ArrayList[][] softBodiesInPositions;
  ArrayList<SoftBody> rocks;
  ArrayList<Creature> creatures;
  Creature selectedCreature = null;
  int creatureIDUpTo = 0;
  float[] letterFrequencies = {8.167,1.492,2.782,4.253,12.702,2.228,2.015,6.094,6.966,0.153,0.772,4.025,2.406,6.749,
  7.507,1.929,0.095,5.987,6.327,9.056,2.758,0.978,2.361,0.150,1.974,1000.0};
  final int listSlots = 3;
  int creatureRankMetric = 0;
  color buttonColor = color(0,0,0.5);
  Creature[] list = new Creature[listSlots];
  final int creatureMinimumIncrement = 5;
  final int creatureMaximumIncrement = 100;
  String folder = "TEST";
  int[] fileSaveCounts;
  double[] fileSaveTimes;
  double imageSaveInterval = 25;
  double textSaveInterval = 1;
  final double flashSpeed = 80;
  boolean userControl;
  boolean killAllCreatures = false;
  double temperature;
  double manualBirthSize = 1.2;
  boolean wasPressingB = false;
  double timeStep; 
  int populationHistoryLength = 200;
  double recordPopulationEvery = 0.50;
  int[] populationHistory;
  int playSpeed = 0;
  int sizeHistoryLength = 1000;
  double recordSizeEvery = 0.10;
  public int threadsToFinish = 0;
 
  public Board(int w, int h, float stepSize, float min, float max, int rta, int cmin, int cmax, int SEED, String initialFileName, double ts){
    noiseSeed(SEED);
    randomSeed(SEED);
    boardWidth = w;
    boardHeight = h;
    tiles = new Tile[w][h];
    for(int x = 0; x < boardWidth; x++){
      for(int y = 0; y < boardHeight; y++){
        float bigForce = .75;
        float fertility = noise(x*stepSize*3,y*stepSize*3)*(1-bigForce)*5.0+noise(x*stepSize*0.5,y*stepSize*0.5)*bigForce*5.0-1.5;
        float climateType = noise(x*stepSize*0.5+10000,y*stepSize*0.5+10000)*.6-.1;
        climateType = min(max(climateType,0.05),0.4);
        tiles[x][y] = new Tile(x,y,fertility,0,climateType,this);
      }
    }
    minTemp = min;
    maxTemp = max;
    
    softBodiesInPositions = new ArrayList[boardWidth][boardHeight];
    for(int x = 0; x < boardWidth; x++){
      for(int y = 0; y < boardHeight; y++){
        softBodiesInPositions[x][y] = new ArrayList<SoftBody>(0);
      }
    }
    
    numberOfRocks = rta;
    rocks = new ArrayList<SoftBody>(0);
    for(int i = 0; i < numberOfRocks; i++){
      rocks.add(new SoftBody(random(0,boardWidth),random(0,boardHeight),0,0,
      getRandomSize(),rockDensity,hue(rockColor),saturation(rockColor),brightness(rockColor),this,year));
    }
    
    creatureMinimum = cmin;
    creatureMaximum = cmax;
    creatures = new ArrayList<Creature>(0);
    maintainCreatureMinimum();
    for(int i = 0; i < listSlots; i++){
      list[i] = null;
    }
    folder = initialFileName;
    fileSaveCounts = new int[4];
    fileSaveTimes = new double[4];
    for(int i = 0; i < 4; i++){
      fileSaveCounts[i] = 0;
      fileSaveTimes[i] = -999;
    }
    userControl = false;
    timeStep = ts;
    populationHistory = new int[populationHistoryLength];
    for(int i = 0; i < populationHistoryLength; i++){
      populationHistory[i] = 0;
    }
  }
  public void drawBoard(float scaleUp, float camZoom, int mX, int mY){
    for(int x = 0; x < boardWidth; x++){
      for(int y = 0; y < boardHeight; y++){
        tiles[x][y].drawTile(scaleUp, (mX == x && mY == y));
      }
    }
    for(int i = 0; i < rocks.size(); i++){
      rocks.get(i).drawSoftBody(scaleUp);
    }
    for(int i = 0; i < creatures.size(); i++){
      creatures.get(i).drawSoftBody(scaleUp, camZoom,true);
    }
  }
  public void drawBlankBoard(float scaleUp){
    fill(backgroundColor);
    rect(0,0,scaleUp*boardWidth,scaleUp*boardHeight);
  }
  public void drawUI(float scaleUp, double timeStep, int x1, int y1, int x2, int y2, PFont font){
    fill(0,0,0);
    noStroke();
    rect(x1,y1,x2-x1,y2-y1);
    
    pushMatrix();
    translate(x1,y1);
    
    fill(0,0,1);
    textAlign(LEFT);
    textFont(font,48);
    String yearText = "Year "+nf((float)year,0,2);
    text(yearText,10,48);
    textFont(font,24);
    text("Population: "+creatures.size(),10,80);
    String[] seasons = {"Winter","Spring","Summer","Autumn", "Winter"};
    text(seasons[(int)((getSeason()+0.125)*4)],180,80);
    
    if(selectedCreature == null){
      for(int i = 0; i < listSlots; i++){
        list[i] = null;
      }
      for(int i = 0; i < creatures.size(); i++){
        int lookingAt = 0;
        if(creatureRankMetric == 4){
          while(lookingAt < listSlots && list[lookingAt] != null && list[lookingAt].name.compareTo(creatures.get(i).name) < 0){
            lookingAt++;
          }
        }
        else if(creatureRankMetric == 5){
          while(lookingAt < listSlots && list[lookingAt] != null && list[lookingAt].name.compareTo(creatures.get(i).name) >= 0){
            lookingAt++;
          }
        }
        else{
          while(lookingAt < listSlots && list[lookingAt] != null && list[lookingAt].measure(creatureRankMetric) > creatures.get(i).measure(creatureRankMetric)){
            lookingAt++;
          }
        }
        if(lookingAt < listSlots){
          for(int j = listSlots-1; j >= lookingAt+1; j--){
            list[j] = list[j-1];
          }
          list[lookingAt] = creatures.get(i);
        }
      }
      double maxEnergy = 0;
      for(int i = 0; i < listSlots; i++){
        if(list[i] != null && list[i].energy > maxEnergy){
          maxEnergy = list[i].energy;
        }
      }
      for(int i = 0; i < listSlots; i++){
        if(list[i] != null){
          list[i].preferredRank += (i-list[i].preferredRank)*0.4;
          float y = 175+70*list[i].preferredRank;
          drawCreature(list[i],45,y+5,2.3,scaleUp);
          textFont(font, 24);
          textAlign(LEFT);
          noStroke();
          fill(0.333,1,0.4);
          float multi = (x2-x1-200);
          if(list[i].energy > 0){
            rect(85,y+5,(float)(multi*list[i].energy/maxEnergy),25);
          }
          if(list[i].energy > 1){
            fill(0.333,1,0.8);
            rect(85+(float)(multi/maxEnergy),y+5,(float)(multi*(list[i].energy-1)/maxEnergy),25);
          }
          fill(0,0,1);
          text(list[i].getCreatureName()+"("+list[i].gen+")"+" ["+list[i].id+"] ("+toAge(list[i].birthTime)+")",90,y);
          text("Energy: "+nf(100*(float)(list[i].energy),0,2),90,y+25);
        }
      }
      noStroke();
      fill(buttonColor);
      rect(10,95,220,40);
      rect(240,95,220,40);
      fill(0,0,1);
      textAlign(CENTER);
      text("Reset Zoom",120,123);
      String[] sorts = {"Biggest","Smallest","Youngest","Oldest","A to Z","Z to A","Highest Gen","Lowest Gen"};
      text("Sort by: "+sorts[creatureRankMetric],350,123);
      
      fill(0,1,0);
      rect(0,370,500,300);
      
      textFont(font,17);
      String[] buttonTexts = {"Kill All Creatures","Creature Minimum: "+creatureMinimum,
      "Screenshot Now","-   Image Every "+nf((float)imageSaveInterval,0,2)+" Years   +",
      "Text File Now","-    Text Every "+nf((float)textSaveInterval,0,2)+" Years    +",
      "-    Play Speed ("+playSpeed+"x)    +","Creature Maximum: "+creatureMaximum};
      //if(userControl){
      //  buttonTexts[0] = "Keyboard Control";
      //}
      for(int i = 0; i < 8; i++){
        float x = (i%2)*230+10;
        float y = floor(i/2)*50+370;
        fill(buttonColor);
        if(i == 0 && killAllCreatures == true){
          fill(0,1,0.8);
          buttonTexts[0] = "Yes                     No";
        }
        rect(x,y,220,40);
        if(i >= 2 && i < 6){
          double flashAlpha = 1.0*Math.pow(0.5,(year-fileSaveTimes[i-2])*flashSpeed);
          fill(0,0,1,(float)flashAlpha);
          rect(x,y,220,40);
        }
        fill(0,0,1,1);
        text(buttonTexts[i],x+110,y+17);
        if(i == 0){
        }
        else if(i == 1){
          text("-"+creatureMinimumIncrement+
          "                        +"+creatureMinimumIncrement,x+110,y+37);
        }
        else if(i <= 5){
          text(getNextFileName(i-2),x+110,y+37);
        }
        else if(i == 7){
          text("-"+creatureMaximumIncrement+"                    +"+creatureMaximumIncrement,x+110,y+37);
        }  
      }
      drawPopulationGraph(x1,x2,y2);
      fill(0,0,1);
      textAlign(RIGHT);
      textFont(font,24);
      text("Population Graph",x2-x1-15,y2-y1-35);
    }
    else{
      float energyUsage = (float)selectedCreature.getEnergyUsage(timeStep);
      noStroke();
      if(energyUsage <= 0){
        fill(0,1,0.5);
      }
      else{
        fill(0.33,1,0.4);
      }
      float EUbar = 20*energyUsage;
      rect(110,280,min(max(EUbar,-110),110),25);
      //if(EUbar < -110){
      //  rect(0,280,25,(-110-EUbar)*20+25);
      //}
      //else if(EUbar > 110){
      //  float h = (EUbar-110)*20+25;
      //  rect(185,280-h,25,h);
      //}
      fill(0,0,1);
      textFont(font,15);
      text("Name: "+selectedCreature.getCreatureName(),10,225);
      text("Energy: "+nf(100*(float)selectedCreature.energy,0,2),10,250);
      text("E Change: "+nf(100*energyUsage,0,2)+" Energy/Year",10,275);
      
      text("ID: "+selectedCreature.id,10,325);
      text("X: "+nf((float)selectedCreature.px,0,2),10,345);
      text("Y: "+nf((float)selectedCreature.py,0,2),10,365);
      text("Rotation: "+nf((float)selectedCreature.rotation,0,2),10,385);
      text("B-day: "+toDate(selectedCreature.birthTime),10,405);
      text("("+toAge(selectedCreature.birthTime)+")",10,425);
      text("Generation: "+selectedCreature.gen,10,445);
      text("Parents: "+selectedCreature.parents,10,465,210,255);
      text("Hue: "+nf((float)(selectedCreature.hue),0,2),10,500,210,255);
      text("Mouth hue: "+nf((float)(selectedCreature.mouthHue),0,2),10,525,210,255);
      
      textAlign(CENTER);
      fill(buttonColor);
      rect(400,450,100,40);
      fill(0,0,1);
      if(selectedCreature.userControl == false){
        text("Brain Control",400,460,100,40);
      }
      else{
        text("User Control",400,460,100,40);
      }
      textAlign(LEFT);
      if(selectedCreature.userControl){
        text("Controls:\nUp/Down: Move\nLeft/Right: Rotate\nSpace: Eat\nF: Fight\nV: Vomit\nU,J: Change color"+
        "\nI,K: Change mouth color\nB: Give birth (Not possible if under "+Math.round((manualBirthSize+1)*100)+" energy)",150,325,250,400);
      }
      pushMatrix();
      translate(330,80);
      selectedCreature.drawBrain(font,26);
      popMatrix();
      
      selectedCreature.drawSizeGraph(x1,x2,y2);
      fill(0,0,1);
      textAlign(RIGHT);
      textFont(font,24);
      text("Size Graph",x2-x1-200,y2-y1-230);
      
      fill(buttonColor);
      rect(325,15,100,30);
      fill(0,0,1);
      textAlign(CENTER);
      textFont(font,17);
      text("Show Axons",375,35);
    }
    popMatrix();
   
    pushMatrix();
    translate(x2,y1);
    textAlign(RIGHT);
    textFont(font,24);
    text("Temperature",-10,24);
    drawThermometer(-45,30,20,530,temperature,thermometerMin,thermometerMax,color(0,1,1));
    popMatrix();
    
    if(selectedCreature != null){
      drawCreature(selectedCreature,x1+65,y1+147,2.3,scaleUp);
    }
  }
  void drawPopulationGraph(float x1, float x2,float y2){
    float barWidth = (x2-x1)/((float)(populationHistoryLength));
    noStroke();
    fill(0.33333,1,0.6);
    int maxPopulation = 0;
    for(int i = 0; i < populationHistoryLength; i++){
      if(populationHistory[i] > maxPopulation){
        maxPopulation = populationHistory[i];
      }
    }
    for(int i = 0; i < populationHistoryLength; i++){
      float h = (((float)populationHistory[i])/maxPopulation)*(y2-570);
      rect((populationHistoryLength-1-i)*barWidth,y2-h,barWidth,h);
    }
  }
  String getNextFileName(int type){
    String[] modes = {"manualImgs","autoImgs","manualTexts","autoTexts"};
    String ending = ".png";
    if(type >= 2){
      ending = ".txt";
    }
    return folder+"/"+modes[type]+"/"+nf(fileSaveCounts[type],5)+ending;
  }
  public void iterate(double timeStep){
    double prevYear = year;
    year += timeStep; 
    if(selectedCreature != null){
    cameraX = (float)evoBoard.selectedCreature.px;
    cameraY = (float)evoBoard.selectedCreature.py;
    }
    else{
     for(int i = 0; i < creatures.size(); i++){
       creatures.get(i).userControl = false;
     }
    }
    if(Math.floor(year/recordPopulationEvery) != Math.floor(prevYear/recordPopulationEvery)){
      for(int i = populationHistoryLength-1; i >= 1; i--){
        populationHistory[i] = populationHistory[i-1];
      }
      populationHistory[0] = creatures.size();
    }
    temperature = getGrowthRate(getSeason());
    double tempChangeIntoThisFrame = temperature-getGrowthRate(getSeason()-timeStep);
    double tempChangeOutOfThisFrame = getGrowthRate(getSeason()+timeStep)-temperature;
    if(tempChangeIntoThisFrame*tempChangeOutOfThisFrame <= 0){
      for(int x = 0; x < boardWidth; x++){
        for(int y = 0; y < boardHeight; y++){
          tiles[x][y].iterate();
        }
      }
    }
    /*for(int x = 0; x < boardWidth; x++){
      for(int y = 0; y < boardHeight; y++){
        tiles[x][y].iterate(this, year);
      }
    }*/
    for(int i = 0; i < creatures.size(); i++){
      creatures.get(i).setPreviousEnergy();
    }
    /*for(int i = 0; i < rocks.size(); i++){
      rocks.get(i).collide(timeStep*OBJECT_TIMESTEPS_PER_YEAR);
    }*/
    maintainCreatureMinimum();
    maintainCreatureMaximum();
    threadsToFinish = creatures.size();
    for(int i = 0; i < creatures.size(); i++){
      Creature me = creatures.get(i);
      me.collide();
      me.metabolize(timeStep);
      me.useBrain(timeStep, !me.userControl);
      if(Math.floor(year/recordSizeEvery) != Math.floor(prevYear/recordSizeEvery)){
        for(int x = sizeHistoryLength-1; x >= 1; x--){
          me.sizeHistory[x] = me.sizeHistory[x-1];
        }
        me.sizeHistory[0] = me.energy;
      }
      if(me.userControl){
        if(me == selectedCreature){
          if(keyPressed){
             if (key == CODED) {
              if (keyCode == UP) me.accelerate(0.04,timeStep*objectTimestepsPerYear);
              if (keyCode == DOWN) me.accelerate(-0.04,timeStep*objectTimestepsPerYear);
              if (keyCode == LEFT) me.turn(-0.1,timeStep*objectTimestepsPerYear);
              if (keyCode == RIGHT) me.turn(0.1,timeStep*objectTimestepsPerYear);
            }
            else{
              if(key == ' ') me.eat(0.1,timeStep*objectTimestepsPerYear);
              if(key == 'v') me.eat(-0.1,timeStep*objectTimestepsPerYear);
              if(key == 'f')  me.fight(0.5,timeStep*objectTimestepsPerYear);
              if(key == 'u') me.setHue(me.hue+0.02);
              if(key == 'j') me.setHue(me.hue-0.02);
              
              if(key == 'i') me.setMouthHue(me.mouthHue+0.02);
              if(key == 'k') me.setMouthHue(me.mouthHue-0.02);
              if(key == 'b'){
                if(!wasPressingB){
                  me.reproduce(manualBirthSize);
                }
                wasPressingB = true;
              }
              else{
                wasPressingB = false;
              }
            }
          }
        }
      }
      if(me.getRadius() < minSurvivableSize){
        me.returnToEarth();
        creatures.remove(me);
        i--;
      }
    }
    finishIterate(timeStep);
  }
  public void finishIterate(double timeStep){
    for(int i = 0; i < rocks.size(); i++){
      rocks.get(i).applyMotions(timeStep*objectTimestepsPerYear);
    }
    for(int i = 0; i < creatures.size(); i++){
      creatures.get(i).applyMotions(timeStep*objectTimestepsPerYear);
      creatures.get(i).see();
    }
    if(Math.floor(fileSaveTimes[1]/imageSaveInterval) != Math.floor(year/imageSaveInterval)){ 
      prepareForFileSave(1);
    }
    if(Math.floor(fileSaveTimes[3]/textSaveInterval) != Math.floor(year/textSaveInterval)){
      prepareForFileSave(3);
    }
  }
  private double getGrowthRate(double theTime){
    double temperatureRange = maxTemp-minTemp;
    return minTemp+temperatureRange*0.5-temperatureRange*0.5*Math.cos(theTime*2*Math.PI);
  }
  private double getGrowthOverTimeRange(double startTime, double endTime){
    double temperatureRange = maxTemp-minTemp;
    double m = minTemp+temperatureRange*0.5;
    return (endTime-startTime)*m+(temperatureRange/Math.PI/4.0)*
    (Math.sin(2*Math.PI*startTime)-Math.sin(2*Math.PI*endTime));
  }
  private double getSeason(){
    return (year%1.0);
  }
  private void drawThermometer(float x1, float y1, float w, float h, double prog, double min, double max,
  color fillColor){
    noStroke();
    fill(0,0,0.2);
    rect(x1,y1,w,h);
    fill(fillColor);
    double proportionFilled = (prog-min)/(max-min);
    rect(x1,(float)(y1+h*(1-proportionFilled)),w,(float)(proportionFilled*h));
    
    
    double zeroHeight = (0-min)/(max-min);
    double zeroLineY = y1+h*(1-zeroHeight);
    textAlign(RIGHT);
    stroke(0,0,1);
    strokeWeight(3);
    line(x1,(float)(zeroLineY),x1+w,(float)(zeroLineY));
    double minY = y1+h*(1-(minTemp-min)/(max-min));
    double maxY = y1+h*(1-(maxTemp-min)/(max-min));
    fill(0,0,0.8);
    line(x1,(float)(minY),x1+w*1.8,(float)(minY));
    line(x1,(float)(maxY),x1+w*1.8,(float)(maxY));
    line(x1+w*1.8,(float)(minY),x1+w*1.8,(float)(maxY));
    
    fill(0,0,1);
    text("Zero",x1-5,(float)(zeroLineY+8));
    text(nf(minTemp,0,2),x1-5,(float)(minY+8));
    text(nf(maxTemp,0,2),x1-5,(float)(maxY+8));
  }
  //private void drawVerticalSlider(float x1, float y1, float w, float h, double prog, color fillColor, color antiColor){
  //  noStroke();
  //  fill(0,0,0.2);
  //  rect(x1,y1,w,h);
  //  if(prog >= 0){
  //    fill(fillColor);
  //  }
  //else{
  //    fill(antiColor);
  //  }
  //  rect(x1,(float)(y1+h*(1-prog)),w,(float)(prog*h));
  //}
  private boolean setMinTemp(float temp){
    minTemp = tempBounds(minTemp+temp*(maxTemp-minTemp));
    if(minTemp > maxTemp){
      float placeHolder = maxTemp;
      maxTemp = minTemp;
      minTemp = placeHolder;
      return true;
    }
    return false;
  }
  private boolean setMaxTemp(float temp){
    maxTemp = tempBounds(minTemp+temp*(maxTemp-minTemp));
    if(minTemp > maxTemp){
      float placeHolder = maxTemp;
      maxTemp = minTemp;
      minTemp = placeHolder;
      return true;
    }
    return false;
  }
  private float tempBounds(float temp){
    return min(max(temp,minTemp),thermometerMax);
  }
  private float getHighTempProportion(){
    return (maxTemp-thermometerMin)/(maxTemp-thermometerMin);
  }
  private float getLowTempProportion(){
    return (minTemp-thermometerMin)/(maxTemp-thermometerMin);
  }
  private String toDate(double d){
    return "Year "+nf((float)(d),0,2);
  }
  private String toAge(double d){
    return nf((float)(year-d),0,2)+" Years Old";
  }
  private void maintainCreatureMinimum(){
    while(creatures.size() < creatureMinimum){
      creatures.add(new Creature(random(0,boardWidth),random(0,boardHeight),0,0,
      random(minCreatureEnergy,maxCreatureEnergy),1,random(0,1),1,1,
      this,year,random(0,2*PI),0,"","[PRIMORDIAL]",true,null,null,1,random(0,1)));
    }
  }
  private void maintainCreatureMaximum(){
    int[] savedCreatures = new int[creatureMinimum];
    double[] creatureEnergy = new double[creatureMinimum];
    boolean newCreature = false;
    if(creatures.size() > creatureMaximum && creatureMaximum > creatureMinimum){
      for(int i = 0; i < creatureMinimum; i++){
        newCreature = false;
        while(newCreature == false){
          savedCreatures[i] = (int)(random(0,creatures.size()));
          newCreature = true;
          for(int x = 0; x > i; x++){
            if (savedCreatures[i] == savedCreatures[x]){
              newCreature = false;
            }
          }
        }
      }
      for(int i = 0; i < creatureMinimum; i++){ //<>//
        Creature c = creatures.get(savedCreatures[i]);
        creatureEnergy[i] = c.energy;
      }  
      killAllCreatures();
      for(int i = 0; i < creatureMinimum; i++){
        Creature c = creatures.get(savedCreatures[i]);
        c.energy = creatureEnergy[i];
      }
    }
  }
  private void killAllCreatures(){
    for(int i = 0; i < creatures.size(); i++){
      Creature c = creatures.get(i);
      c.kill();
    }
  }
  private double getRandomSize(){
    return pow(random(minRockEnergy,maxRockEnergy),4);
  }
  private void drawCreature(Creature c, float x, float y, float scale, float scaleUp){
    pushMatrix();
    float scaleIconUp = scaleUp*scale;
    translate((float)(-c.px*scaleIconUp),(float)(-c.py*scaleIconUp));
    translate(x,y);
    c.drawSoftBody(scaleIconUp, 40.0/scale,false);
    popMatrix();
  }
  private void prepareForFileSave(int type){
    fileSaveTimes[type] = -999999;
  }
  private void fileSave(){
    for(int i = 0; i < 4; i++){
      if(fileSaveTimes[i] < -99999){
        fileSaveTimes[i] = year;
        if(i < 2){
          saveFrame(getNextFileName(i));
        }
        else{
          String[] data = this.toBigString();
          saveStrings(getNextFileName(i),data);
        }
        fileSaveCounts[i]++;
      }
    }
  }
  public String[] toBigString(){
    String[] placeholder = {"Doesn't work"};
    return placeholder;
  }
  public void unselect(){
    selectedCreature = null;
  }
}
