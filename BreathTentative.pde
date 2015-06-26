// coded by Yota Odaka
// GitHub: https://github.com/62grow2e/BreathTentative
import processing.video.*;
Capture cap;

int cap_w = 480; // 自由に変えられます
int cap_h = cap_w/16*9;
int fps = 24; // サンプリングする速さ（カメラより早いと解像度が落ちます）

color[][] scannedColors;
PVector[] scanPos = new PVector[cap_h];
int num_buffers = 1000; // どのくらい横につなげるか
int tempBuffer_i = 0;

PGraphics view;
int view_w = num_buffers;
int view_h = cap_h;

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

	scanPixels(); // 中心のピクセルの取得
	updateView(); // empty, true --> 左から右, false --> 右から左
	drawView(0, cap_h); // 取得したピクセルを繋げて描画
	
	drawCapture(width/2, cap_h/2); // キャプチャ描画

	// step buffer index
	tempBuffer_i++;
	tempBuffer_i %= num_buffers;

	// 一周で画像保存
	saveView();
}

// キャプチャの中心一列を取得
void scanPixels(){
	if(tempBuffer_i >= num_buffers)return;
	cap.loadPixels();
	for(int i = 0; i < cap_h; i++){
		int scan_x, scan_y;
		/*** scan_xとscan_yを変えれば取得する色を変えられます ***/
		// capの取得したい座標を scan_x, scan_y に入れます
		
		/*** X中心座標を取得する例 ***/
		scan_x = cap.width/2; // 定義域: (0, cap.width]

		/*** マウスのX座標を取得する例 ***/
		/*
		int mx = (mouseX>width/2 - cap_w/2)? (mouseX>width/2 + cap_w/2)? cap.width: (int)map(mouseX, width/2-cap_w/2, width/2+cap_w/2, 0, cap.width): 1;
		scan_x = int(cap.width-mx);
		*/
		
		scan_y = i*cap.height/cap_h; // 定義域: [0, cap.height)


		// キャプチャから色データを取得する
		scannedColors[tempBuffer_i][i] = cap.get(scan_x, scan_y);
		// 座標を保存する
		scanPos[i].set((float)scan_x/cap.width*cap_w, (float)scan_y/cap.height*cap_h, 0);
	}

}

// キャプチャをアップデートする
void drawCapture(int center_x, int center_y){
	imageMode(CENTER);
	pushMatrix();
	translate(center_x, center_y);
	scale(-1, 1); // 見やすいようにキャプチャを反転
	image(cap, 0, 0, cap_w, cap_h);

	// スキャンしている赤線を引く
	fill(#ff0000);
	noStroke();
	for(PVector p: scanPos){
		rect(p.x - cap_w/2, p.y - cap_h/2, 1, 1);
	}
	popMatrix();
}

// 繋げたものを表示
void drawView(int left_x, int left_y){
	imageMode(CENTER);
	image(view, left_x+view_w/2, left_y+view_h/2);
}

void initView(){
	view = createGraphics(view_w, view_h);
}


// 取得したピクセルを繋げます
// trueか空で 左から右 ,falseで右から左へ
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

// 繋げた画像を保存します
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