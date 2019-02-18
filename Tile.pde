class Tile{
  Board board;
  public final color barrenColor = color(0,0,1);
  public final color fertileColor = color(0,0,0.2);
  public final color blackColor = color(0,1,0);
  public final color waterColor = color(0.60,0.40,0.75);
  public final float foodGrowthRate = 1.0;
  
  private double fertility;
  private double foodLevel;
  private final float maxGrowthLevel = 3.0;
  private int posX;
  private int posY;
  private double lastUpdateTime = 0;
  
  public double climateType;
  public double foodType;
  
  public Tile(int x, int y, double f, float food, float type, Board b){
    posX = x;
    posY = y;
    fertility = Math.max(0,f);
    foodLevel = Math.max(0,food);
    climateType = foodType = type;
    board = b;
  }
  public double getFertility(){
    return fertility;
  }
  public double getFoodLevel(){
    return foodLevel;
  }
  public void setFertility(double f){
    fertility = f;
  }
  public void setFoodLevel(double f){
    foodLevel = f;
  }
  public void drawTile(float scaleUp, boolean showEnergy){
    //stroke(0,0,0);
    noStroke();
    //strokeWeight(0);
    color landColor = getColor();
    fill(landColor);
    rect(posX*scaleUp,posY*scaleUp,scaleUp,scaleUp);
    if(showEnergy){
      if(brightness(landColor) >= 0.9){
        fill(0,0,0,1);
      }
      else{
        fill(0,0,1,1);
      }
      textAlign(CENTER);
      textFont(font,6);
      text(nf((float)(100*foodLevel),0,2)+" Energy",(posX+0.5)*scaleUp,(posY+0.3)*scaleUp);
      text("Climate: "+nf((float)(climateType),0,2),(posX+0.5)*scaleUp,(posY+0.6)*scaleUp);
      text("Temp: "+String.format("%.2g%n",board.getGrowthRate(board.getSeason(),climateType)),(posX+0.5)*scaleUp,(posY+0.9)*scaleUp);
    }
  }
  public void iterate(){
    double updateTime = board.year;
    if(Math.abs(lastUpdateTime-updateTime) >= 0.00001){
      double growthChange = board.getGrowthOverTimeRange(lastUpdateTime,updateTime,climateType);
      if(fertility > 1){
        foodLevel = 0;
      }
      else{
        if(growthChange > 0){
          if(foodLevel < maxGrowthLevel){
            double newDistToMax = (maxGrowthLevel-foodLevel)*Math.pow(2.71828182846,-growthChange*fertility*foodGrowthRate);
            double foodGrowthAmount = (maxGrowthLevel-newDistToMax)-foodLevel;
            addFood(foodGrowthAmount,false);
          }
        }
        else{
          removeFood(foodLevel-foodLevel*Math.pow(2.71828182846,growthChange*foodGrowthRate),false);
        }
        /*if(growableTime > 0){
          if(foodLevel < maxGrowthLevel){
            double foodGrowthAmount = (maxGrowthLevel-foodLevel)*fertility*foodGrowthRate*timeStep*growableTime;
            addFood(foodGrowthAmount,climateType);
          }
        }
        else{
          foodLevel += maxGrowthLevel*foodLevel*foodGrowthRate*timeStep*growableTime;
        }*/
      }
      foodLevel = Math.max(foodLevel,0);
      lastUpdateTime = updateTime;
    }
  }
  public void addFood(double amount,boolean canCauseIteration){
    if(canCauseIteration){
      iterate();
    }
    foodLevel += amount;
  }
  public void removeFood(double amount, boolean canCauseIteration){
    if(canCauseIteration){
      iterate();
    }
    foodLevel -= amount;
  }
  public color getColor(){
    iterate();
    color foodColor = color((float)(foodType),1,1);
    if(fertility > 1){
      foodColor = color(0.6, 1.0, (float)(foodType));
      return interColorFixedHue(interColor(barrenColor,waterColor,fertility-.2),foodColor,foodLevel/maxGrowthLevel,hue(foodColor));
    }
    else if(foodLevel < 1.7){
      return interColorFixedHue(interColor(barrenColor,fertileColor,fertility),foodColor,foodLevel/maxGrowthLevel,hue(foodColor));
    }
    else{
      return interColorFixedHue(interColor(barrenColor,fertileColor,fertility),foodColor,1.7/maxGrowthLevel,hue(foodColor));
    }
  }
  public color interColor(color a, color b, double x){
    double hue = inter(hue(a),hue(b),x);
    double sat = inter(saturation(a),saturation(b),x);
    double bri = inter(brightness(a),brightness(b),x);
    return color((float)(hue),(float)(sat),(float)(bri));
  }
  public color interColorFixedHue(color a, color b, double x, double hue){
    double satB = saturation(b);
    if(brightness(b) == 0){
      satB = 1;
    }
    double sat = inter(saturation(a),satB,x);
    double bri = inter(brightness(a),brightness(b),x);
    return color((float)(hue),(float)(sat),(float)(bri));
  }
  public double inter(double a, double b, double x){
    return a + (b-a)*x;
  }
} 
