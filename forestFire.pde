import java.util.Arrays;

//touch
int sizeTree = 20; //taille d'un arbre
int L = 400; //window size
float treeDensity = 1; // Densité d'arbres
int delay = 0; //délai entre chaque action

//tab valeur min/max 
float[] qteCombustibleTab = { 10 , 10 }; //quantité de "matière" dans l'arbre //min 0
float[] propagationAreaTab = { sizeTree*1.5 , sizeTree*2 }; //zone de transmission du feu
float[] fireResistanceTab = { 0 , 0 }; //qté de matière à brûler avant de se propager //min 0


boolean auto = true; //lancer plusieurs test d'affiler
int nbTest = 5; //nombre de test pour les tests auto
int trenchSize = 25; //largeur des tranchées

//don't touch
int nbTree;
tree[] forest;
boolean fireStarted = false;
float percentBurned;
int cpt = 0;
float[] moyPercentBurned = new float[nbTest];

void settings(){
   size(1000, 1000);
}

void setup() {
  nbTree = (int) Math.floor(Math.pow(L/sizeTree,2)*treeDensity); // Nombre d'arbre en fonction de la densité choisie et de la taille de l'arbre

  forest = new tree[nbTree];
  
  initializeForest(); //génération de la forêt
}

void draw() {
  background(255);  

  //propagation du feu 
  for (int i = 0; i < forest.length; i++) {
    float state = forest[i].getBurningQty();
    if (state != 0 && state > forest[i].getFireResistance()){ // si l'arbre brûle et a dépassé sa résistance au feu
      if (state <= forest[i].getQteCombustible()) { // si l'arbre n'est pas complétement brûlé
        fill(255, 140, 0); // orange foncé => propagation du feu              
      } else if (state == -1) { // sinon carbonisé
        fill(255,255,255); // noir => calcinés
      }
      //génère la taille du diamètre de la zone de propagation : (qté de feu - résistance) / (qté de matière - résistance) * propagation
      forest[i].setSpread((float)Math.floor(((state-forest[i].getFireResistance())/(forest[i].getQteCombustible()-forest[i].getFireResistance()))*forest[i].getPropagationArea()));
      noStroke();
      ellipse(forest[i].position.x, forest[i].position.y, forest[i].getSpread(), forest[i].getSpread()); // génère le cercle de propagation
    }
  }

  //régénére la forêt avec leur nouvel état 
  for (int i = 0; i < forest.length; i++) {
    float state = forest[i].getBurningQty();
    if (state == 0) { // si l'arbre est sain
      fill(0, 128, 0); // Vert foncé            
    } else if (state > 0) { // si l'arbre brûle 
      fill(255, 0, 0); // Rouge 
    } else if (state == -1) { // si l'arbre est calciné
      fill(100); // Gris
    }
    ellipse(forest[i].position.x, forest[i].position.y, sizeTree, sizeTree); //génère l'arbre
  }  

  //calcule le pourcentage d'arbres brûlés 
  percentBurned = 0;
  for (tree tree : forest) {
      if (tree.getBurningQty() == -1) {
          percentBurned++;
      }
  }
  percentBurned = (percentBurned / forest.length * 100.0);

  // si le feu a commencé, propage le feu entre les arbres
  if (fireStarted) {
    propagateFire();
  }
  
  ///output
  
  //nombre d'arbre
  textFont(createFont("Arial",20),20);            
  fill(0);           
  text("nbTree",L/2,30);  
  textFont(createFont("Arial",20),20);            
  fill(0);           
  text(nbTree,L/2,50);
  
  //densité
  textFont(createFont("Arial",20),20);            
  fill(0);           
  text("density",L*3/4,30);  
  textFont(createFont("Arial",20),20);            
  fill(0);           
  text(treeDensity,L*3/4,50);
  
  //% brûlé
  textFont(createFont("Arial",20),20);            
  fill(0);           
  text("% burn",L*1/4,30);  
  textFont(createFont("Arial",20),20);            
  fill(0);           
  text(percentBurned+"%",L*1/4,50);
 
 
  // auto mode
  if(auto){
    if(cpt < nbTest && fireEnded()){// si ce n'est pas le dernier test et qu'aucun arbre ne brûle
      boolean burningClick = autoMousePressed(); // simule un clic au centre de la forêt
      if(!burningClick){ // si le clic n'a pas mis feu a un arbre (l'arbre le plus près n'est pas sain)
        moyPercentBurned[cpt] = percentBurned; // ajout à l amoyenne globale
        delay(delay);
        initializeForest(); // réinitialisation de la forêt
        cpt++;
      }
    }
    
    //moyenne % brûlé  
    textFont(createFont("Arial",20),20);            
    fill(0);           
    text("moyenne % burn for "+(cpt)+" test",L*1/4,90);  
    textFont(createFont("Arial",20),20);            
    fill(0);           
    float moy = 0;
    for(float e : moyPercentBurned) {
      moy += e;
    }
    text((moy/cpt)+"%",L*1/4,110);
    
  }
}

//génération de la forêt
void initializeForest() {
  for (int i = 0; i < forest.length; i++) {
      // valeur aléatoire entre les limites choisies
      float qteComb = (float) Math.floor(random(qteCombustibleTab[0],qteCombustibleTab[1])); // quantité de matière totale de l'arbre
      float prop = (float) Math.floor(random(propagationAreaTab[0],propagationAreaTab[1])); // taille de la zone de propagation maximale de l'arbre 
      float res = (float) Math.floor(random(fireResistanceTab[0],fireResistanceTab[1]));
      if(res > qteComb){ // si la quantité de matière de l'arbre est inférieur à la résistance de l'arbre
        res = qteComb; // résistance = quantité 
      }         
      float treeX = random(L/2,L*2);
      float treeY = random(L/2,L*2);
      
      // définition des tranchées
      //tranchées sur l'axe des abscisses
      while((treeX >=500 && treeX <=500+trenchSize) || (treeX >=300 && treeX <=300+trenchSize) || (treeX >=700 && treeX <=700+trenchSize)){ // change treeX tant qu'il est dans une tranchée
        treeX = random(L/2,L*2);
      }
      //tranchées sur l'axe des ordonnés
      while((treeY >=500 && treeY <=500+trenchSize) || (treeY >=300 && treeY <=300+trenchSize) || (treeY >=700 && treeY <=700+trenchSize)){ // change treeY tant qu'il est dans une tranchée
        treeY = random(L/2,L*2);
      }
      
      // création de l'arbre
      forest[i] = new tree(treeX,treeY,qteComb,prop,res); // posx, posy, qteCombustible, propagationArea, fireResistance
  }  
}

// vérifie si l'état de l'incendie
boolean fireEnded(){
  for (tree t : forest){
    if(t.getBurningQty() > 0){
      return false;
    }
  }
  return true;
}

// simule un clic au centre de la forêt
boolean autoMousePressed(){
  tree clickedTree = closestTree(new PVector(500, 500)); // trouve l'arbre le plus proche du centre  
  if (clickedTree.getBurningQty() == 0) { // Si l'arbre est sain, allume le feu
    clickedTree.setBurning(1);
    fireStarted = true;
  } else {
    return false;
  }
  return true;
}

// clic manuel
void mousePressed() {
   tree clickedTree = closestTree(new PVector(mouseX, mouseY)); // trouve l'arbre le plus proche du clic
   if (clickedTree.getBurningQty() == 0) { // Si l'arbre est sain, allume le feu
     clickedTree.setBurning(1);
     fireStarted = true;
  }  
}

// propage le feu entre les arbres
void propagateFire() {  
  for (tree t : forest){ 
    t.igniteNeighbors(forest); //propage le feu sur les voisins les plus proche
  }
  
  //augmente la quantité de feu sur l'arbre
  for(int i = 0; i< forest.length; i++){
    tree burningTree = closestTree(new PVector(forest[i].position.x, forest[i].position.y)); // récupère chaque arbre en fonction de leur position
    
    if(forest[i].getBurningQty() > 0 ){ // si l'arbre brûle
      if(forest[i].getBurningQty() < forest[i].getQteCombustible() ){ // si l'arbre n'a pas atteint sa limite de carbonisation 
        burningTree.setBurning(burningTree.getBurningQty()+1);
      }
      else{ // sinon carbonisé
        burningTree.setBurning(-1);
      }
    }
  }  
}

// trouve l'arbre le plus près d'un certain point
tree closestTree(PVector startPoint){
  float closest = width;
  tree closestTree = new tree(mouseX, mouseY);
  
  //cherche pour l'arbre le plus près
  for (tree t : forest){
    float distance = PVector.dist(startPoint, t.getPosition());
    if(closest > distance){
      closest = distance;
      closestTree = t;
    }
  }
  return closestTree;
}

// un arbre
class tree {
  PVector position; //position de l'arbre
  float burning; //% de feu
  float qteCombustible; //quantité de "matière" dans l'arbre
  float propagationArea; //zone maximale de transmission du feu
  float fireResistance; //qté de matière à brûler avant de se propager
  float spread; // taille de la zone de transmission du feu
  
  tree (float x, float y, float qteComb, float pa, float res){
    this.position = new PVector(x,y);
    this.burning = 0;
    this.qteCombustible = qteComb;
    this.propagationArea = pa;
    this.fireResistance = res;
    spread = 0;
  }
  
  tree (float x, float y){
    this.position = new PVector(x,y);
  }
  
  // démarre un feu chez les arbres voisins
  void igniteNeighbors(tree[] closestTree) {
    if (this.burning > 0 && this.fireResistance < this.burning) { // si l'arbre brûle et qu'il a dépassé sa résistance au feu
      for (tree t : closestTree) {
        float distance = PVector.dist(this.position, t.getPosition()); // prend la distance entre les deux arbres
        if (distance > 0 && distance < this.spread && t.getBurningQty() == 0) {// si ce pas le même arbre et qu'il est dans la zone de propagation et que l'arbre cible est sain
          t.setBurning(1); // enflammer l'arbre
        }
      }
    }
  }

  PVector getPosition(){return this.position;}
  
  float getBurningQty(){return this.burning;}  
  void setBurning(float b){this.burning = b;}
  
  float getQteCombustible(){return this.qteCombustible;}
  
  float getPropagationArea(){return this.propagationArea;}
  
  float getFireResistance(){return this.fireResistance;}
  
  float getSpread(){return this.spread;}
  void setSpread(float s){this.spread = s;}
  
  String toString(){return this.position+"   "+this.burning+"   "+ this.qteCombustible+"   "+this.fireResistance+"   "+this.propagationArea;}
}
