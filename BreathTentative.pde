import processing.video.*;
Capture cap;

int cap_w = 480;
int cap_h = 270;
int fps = 60;
color[][] scannedColors;
int num_buffers = 1000;
int tempBuffer_i = 0;

int view_w = num_buffers;
int view_h = cap_h;

// setupは無視しても大丈夫かなー
void setup(){
	background(255);
	frameRate(fps);
	scannedColors = new color[num_buffers][cap_h];

	String[] cameras = Capture.list();
	for(int i = 0; i < cameras.length; i++){
		println(i, cameras[i]);
	}
	cap = new Capture(this, cameras[0]);
	cap.start();

	size(view_w, cap_h+view_h);
}

void draw(){
	if(cap.available() == true){
		cap.read();
	}

	updatePixels_center(); // ピクセルの取得
	drawView(0, cap_h); // 取得したピクセルを繋げて描画
	drawCapture(width/2, cap_h/2); // キャプチャ描画


	tempBuffer_i++;
	tempBuffer_i %= num_buffers;

	// 一周で画像保存するよ
	if(tempBuffer_i == 0){
		String month = (month()<10)?"0"+str(month()): str(month());
		String day = (day()<10)?"0"+str(day()): str(day());
		String hour = (hour()<10)?"0"+str(hour()): str(hour());
		String minute = (minute()<10)?"0"+str(minute()): str(minute());
		String second = (second()<10)?"0"+str(second()): str(second());

		String filename = "images/breath-"+year()+month+day+hour+minute+second+".jpg";
		saveFrame(filename);
		println("frame saved as "+filename+".");
	}
}

// キャプチャの中心一列を取得
void updatePixels_center(){
	if(tempBuffer_i >= num_buffers)return;
	cap.loadPixels();
	for(int i = 0; i < cap_h; i++){
		// この引数を変更して座標を変えられる
		scannedColors[tempBuffer_i][i] = cap.get(cap.width/2, i*cap.height/cap_h);
	}
	return;
}

// キャプチャをアップデートする
void drawCapture(int center_x, int center_y){
	imageMode(CENTER);
	pushMatrix();
	translate(center_x, center_y);
	scale(-1, 1); // 見やすいようにキャプチャを反転
	image(cap, 0, 0, cap_w, cap_h);

	// スキャンしている赤線を引くところ
	// 適宜変更するよろし
	stroke(#ff0000);
	line(0, -cap_h/2, 0, cap_h/2);
	popMatrix();
}

// スキャンしたものを繋げて左から表示
void drawView(int left_x, int left_y){
	if(tempBuffer_i >= num_buffers)return;
	for(int i = 0; i < cap_h; i++){
		fill(scannedColors[tempBuffer_i][i]);
		noStroke();
		rect(tempBuffer_i+left_x, i+left_y, 1, 1);
	}
}
