import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.video.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class BreathTentative extends PApplet {

// coded by Yota Odaka

Capture cap;

int cap_w = 480; // \u81ea\u7531\u306b\u5909\u3048\u3089\u308c\u307e\u3059
int cap_h = cap_w/16*9;
int fps = 24; // \u30b5\u30f3\u30d7\u30ea\u30f3\u30b0\u3059\u308b\u901f\u3055\uff08\u30ab\u30e1\u30e9\u3088\u308a\u65e9\u3044\u3068\u89e3\u50cf\u5ea6\u304c\u843d\u3061\u307e\u3059\uff09

int[][] scannedColors;
PVector[] scanPos = new PVector[cap_h];
int num_buffers = 1000; // \u3069\u306e\u304f\u3089\u3044\u6a2a\u306b\u3064\u306a\u3052\u308b\u304b
int tempBuffer_i = 0;

PGraphics view;
int view_w = num_buffers;
int view_h = cap_h;

public void setup(){
	background(255);
	frameRate(fps);
	scannedColors = new int[num_buffers][cap_h];
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

	int window_w = (view_w>cap_w)?view_w: cap_w;
	size(window_w, cap_h+view_h);

	initView();
}

public void draw(){
	background(255);
	if(cap.available() == true){
		cap.read();
	}

	updatePixels(); // \u4e2d\u5fc3\u306e\u30d4\u30af\u30bb\u30eb\u306e\u53d6\u5f97
	updateView(); // empty, true --> \u5de6\u304b\u3089\u53f3, false --> \u53f3\u304b\u3089\u5de6
	drawView(0, cap_h); // \u53d6\u5f97\u3057\u305f\u30d4\u30af\u30bb\u30eb\u3092\u7e4b\u3052\u3066\u63cf\u753b
	
	drawCapture(width/2, cap_h/2); // \u30ad\u30e3\u30d7\u30c1\u30e3\u63cf\u753b

	// step buffer index
	tempBuffer_i++;
	tempBuffer_i %= num_buffers;

	// \u4e00\u5468\u3067\u753b\u50cf\u4fdd\u5b58
	saveView();
}

// \u30ad\u30e3\u30d7\u30c1\u30e3\u306e\u4e2d\u5fc3\u4e00\u5217\u3092\u53d6\u5f97
public void updatePixels(){
	if(tempBuffer_i >= num_buffers)return;
	cap.loadPixels();
	for(int i = 0; i < cap_h; i++){
		int scan_x, scan_y;
		/*** scan_x\u3068scan_y\u3092\u5909\u3048\u308c\u3070\u53d6\u5f97\u3059\u308b\u8272\u3092\u5909\u3048\u3089\u308c\u307e\u3059 ***/
		// cap\u306e\u53d6\u5f97\u3057\u305f\u3044\u5ea7\u6a19\u3092 scan_x, scan_y \u306b\u5165\u308c\u307e\u3059
		
		/*** X\u4e2d\u5fc3\u5ea7\u6a19\u3092\u53d6\u5f97\u3059\u308b\u4f8b ***/
		scan_x = cap.width/2; // \u5b9a\u7fa9\u57df: (0, cap.width]

		/*** \u30de\u30a6\u30b9\u306eX\u5ea7\u6a19\u3092\u53d6\u5f97\u3059\u308b\u4f8b ***/
		/*
		int mx = (mouseX>width/2 - cap_w/2)? (mouseX>width/2 + cap_w/2)? cap.width: (int)map(mouseX, width/2-cap_w/2, width/2+cap_w/2, 0, cap.width): 1;
		scan_x = int(cap.width-mx);
		*/

		scan_y = i*cap.height/cap_h; // \u5b9a\u7fa9\u57df: [0, cap.height)


		// \u30ad\u30e3\u30d7\u30c1\u30e3\u304b\u3089\u8272\u30c7\u30fc\u30bf\u3092\u53d6\u5f97\u3059\u308b
		scannedColors[tempBuffer_i][i] = cap.get(scan_x, scan_y);
		// \u5ea7\u6a19\u3092\u4fdd\u5b58\u3059\u308b
		scanPos[i].set((float)scan_x/cap.width*cap_w, (float)scan_y/cap.height*cap_h, 0);
	}
}

// \u30ad\u30e3\u30d7\u30c1\u30e3\u3092\u30a2\u30c3\u30d7\u30c7\u30fc\u30c8\u3059\u308b
public void drawCapture(int center_x, int center_y){
	imageMode(CENTER);
	pushMatrix();
	translate(center_x, center_y);
	scale(-1, 1); // \u898b\u3084\u3059\u3044\u3088\u3046\u306b\u30ad\u30e3\u30d7\u30c1\u30e3\u3092\u53cd\u8ee2
	image(cap, 0, 0, cap_w, cap_h);

	// \u30b9\u30ad\u30e3\u30f3\u3057\u3066\u3044\u308b\u8d64\u7dda\u3092\u5f15\u304f
	fill(0xffff0000);
	noStroke();
	for(PVector p: scanPos){
		rect(p.x - cap_w/2, p.y - cap_h/2, 1, 1);
	}
	popMatrix();
}

// \u7e4b\u3052\u305f\u3082\u306e\u3092\u8868\u793a
public void drawView(int left_x, int left_y){
	imageMode(CENTER);
	image(view, left_x+view_w/2, left_y+view_h/2);
}

public void initView(){
	view = createGraphics(view_w, view_h);
}


// \u53d6\u5f97\u3057\u305f\u30d4\u30af\u30bb\u30eb\u3092\u7e4b\u3052\u307e\u3059
// true\u304b\u7a7a\u3067 \u5de6\u304b\u3089\u53f3 ,false\u3067\u53f3\u304b\u3089\u5de6\u3078
public void updateView(boolean left2right){
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
public void updateView(){
	updateView(true);
}

// \u7e4b\u3052\u305f\u753b\u50cf\u3092\u4fdd\u5b58\u3057\u307e\u3059
public void saveView(){
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
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "BreathTentative" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
