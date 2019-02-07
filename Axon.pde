class Axon{
  final double Mutability = 0.7;
  final int mutatePower = 9; 
  final double mutateMulti;
  
  double weight;
  double mutability;
  public Axon(double w, double m){
    weight = w;
    mutability = m;
    mutateMulti = Math.pow(0.5,mutatePower);
  }
  
  public Axon mutateAxon(){
    double mutabilityMutate = Math.pow(0.5,pmRan()*Mutability);
    return new Axon(weight+r()*mutability/mutateMulti,mutability*mutabilityMutate);
  }
  public double r(){
    return Math.pow(pmRan(),mutatePower);
  }
  public double pmRan(){
    return (Math.random()*2-1);
  }
}  
