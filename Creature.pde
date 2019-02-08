class Creature extends SoftBody{
  double accelerationEnergy = 0.25;
  double backAccelerationEnergy = 0.30;
  double swimEnergy = 0.00015;
  double turnEnergy = 0.05;
  double eatEnergy = 0.005;
  double eatSpeed = 0.5;
  double eatWhileMovingMultiplier = 20.0;
  double fightEnergy = 0.75;
  double injuredEnergy = 1.00;
  double metabolismEnergy = 0.0025;
  String name;
  String parents;
  int gen;
  int id;
  boolean userControl = false;
  double visionDistance = 10;
  double currentEnergy;
  double previousBirthTime;
  final int energyHistoryLength = 6;
  final double safeSize = 1.25; 
  double[] previousEnergy = new double[energyHistoryLength];
  final double matureAgeMin = 10;
  final double matureAgeMax = 20;
  final double matureAge = matureAgeMin+(Math.random()*(matureAgeMax-matureAgeMin));
  final double birthDelayMin = 3;
  final double birthDelayMax = 6;
  final double birthDelay = birthDelayMin+(Math.random()*(birthDelayMax-birthDelayMin));
  final double axonVaribility = 1.0;
  final double foodSensitivity = 2.00;
  
  double vr = 0;
  double rotation = 0;
  final int genXP = 3;
  final int brainWidth = 10;
  final int brainHeight = 14;
  final double axonMutability = 0.0005;
  final int minNameLength = 3;
  final int maxNameLength = 10;
  final float brightnessThreshold = 0.7;
  Axon[][][] axons;
  double[][] neurons;
  
  float preferredRank = 8;
  double[] visionAngles = {0,-0.4,0.4};
  double[] visionDistances = {0,0.7,0.7};
  double[] visionOccludedX = new double[visionAngles.length];
  double[] visionOccludedY = new double[visionAngles.length];
  double visionResults[] = new double[9];
  int memoryCount = brainHeight-10;
  double[] memories;
  
  double[] sizeHistory;
  
  float crossSize = 0.022;
  
  double mouthHue;
  CreatureThread thread;
  
  public Creature(double tpx, double tpy, double tvx, double tvy, double tenergy,
  double tdensity, double thue, double tsaturation, double tbrightness, Board tb, double bt,
  double rot, double tvr, String tname,String tparents, boolean mutateName,
  Axon[][][] tbrain, double[][] tneurons, int tgen, double tmouthHue){
    super(tpx,tpy,tvx,tvy,tenergy,tdensity,thue, tsaturation, tbrightness,tb, bt);
    if(tbrain == null){
      axons = new Axon[brainWidth-1][brainHeight][brainHeight*brainWidth];
      neurons = new double[brainWidth][brainHeight];
      for(int y = 0; y < brainHeight; y++){
        for(int z = 0; z < brainHeight; z++){
          axons[0][y][z] = new Axon((Math.random()*2-1)*axonVaribility,axonMutability);
        }
      }
      neurons = new double[brainWidth][brainHeight];
      for(int x = 0; x < brainWidth; x++){
        for(int y = 0; y < brainHeight; y++){
          neurons[x][y] = 0;
        }
      }
    }
    else{
      axons = tbrain;
      neurons = tneurons;
    }
    sizeHistory = new double [board.sizeHistoryLength];
    rotation = rot;
    vr = tvr;
    isCreature = true;
    id = board.creatureIDUpTo+1;
    if(tname.length() >= 1){
      if(mutateName){
        name = mutateName(tname);
      }
      else{
        name = tname;
      }
      name = sanitizeName(name);
    }
    else{
      name = createNewName();
    }
    parents = tparents;
    board.creatureIDUpTo++;
    //visionAngle = 0;
    //visionDistance = 0;
    //visionEndX = getVisionStartX();
    //visionEndY = getVisionStartY();
    for(int i = 0; i < 9; i++){
      visionResults[i] = 0;
    }
    memories = new double[memoryCount];
    for(int i = 0; i < memoryCount; i++){
      memories[i] = 0;
    }
    gen = tgen;
    mouthHue = tmouthHue;
  }
  public void drawBrain(PFont font, float scaleUp){
    final float neuronSize = 0.15;
    noStroke();
    fill(0,0,0.4);
    rect((-1.7-neuronSize)*scaleUp-15,-neuronSize*scaleUp-12,(2.4+brainWidth+neuronSize*2)*scaleUp/1.7+20,(brainHeight+neuronSize*2)*scaleUp);  
    
    ellipseMode(RADIUS);
    strokeWeight(2);
    textFont(font,0.58*scaleUp);
    fill(0,0,1);
    String[] inputLabels = {"Hue","Sat","Bri","1Hue",
    "1Sat","1Bri","2Hue","2Sat","2Bri","MHue","Mem"};
    String[] outputLabels = {"Accel.","Turn","Eat","Fight","Birth","1",
    "2","3","4","MHue","Mem"};
    for(int y = 0; y < brainHeight; y++){
      if(y > 9){
        textAlign(RIGHT);
        text(inputLabels[10]+(y-9),(-neuronSize-0.1)*scaleUp-20,(y+(neuronSize*0.6))*scaleUp);
        textAlign(LEFT);
        text(outputLabels[10]+(y-9),(brainWidth-1+neuronSize+0.1)*scaleUp/1.8-20,(y+(neuronSize*0.6))*scaleUp);
      }
      else{
        textAlign(RIGHT);
        text(inputLabels[y],(-neuronSize-0.1)*scaleUp-20,(y+(neuronSize*0.6))*scaleUp);
        textAlign(LEFT);
        text(outputLabels[y],(brainWidth-1+neuronSize+0.1)*scaleUp/1.8-20,(y+(neuronSize*0.6))*scaleUp);
      }
    }
    textAlign(CENTER);
    for(int x = 0; x < brainWidth; x++){
      for(int y = 0; y < brainHeight; y++){
        //noStroke();
        strokeWeight(1);
        double val = neurons[x][y];
        fill(neuronFillColor(val));
        ellipse(x*scaleUp/1.9-20,y*scaleUp,neuronSize*scaleUp,neuronSize*scaleUp);
        //fill(neuronTextColor(val));
        //text(nf((float)val,0,1),x*scaleUp,(y+(neuronSize*0.6))*scaleUp);
      }
    }
    noStroke();
    if(showAxons == true){
      int nLevel = gen/genXP;
      if(nLevel >= brainHeight*(brainWidth-1))
        nLevel = brainHeight*(brainWidth-1);
      for(int x1 = 0; x1 < brainWidth-1; x1++){
        for(int y1 = 0; y1 < brainHeight; y1++){
          if(x1 == 0){
            for(int z = 0; z < brainHeight+nLevel; z++){
              int x2 = (brainHeight*brainWidth-1-z)/brainHeight;
              int y2 = z%brainHeight;
              drawAxon(x1,y1,x2,y2,z,scaleUp);
            }
          }
          else if(brainWidth-2-x1 < 1+(nLevel-1)/brainHeight){
            if((brainWidth-2-x1)*brainHeight+y1 < nLevel){
              for(int z = 0; z < brainHeight*(brainWidth-x1); z++){ //<>//
                int x2 = (brainHeight*brainWidth-1-z)/13;
                int y2 = z%brainHeight;
                drawAxon(x1,y1,x2,y2,z,scaleUp);
              }
            }
          }
        }
      }
    }
  }
  public void drawAxon(int x1, int y1, int x2, int y2, int z, float scaleUp){
    stroke(neuronFillColor(axons[x1][y1][z].weight)); //*neurons[x1][y1]));
    line(x1*scaleUp/1.9-20,y1*scaleUp,x2*scaleUp/1.9-20,y2*scaleUp);
  }
  public void useBrain(double timeStep, boolean useOutput){
    for(int i = 0; i < 9; i++){
      neurons[0][i] = visionResults[i];
    }
    neurons[0][9] = mouthHue;
    for(int i = 0; i < memoryCount; i++){
      neurons[0][10+i] = sigmoid(memories[i]);
    }
    
    for(int x = 1; x < brainWidth; x++){
      for(int y = 0; y < brainHeight; y++){
        neurons[x][y] = 0;
      }
    }
    int nLevel = gen/genXP;
    if(nLevel >= brainHeight*(brainWidth-1))
      nLevel = brainHeight*(brainWidth-1);
    for(int x1 = 0; x1 < brainWidth-1; x1++){
      for(int y1 = 0; y1 < brainHeight; y1++){
        if(x1 == 0){
          for(int z = 0; z < brainHeight+nLevel; z++){
          int x2 = (brainHeight*brainWidth-1-z)/brainHeight;
          int y2 = z%brainHeight;
          neurons[x2][y2] += neurons[x1][y1]*axons[x1][y1][z].weight;
          }
        }
        else if(brainWidth-2-x1 < 1+(nLevel-1)/brainHeight){
          if((brainWidth-2-x1)*brainHeight+y1 < nLevel){
            for(int z = 0; z < brainHeight*(brainWidth-1-x1); z++){ //13+nLevel-(9-x1)*13; z++){              
              int x2 = (brainHeight*brainWidth-1-z)/brainHeight;
              int y2 = z%brainHeight;
              neurons[x2][y2] += neurons[x1][y1]*axons[x1][y1][z].weight;
            }
          }
        } //<>//
      }
      if(x1 < 1+nLevel/brainHeight){
        for(int y = 0; y < brainHeight; y++){
          neurons[x1+1][y] = sigmoid(neurons[x1+1][y]);
        }
      }
    }
    if(useOutput){
      int end = brainWidth-1;
      //hue = Math.min(Math.max(neurons[end][0],0),1);
      accelerate(neurons[end][1],timeStep);
      turn(neurons[end][2],timeStep);
      eat(neurons[end][3],timeStep);
      fight(neurons[end][4],timeStep);   
      if(neurons[end][5] > 0 && board.year-birthTime >= matureAge && energy > safeSize){
        reproduce(safeSize);
      }
      mouthHue = Math.min(Math.max(neurons[end][9],0.05),0.4);
      for(int i = 0; i < memoryCount; i++){
        memories[i] = neurons[end][10+i];
      }
    }
  }
  public double sigmoid(double input){
    return (2.0/(1.0+Math.pow(2.71828182846,-input))-1);
  }
  public double ageFunction(double input){
    return -1.0/(1.0+Math.pow(2.71828182846,-(input-40)/15))+1;
  }  
  public double ageFunction2(double input){
    return Math.pow(1.023,input);
  }  
  public color neuronFillColor(double d){
    if(d >= 0){
      return color(0,0,1,(float)(d));
    }
    else{
      return color(0,0,0,(float)(-d));
    }
  }
   public color neuronTextColor(double d){
    if(d >= 0){
      return color(0,0,0);
    }
    else{
      return color(0,0,1);
    }
  }
  void drawSizeGraph(float x1, float x2, float y2){
    float barWidth = (x2-x1)/((float)(board.sizeHistoryLength));
    noStroke();
    fill(0.5,1,0.6);
    float maxSize = 0;
    for(int i = 0; i < board.sizeHistoryLength; i++){
      if(sizeHistory[i] > maxSize){
        maxSize = (float)sizeHistory[i];
      }
    }
    for(int i = 0; i < board.sizeHistoryLength; i++){
      float h = (((float)sizeHistory[i])/maxSize)*(y2-570);
      rect((board.sizeHistoryLength-1-i)*barWidth,y2-h,barWidth,h);
    }
  }
  public void drawSoftBody(float scaleUp, float camZoom, boolean showVision){
    ellipseMode(RADIUS);
    double radius = getRadius();
    if(showVision){
      for(int i = 0; i < visionAngles.length; i++){
        color visionUIcolor = color(0,0,1);
        if(visionResults[i*3+2] > brightnessThreshold){
          visionUIcolor = color(0,0,0);
        }
        stroke(visionUIcolor);
        strokeWeight(board.creatureStrokeWeight);
        float endX = (float)getVisionEndX(i);
        float endY = (float)getVisionEndY(i);
        line((float)(px*scaleUp),(float)(py*scaleUp),endX*scaleUp,endY*scaleUp);
        noStroke();
        fill(visionUIcolor);
        ellipse((float)(visionOccludedX[i]*scaleUp),(float)(visionOccludedY[i]*scaleUp),
        2*crossSize*scaleUp,2*crossSize*scaleUp);
        stroke((float)(visionResults[i*3]),(float)(visionResults[i*3+1]),(float)(visionResults[i*3+2]));
        strokeWeight(board.creatureStrokeWeight);
        line((float)((visionOccludedX[i]-crossSize)*scaleUp),(float)((visionOccludedY[i]-crossSize)*scaleUp),
        (float)((visionOccludedX[i]+crossSize)*scaleUp),(float)((visionOccludedY[i]+crossSize)*scaleUp));
        line((float)((visionOccludedX[i]-crossSize)*scaleUp),(float)((visionOccludedY[i]+crossSize)*scaleUp),
        (float)((visionOccludedX[i]+crossSize)*scaleUp),(float)((visionOccludedY[i]-crossSize)*scaleUp));
      }
    noStroke();
    if(fightLevel > 0){
      fill(0,1,1,(float)(fightLevel*0.8));
      ellipse((float)(px*scaleUp),(float)(py*scaleUp),(float)(fightRange*radius*scaleUp),(float)(fightRange*radius*scaleUp));
    }
    }
    strokeWeight(board.creatureStrokeWeight);
    stroke(0,0,1);
    fill(0,0,1);
    if(this == board.selectedCreature){
      ellipse((float)(px*scaleUp),(float)(py*scaleUp),
      (float)(radius*scaleUp+1+75.0/camZoom),(float)(radius*scaleUp+1+75.0/camZoom));
    }
    super.drawSoftBody(scaleUp);
    noFill();
    strokeWeight(board.creatureStrokeWeight);
    stroke(0,0,1);
    ellipseMode(RADIUS);
    ellipse((float)(px*scaleUp),(float)(py*scaleUp),
      (float)(board.minSurvivableSize*scaleUp),(float)(board.minSurvivableSize*scaleUp));
    pushMatrix();
    translate((float)(px*scaleUp),(float)(py*scaleUp));
    scale((float)radius);
    rotate((float)rotation);
    strokeWeight((float)(board.creatureStrokeWeight/radius));
    stroke(0,0,0);
    fill((float)mouthHue,1.0,1.0);
    ellipse(0.6*scaleUp,0,0.37*scaleUp,0.37*scaleUp);
    /*rect(-0.7*scaleUp,-0.2*scaleUp,1.1*scaleUp,0.4*scaleUp);
    beginShape();
    vertex(0.3*scaleUp,-0.5*scaleUp);
    vertex(0.3*scaleUp,0.5*scaleUp);
    vertex(0.8*scaleUp,0.0*scaleUp);
    endShape(CLOSE);*/
    popMatrix();
    if(showVision){
      fill(0,0,1);
      textFont(font,0.2*scaleUp);
      textAlign(CENTER);
      text(getCreatureName(),(float)(px*scaleUp),(float)((py-getRadius()*1.4-0.07)*scaleUp));
    }
  }
  public void metabolize(double timeStep){
    loseEnergy(energy*metabolismEnergy*timeStep);
  }
  public void doThread(double timeStep, Boolean userControl){
    //collide(timeStep);
    //metabolize(timeStep);
    //useBrain(timeStep, !userControl);
    thread = new CreatureThread("Thread "+id, this, timeStep, userControl);
    thread.start();
  }
  public void accelerate(double amount, double timeStep){
    double multiplied = amount*timeStep/getMass();
    vx += Math.cos(rotation)*multiplied;
    vy += Math.sin(rotation)*multiplied;
    if(amount >= 0){
      loseEnergy(amount*accelerationEnergy*timeStep);
    }
    else{
      loseEnergy(Math.abs(amount*backAccelerationEnergy*timeStep));
    }
  }
  public void turn(double amount, double timeStep){
    vr += 0.04*amount*timeStep/getMass();
    loseEnergy(Math.abs(amount*turnEnergy*energy*timeStep));
  }
  public Tile getRandomCoveredTile(){
    double radius = (float)getRadius();
    double choiceX = 0;
    double choiceY = 0;
    while(dist((float)px,(float)py,(float)choiceX,(float)choiceY) > radius){
      choiceX = (Math.random()*2*radius-radius)+px;
      choiceY = (Math.random()*2*radius-radius)+py;
    }
    int x = xBound((int)choiceX);
    int y = yBound((int)choiceY);
    return board.tiles[x][y];
  }
  public void eat(double attemptedAmount, double timeStep){
    double amount = attemptedAmount/(1.0+distance(0,0,vx,vy)*eatWhileMovingMultiplier);
    if(distance(0,0,vx,vy) > .005){}
    else if(amount < 0){
      dropEnergy(-amount*timeStep);
      loseEnergy(-attemptedAmount*eatEnergy*timeStep);
    }
    else{
      Tile coveredTile = getRandomCoveredTile();
      double foodToEat = coveredTile.foodLevel*(1-Math.pow((1-eatSpeed),amount*timeStep));
      if(foodToEat > coveredTile.foodLevel){
        foodToEat = coveredTile.foodLevel;
      }
      coveredTile.removeFood(foodToEat, true);
      double foodDistance = Math.abs(coveredTile.foodType-mouthHue);
      double multiplier = 1.0-foodDistance/foodSensitivity;
      if(multiplier >= 0){
        addEnergy(foodToEat*multiplier);
      }
      else{
        loseEnergy(-foodToEat*multiplier);
      }
      loseEnergy(attemptedAmount*eatEnergy*timeStep);
    }
  }
  public void fight(double amount, double timeStep){
    if(amount > 0 && board.year-birthTime >= matureAge){
      fightLevel = amount;
      loseEnergy(fightLevel*fightEnergy*energy*timeStep);
      for(int i = 0; i < colliders.size(); i++){
        SoftBody collider = colliders.get(i);
        if(collider.isCreature){
          float distance = dist((float)px,(float)py,(float)collider.px,(float)collider.py);
          double combinedRadius = getRadius()*fightRange+collider.getRadius();
          if(distance < combinedRadius){
            ((Creature)collider).loseEnergy(fightLevel*injuredEnergy*timeStep);
            addEnergy(fightLevel*injuredEnergy*timeStep*5);
          }
        }
      }
    }
    else{
      fightLevel = 0;
    }
  }
  public void kill(){
    energy = 0;
  }  
  public void loseEnergy(double energyLost){
    if(energyLost > 0){
      energy -= (energyLost*ageFunction2(board.year-birthTime));
    }
  }
  public void dropEnergy(double energyLost){
    if(energyLost > 0){
      energyLost = Math.min(energyLost, energy);
      energy -= energyLost;
      getRandomCoveredTile().addFood(energyLost,true);
    }
  }
  public void see(){
    for(int k = 0; k < visionAngles.length; k++){
      double visionStartX = px;
      double visionStartY = py;
      double visionTotalAngle = rotation+visionAngles[k];
      
      double endX = getVisionEndX(k);
      double endY = getVisionEndY(k);
      
      visionOccludedX[k] = endX;
      visionOccludedY[k] = endY;
      color c = getColorAt(endX,endY);
      visionResults[k*3] = hue(c);
      visionResults[k*3+1] = saturation(c);
      visionResults[k*3+2] = brightness(c);
      
      int tileX = 0;
      int tileY = 0;
      int prevTileX = -1;
      int prevTileY = -1;
      ArrayList<SoftBody> potentialVisionOccluders = new ArrayList<SoftBody>();
      for(int DAvision = 0; DAvision < visionDistances[k]+1; DAvision++){
        tileX = (int)(visionStartX+Math.cos(visionTotalAngle)*DAvision);
        tileY = (int)(visionStartY+Math.sin(visionTotalAngle)*DAvision);
        if(tileX != prevTileX || tileY != prevTileY){
          addPVOs(tileX,tileY,potentialVisionOccluders);
          if(prevTileX >= 0 && tileX != prevTileX && tileY != prevTileY){
            addPVOs(prevTileX,tileY,potentialVisionOccluders);
            addPVOs(tileX,prevTileY,potentialVisionOccluders);
          }
        }
        prevTileX = tileX;
        prevTileY = tileY;
      }
      double[][] rotationMatrix = new double[2][2];
      rotationMatrix[1][1] = rotationMatrix[0][0] = Math.cos(-visionTotalAngle);
      rotationMatrix[0][1] = Math.sin(-visionTotalAngle);
      rotationMatrix[1][0] = -rotationMatrix[0][1];
      double visionLineLength = visionDistances[k];
      for(int i = 0; i < potentialVisionOccluders.size(); i++){
        SoftBody body = potentialVisionOccluders.get(i);
        double x = body.px-px;
        double y = body.py-py;
        double r = body.getRadius();
        double translatedX = rotationMatrix[0][0]*x+rotationMatrix[1][0]*y;
        double translatedY = rotationMatrix[0][1]*x+rotationMatrix[1][1]*y;
        if(Math.abs(translatedY) <= r){
          if((translatedX >= 0 && translatedX < visionLineLength && translatedY < visionLineLength) ||
          distance(0,0,translatedX,translatedY) < r ||
          distance(visionLineLength,0,translatedX,translatedY) < r){
            visionLineLength = translatedX-Math.sqrt(r*r-translatedY*translatedY);
            visionOccludedX[k] = visionStartX+visionLineLength*Math.cos(visionTotalAngle);
            visionOccludedY[k] = visionStartY+visionLineLength*Math.sin(visionTotalAngle);
            visionResults[k*3] = body.hue;
            visionResults[k*3+1] = body.saturation;
            visionResults[k*3+2] = body.brightness;
          }
        }
      }
    }
  }
  public color getColorAt(double x, double y){
    if(x >= 0 && x < board.boardWidth && y >= 0 && y < board.boardHeight){
      return board.tiles[(int)(x)][(int)(y)].getColor();
    }
    else{
      return board.backgroundColor;
    }
  }
  public double distance(double x1, double y1, double x2, double y2){
    return(Math.sqrt((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1)));
  }
  public void addPVOs(int x, int y, ArrayList<SoftBody> PVOs){
    if(x >= 0 && x < board.boardWidth && y >= 0 && y < board.boardHeight){
      for(int i = 0; i < board.softBodiesInPositions[x][y].size(); i++){
        SoftBody newCollider = (SoftBody)board.softBodiesInPositions[x][y].get(i);
        if(!PVOs.contains(newCollider) && newCollider != this){
          PVOs.add(newCollider);
        }
      }
    }
  }
  public void returnToEarth(){
    int pieces = 20;
    //double radius = (float)getRadius();
    for(int i = 0; i < pieces; i++){
      getRandomCoveredTile().addFood(energy/pieces,true);
    }
    for(int x = SBIPMinX; x <= SBIPMaxX; x++){
      for(int y = SBIPMinY; y <= SBIPMaxY; y++){
        board.softBodiesInPositions[x][y].remove(this);
      }
    }
    if(board.selectedCreature == this){
      board.unselect();
    }
  }
  public void reproduce(double babySize){
    if(board.year-previousBirthTime > birthDelay){
      previousBirthTime = board.year;
      if(colliders == null){
        collide();
      }
      int highestGen = 0;
      if(babySize >= 0){
        ArrayList<Creature> parents = new ArrayList<Creature>(0);
        parents.add(this);
        double availableEnergy = getBabyEnergy();
        for(int i = 0; i < colliders.size(); i++){
          SoftBody possibleParent = colliders.get(i);
          if(possibleParent.isCreature && ((Creature)possibleParent).neurons[brainWidth-1][9] > -1){
            float distance = dist((float)px,(float)py,(float)possibleParent.px,(float)possibleParent.py);
            double combinedRadius = getRadius()*fightRange+possibleParent.getRadius();
            if(distance < combinedRadius){
              parents.add((Creature)possibleParent);
              availableEnergy += ((Creature)possibleParent).getBabyEnergy();
            }
          }
        }
        if(availableEnergy > babySize){
          double newPX = random(-0.01,0.01);
          double newPY = random(-0.01,0.01);
          double newHue = 0;
          double newSaturation = 0;
          double newBrightness = 0;
          double newMouthHue = 0;
          int parentsTotal = parents.size();
          String[] parentNames = new String[parentsTotal];
          Axon[][][] newBrain = new Axon[brainWidth-1][brainHeight][brainHeight*brainWidth];
          double[][] newNeurons = new double[brainWidth][brainHeight];
          int a = 0;
          for(int i = 0; i < parentsTotal; i++){
            Creature parent = parents.get(i);
            if(parent.gen > highestGen){
              highestGen = parent.gen;
              a = i;
            }
          }
          Creature parent1 = parents.get(a);
          int nLevel = highestGen/genXP;
          if(nLevel >= brainHeight*(brainWidth-1))
            nLevel = brainHeight*(brainWidth-1);
          for(int x = 0; x < brainWidth-1; x++){
            for(int y = 0; y < brainHeight; y++){
              if(x == 0){
                for(int z = 0; z < brainHeight+nLevel; z++){
                  newBrain[x][y][z] = parent1.axons[x][y][z].mutateAxon();
                }
              }
              else if(brainWidth-2-x < 1+(nLevel-1)/brainHeight){
                if((brainWidth-2-x)*brainHeight+y < nLevel){
                  for(int z = 0; z < brainHeight*(brainWidth-1-x); z++){
                    newBrain[x][y][z] = parent1.axons[x][y][z].mutateAxon();
                  }
                }
              }
            }
          }
          if(highestGen%genXP == genXP-1){
            nLevel++;
            if(nLevel >= brainHeight*(brainWidth-1))
              nLevel = brainHeight*(brainWidth-1);
            int x = brainWidth-1-(brainHeight-1+nLevel)/brainHeight;
            int y = (nLevel-1)%brainHeight;
            for(int z = 0; z < brainHeight+nLevel-nLevel%brainHeight; z++){
              newBrain[x][y][z] = new Axon((Math.random()*2-1)*axonVaribility,axonMutability);
            }
            for(int x1 = 0; x1 < 1+(nLevel-1)/brainHeight; x1++){
              for(int y1 = 0; y1 < brainHeight; y1++){
                int z = brainHeight-1+nLevel;
                newBrain[x1][y1][z] = new Axon((Math.random()*2-1)*axonVaribility,axonMutability);
              }
            }
          }
          for(int x = 0; x < brainWidth; x++){
            for(int y = 0; y < brainHeight; y++){
              newNeurons[x][y] = parent1.neurons[x][y];
            }
          }
          for(int i = 0; i < parentsTotal; i++){
            int chosenIndex = (int)random(0,parents.size());
            Creature parent = parents.get(chosenIndex);
            parents.remove(chosenIndex);
            parent.energy -= babySize*(parent.getBabyEnergy()/availableEnergy);
            newPX += parent.px/parentsTotal;
            newPY += parent.py/parentsTotal;
            newHue += parent.hue/parentsTotal;
            newSaturation += parent.saturation/parentsTotal;
            newBrightness += parent.brightness/parentsTotal;
            newMouthHue += parent.mouthHue/parentsTotal;
            parentNames[i] = parent.name;
            if(parent.gen > highestGen){
              highestGen = parent.gen;
            }
          }
          newSaturation = 1;
          newBrightness = 1;
          board.creatures.add(new Creature(newPX,newPY,0,0,
            babySize,density,newHue,newSaturation,newBrightness,board,board.year,random(0,2*PI),0,
            stitchName(parentNames),andifyParents(parentNames),true,
            newBrain,newNeurons,highestGen+1,newMouthHue));
        }
      }
    }
  }
  public String stitchName(String[] s){
    String result = "";
    for(int i = 0; i < s.length; i++){
      float portion = ((float)s[i].length())/s.length;
      int start = (int)min(max(round(portion*i),0),s[i].length());
      int end = (int)min(max(round(portion*(i+1)),0),s[i].length());
      result = result+s[i].substring(start,end);
    }
    return result;
  }
  public String andifyParents(String[] s){
    String result = "";
    for(int i = 0; i < s.length; i++){
      if(i >= 1){
        result = result + " & ";
      }
      result = result + capitalize(s[i]);
    }
    return result;
  }
  public String createNewName(){
    String nameSoFar = "";
    int chosenLength = (int)(random(minNameLength,maxNameLength));
    for(int i = 0; i < chosenLength; i++){
      nameSoFar += getRandomChar();
    }
    return sanitizeName(nameSoFar);
  }
  public char getRandomChar(){
    float letterFactor = random(0,100);
    int letterChoice = 0;
    while(letterFactor > 0){
      letterFactor -= board.letterFrequencies[letterChoice];
      letterChoice++;
    }
    return (char)(letterChoice+96);
  }
  public String sanitizeName(String input){
    String output = "";
    int vowelsSoFar = 0;
    int consonantsSoFar = 0;
    for(int i = 0; i < input.length(); i++){
      char ch = input.charAt(i);
      if(isVowel(ch)){
        consonantsSoFar = 0;
        vowelsSoFar++;
      }
      else{
        vowelsSoFar = 0;
        consonantsSoFar++;
      }
      if(vowelsSoFar <= 2 && consonantsSoFar <= 2){
        output = output+ch;
      }
      else{
        double chanceOfAddingChar = 0.5;
        if(input.length() <= minNameLength){
          chanceOfAddingChar = 1.0;
        }
        else if(input.length() >= maxNameLength){
          chanceOfAddingChar = 0.0;
        }
        if(random(0,1) < chanceOfAddingChar){
          char extraChar = ' ';
          while(extraChar == ' ' || (isVowel(ch) == isVowel(extraChar))){
            extraChar = getRandomChar();
          }
          output = output+extraChar+ch;
          if(isVowel(ch)){
            consonantsSoFar = 0;
            vowelsSoFar = 1;
          }
          else{
            consonantsSoFar = 1;
            vowelsSoFar = 0;
          }
        }
        else{
        }
      }
    }
    return output;
  }
  public String getCreatureName(){
    return capitalize(name);
  }
  public String capitalize(String n){
    return n.substring(0,1).toUpperCase()+n.substring(1,n.length());
  }
  public boolean isVowel(char a){
    return (a == 'a' || a == 'e' || a == 'i' || a == 'o' || a == 'u' || a == 'y');
  }
  public String mutateName(String input){
    if(input.length() >= 3){
      if(random(0,1) < 0.2){
        int removeIndex = (int)random(0,input.length());
        input = input.substring(0,removeIndex)+input.substring(removeIndex+1,input.length());
      }
    }
    if(input.length() <= 9){
      if(random(0,1) < 0.2){
        int insertIndex = (int)random(0,input.length()+1);
        input = input.substring(0,insertIndex)+getRandomChar()+input.substring(insertIndex,input.length());
      }
    }
    int changeIndex = (int)random(0,input.length());
    input = input.substring(0,changeIndex)+getRandomChar()+input.substring(changeIndex+1,input.length());
    return input;
  }
  public void applyMotions(double timeStep){
    if(getRandomCoveredTile().fertility > 1){
      loseEnergy(swimEnergy*energy);
    }
    super.applyMotions(timeStep);
    rotation += vr;
    vr *= Math.max(0,1-friction/getMass());
  }
  public double getEnergyUsage(double timeStep){
    return (energy-previousEnergy[energyHistoryLength-1])/energyHistoryLength/timeStep;
  }
  public double getBabyEnergy(){
    return energy-safeSize;
  }
  public void addEnergy(double amount){
    energy += amount*ageFunction(board.year-birthTime);
  }
  public void setPreviousEnergy(){
    for(int i = energyHistoryLength-1; i >= 1; i--){
      previousEnergy[i] = previousEnergy[i-1];
    }
    previousEnergy[0] = energy;
  }
  public double measure(int choice){
    int sign = 1-2*(choice%2);
    if(choice < 2){
      return sign*energy;
    }
    else if(choice < 4){
      return sign*birthTime;
    }
    else if(choice == 6 || choice == 7){
      return sign*gen;
    }
    return 0;
  }
  public void setHue(double set){
    hue = Math.min(Math.max(set,0),1);
  }
  public void setMouthHue(double set){
    mouthHue = Math.min(Math.max(set,0),1);
  }
  public void setSaturarion(double set){
    saturation = Math.min(Math.max(set,0),1);
  }
  public void setBrightness(double set){
    brightness = Math.min(Math.max(set,0),1);
  }
  /*public void setVisionAngle(double set){
    visionAngle = set;//Math.min(Math.max(set,-Math.PI/2),Math.PI/2);
    while(visionAngle < -Math.PI){
      visionAngle += Math.PI*2;
    }
    while(visionAngle > Math.PI){
      visionAngle -= Math.PI*2;
    }
  }
  public void setVisionDistance(double set){
    visionDistance = Math.min(Math.max(set,0),MAX_VISION_DISTANCE);
  }*/
  /*public double getVisionStartX(){
    return px;//+getRadius()*Math.cos(rotation);
  }
  public double getVisionStartY(){
    return py;//+getRadius()*Math.sin(rotation);
  }*/
  public double getVisionEndX(int i){
    double visionTotalAngle = rotation+visionAngles[i];
    return px+visionDistances[i]*Math.cos(visionTotalAngle);
  }
  public double getVisionEndY(int i){
    double visionTotalAngle = rotation+visionAngles[i];
    return py+visionDistances[i]*Math.sin(visionTotalAngle);
  }
  
}
