// coded by Yota Odaka
// GitHub: https://github.com/62grow2e/BreathTentative

import processing.video.*;

final int MODE_CENTER = 1;
final int MODE_MOUSEX = 2;
final int MODE_SIN = 3;
//final int MODE_CENTER = 4;


Capture cap;

int cap_w = 480; // you can change
int cap_h = cap_w/16*9;
int fps = 24; // sampling speed

color[][] scannedColors;
PVector[] scanPos = new PVector[cap_h];
int num_buffers = 1000; // width of a jointed view image
int tempBuffer_i = 0; // 

PGraphics view;
int view_w = num_buffers;
int view_h = cap_h;

float t = 0; // this will change while this program is runnning
float dt = 0.5; // speed of t
int mode =  MODE_CENTER;

void setup(){
	background(255);
	frameRate(fps);
	scannedColors = new color[num_buffers][cap_h];
	for(int i = 0; i < scanPos.length; i++){
		scanPos[i] = new PVector(0, 0, 0);
	}

	// select camera which you use
	String[] cameras = Capture.list();
	for(int i = 0; i < cameras.length; i++){
		println(i, cameras[i]);
	}
	cap = new Capture(this, cameras[0]);
	cap.start();
	while(!cap.available())delay(1);

	int window_w = (view_w>cap_w)?view_w: cap_w;
	size(window_w, cap_h+view_h);

	initView();
}

void draw(){
	background(255);
	if(cap.available() == true){
		cap.read();
	}

	updatePixels(); 
	updateView(); // empty, true --> left to right, false --> right to left
	drawView(0, cap_h);
	
	drawCapture(width/2, cap_h/2);

	// step buffer index
	tempBuffer_i++;
	tempBuffer_i %= num_buffers;

	// save a jointed image as jpeg
	saveView();
}

// key events
void keyPressed(){
	if(keyCode == UP){
		dt+=0.1;
		println("dt: "+dt);
	}
	else if(keyCode == DOWN){
		dt-=0.1;
		println("dt: "+dt);
	}
	else if(keyCode == MODE_CENTER+48){
		mode = MODE_CENTER;
		println("mode: ", mode);
	}
	else if(keyCode == MODE_MOUSEX+48){
		mode = MODE_MOUSEX;
		println("mode: ", mode);
	}
	else if(keyCode == MODE_SIN+48){
		mode = MODE_SIN;
		println("mode: ", mode);
	}

}
// get color data according as temporary mode
void updatePixels(){
	if(tempBuffer_i >= num_buffers)return;
	cap.loadPixels();
	for(int i = 0; i < cap_h; i++){
		int scan_x, scan_y;

		switch (mode) {
			case MODE_CENTER :
			default :	
				scan_x = cap.width/2; // defined in (0, cap.width]
			break;

			case MODE_MOUSEX :
				int mx = (mouseX>width/2 - cap_w/2)? (mouseX>width/2 + cap_w/2)? cap.width: (int)map(mouseX, width/2-cap_w/2, width/2+cap_w/2, 0, cap.width): 1;
				scan_x = int(cap.width-mx);	
			break;

			case MODE_SIN :
				scan_x = int((cap.width/2-1)*sin(radians(t))+cap.width/2);
			break;			
		}

		scan_y = i*cap.height/cap_h; // defined in [0, cap.height)

		// get color data
		scannedColors[tempBuffer_i][i] = cap.get(scan_x, scan_y);
		// hold scanned positions
		scanPos[i].set((float)scan_x/cap.width*cap_w, (float)scan_y/cap.height*cap_h, 0);
	}

	t+=dt;
}

// update chapture
void drawCapture(int center_x, int center_y){
	imageMode(CENTER);
	pushMatrix();
	translate(center_x, center_y);
	scale(-1, 1); // mirror image for using easily
	image(cap, 0, 0, cap_w, cap_h);

	// draw red points on scanned positions
	fill(#ff0000);
	noStroke();
	for(PVector p: scanPos){
		rect(p.x - cap_w/2, p.y - cap_h/2, 1, 1);
	}
	popMatrix();
}

// draw a jointed view
void drawView(int left_x, int left_y){
	imageMode(CENTER);
	image(view, left_x+view_w/2, left_y+view_h/2);
}

void initView(){
	view = createGraphics(view_w, view_h);
}


// update a jointed view
void updateView(boolean left2right){
	if(tempBuffer_i >= num_buffers)return;
	view.beginDraw();
	if(left2right){
		for (int i = 0; i < cap_h; i++) {
			view.fill(scannedColors[tempBuffer_i][i]);
			view.noStroke();
			view.rect(tempBuffer_i, i, 1, 1);
		}
	}
	else {
		for (int i = 0; i < cap_h; i++) {
			view.fill(scannedColors[tempBuffer_i][i]);
			view.noStroke();
			view.rect(view_w-1-tempBuffer_i, i, 1, 1);
		}
	}
	view.endDraw();
}
void updateView(){
	updateView(true);
}

// save a jointed view
void saveView(){
	if(tempBuffer_i != 0)return;
	String month = (month()<10)?"0"+str(month()): str(month());
	String day = (day()<10)?"0"+str(day()): str(day());
	String hour = (hour()<10)?"0"+str(hour()): str(hour());
	String minute = (minute()<10)?"0"+str(minute()): str(minute());
	String second = (second()<10)?"0"+str(second()): str(second());

	String filename = "images/breath-"+year()+month+day+hour+minute+second+".jpg";

	view.save(filename);
	println("frame saved as "+filename+".");
}