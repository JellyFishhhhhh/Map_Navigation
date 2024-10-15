import java.util.*; 
import java.util.Map;
import static javax.swing.JOptionPane.*;
import processing.sound.*;

String mapFile = "halifax_map.png", poiFile = "halifax_POI.txt", pinFile = "pin_red.png", originFile = "origin.png",pinFileSelect = "pin_green.png";
SoundFile correct;
float mapX = 0, mapY = 0, mapW = 0, mapH = 0, pinW = 0, pinH = 0, originW = 0, originH = 0, centerX = 345, centerY = 505, f = 25, xShift, yShift;
float scaler = 1;
int drag_shift = 0, shift_index = 0;
boolean has_selection = false, halo_mode = true;
int task = 0, page = 0;
Object[] options = {"Liquor", "Shoppers", "Canada Post", "Chatime"}, sControl = {"Confirm"};
POI task1, task3, task4, task6;
ArrayList<POI> task2, task5;
int task1_err = 0, task2_err = 0, task3_err = 0, task4_err = 0, task5_err = 0, task6_err = 0, start_time, index_of_task6, total_time, index_of_task3;
boolean task1_confirm = false, task2_confirm = false, task3_confirm = false, task4_confirm = false, task5_confirm = false, task6_confirm = false;
Table table;
Random rnd;

PImage map, pin, pinSelect, wedge, origin;
POI o_point;
final Frame frame = Frame.getInstance(this);
color white = color(255, 255, 255), blue = color(20, 40, 59), green = color(45, 170, 0), red = color(230, 74, 58), grey = color(203, 200, 198);
ArrayList<POI> pois;
ArrayList<POI> dists;
ArrayList<Rim> rims;
HashMap<String, Button> bts;
int last_key_pressed = 0, last_screen_pressed = 0;
boolean o_target = false, l_target = false;

void build_POI_list_and_button(){
    int x = 25, y = 1010, w = 100, h = 30, gap = 25; 
    String[] lines = loadStrings(poiFile);
    String category = "";
    for (int i = 0 ; i < lines.length; i++) {
        if(!lines[i].matches(".*\\d.*")){
            category = lines[i];
            if(category.equals("Origin")){
                bts.put(category, new Button(615, 997, category));
            }
            else{
                bts.put(category, new Button(x, y, h, w, category));
                x += gap + w;
            }
        }
        else{
            int[] coordinate = int(split(lines[i], ","));
            if(category.equals("Origin")){
                o_point = new POI(category, coordinate[0], coordinate[1]);
                pois.add(o_point);
            }
            else
                pois.add(new POI(category, coordinate[0], coordinate[1]));
        }
    }
}

void build_rims(){
    rims.add(new Rim(25, 25, 25, 985));      //left
    rims.add(new Rim(25, 985, 665, 985));    //buttom
    rims.add(new Rim(665, 985, 665, 25));    //right
    rims.add(new Rim(25, 25, 665, 25));      //top
}

boolean mouse_in_screen(){
    if(mouseX > 25 && mouseX < 665 && mouseY > 25 && mouseY < 985)
        return true;
    else
        return false;
}

boolean poi_in_screen(POI p){
    float x = p.getX();
    float y = p.getY();
    if(x > 25-xShift && x < 665-xShift && y > 25-yShift && y < 985-yShift)
        return true;
    else
        return false;
}

Button get_button_object(int mouse_x, int mouse_y){
    for(Button b : bts.values()){
        if(b.is_on_button(mouse_x, mouse_y))
            return b;
    }
    return null;
}

PVector line_intersection(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4){
    float uA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
    float uB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
    if(uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1){
        float intersection_X = x1 + (uA * (x2-x1));
        float intersection_Y = y1 + (uA * (y2-y1));
        return new PVector(intersection_X, intersection_Y);
    }
    else
        return null;
}

void show_popup_list(){
    int list_y = 50, row_height = 50;
    String label = "";
    if(l_target){
        fill(white);
        rect(50, 50, 200, dists.size()*row_height);
        for(int i = 0; i < dists.size(); i++){
            label = dists.get(i).getCategory() + "  " + dists.get(i).getDist();
            if(shift_index == i){
                fill(green);
                dists.get(i).w.set_status(true);
            }
            else{
                fill(white);
                dists.get(i).w.set_status(false);
            }
            rect(50, list_y, 200, row_height);
            textAlign(CENTER, CENTER);
            fill(0);
            text(label, 150, list_y+row_height/2);
            list_y+=row_height;
        }
    }
}

void sort_list(){
    POI temp;
    for(int i=0; i<dists.size()-1; i++){
        int min = i;
        for(int j=i+1; j<dists.size(); j++){
            if(dists.get(j).getDist() < dists.get(min).getDist()){
                min = j;
            }
        }
        temp = dists.get(i);
        dists.set(i, dists.get(min));
        dists.set(min, temp);
    }
}

void add_record(int task, String mode, int time, int err_counter){
    TableRow new_row = table.addRow();
    new_row.setInt("Task#", task);
    new_row.setString("Mode", mode);
    new_row.setInt("ElapsedTime", time);
    new_row.setInt("Error#", err_counter);
}

void back_to_origin(){
    xShift = centerX - o_point.getX();
    yShift = centerY - o_point.getY();
}

void mousePressed() {
    last_screen_pressed = millis();
    Button b = get_button_object(mouseX, mouseY);
    if(b!=null){
        if(b.label.equals("Origin")) back_to_origin();
        else b.change_status();
    }
    for(int i=0; i<dists.size(); i++){
        if(dists.get(i).w.is_target(mouseX, mouseY)){
            xShift = centerX - dists.get(i).getX();
            yShift = centerY - dists.get(i).getY();
        }
    }
    if(o_point.is_target(mouseX, mouseY) && mouseButton == RIGHT){
        o_target = true;
    }
    if(o_point.is_target(mouseX, mouseY) && mouseButton == LEFT){
        if(millis()-last_key_pressed > 500  && dists.size() > 0){
            l_target = true;
            has_selection = false;
        }
    }
    if(page == 1 && task1_confirm){
        println(task1);
        for(int i=0; i<dists.size(); i++){
            if(dists.get(i).is_target(mouseX, mouseY)){
                println(dists.get(i));
                if(dists.get(i) == task1){
                    total_time = millis() - start_time;
                    correct.play();
                    add_record(1, "Halo", total_time, task1_err);
                    back_to_origin();
                    page++;
                }
                else task1_err++;
            }
        }
    }
    else if(page == 2 && task2_confirm){
        for(int i=0; i<dists.size(); i++){
            if(dists.get(i).is_target(mouseX, mouseY)){
                if(dists.get(i) == task2.get(0)){task2.remove(0);correct.play();}
                else task2_err++;
            }
        }
        if(task2.size() ==0){
            total_time = millis() - start_time;
            add_record(2, "Halo", total_time, task1_err);
            back_to_origin();
            page++;
        }
    }
    else if(page == 3 && task3_confirm){
        for(int i=0; i<dists.size(); i++){
            if(dists.get(i).is_target(mouseX, mouseY)){
                if(dists.get(i) == task3){
                    correct.play();
                    total_time = millis() - start_time;
                    add_record(3, "Halo", total_time, task3_err);
                    back_to_origin();
                    page++;
                }
                else task3_err++;
            }
        }
    }
    if(page == 4 && task4_confirm){
        for(int i=0; i<dists.size(); i++){
            if(dists.get(i).is_target(mouseX, mouseY)){
                if(dists.get(i) == task4){
                    correct.play();
                    total_time = millis() - start_time;
                    add_record(4, "Wedge", total_time, task1_err);
                    back_to_origin();
                    page++;
                }
                else task4_err++;
            }
        }
    }
    else if(page == 5 && task5_confirm){
        for(int i=0; i<dists.size(); i++){
            if(dists.get(i).is_target(mouseX, mouseY)){
                if(dists.get(i) == task5.get(0)) {task5.remove(0);correct.play();}
                else task5_err++;
            }
        }
        if(task5.size() == 0){
            total_time = millis() - start_time;
            add_record(5, "Wedge", total_time, task1_err);
            back_to_origin();
            page++;
        }
    }
    else if(page == 6 && task6_confirm){
        for(int i=0; i<dists.size(); i++){
            if(dists.get(i).is_target(mouseX, mouseY)){
                if(dists.get(i) == task6){
                    correct.play();
                    total_time = millis() - start_time;
                    add_record(6, "Wedge", total_time, task6_err);
                    back_to_origin();
                    page++;
                }
                else task6_err++;
            }
        }
    }
}

void mouseDragged() {
    if(o_target){
        o_point.set_X_shift(mouseX-pmouseX);
        o_point.set_Y_shift(mouseY-pmouseY);
        if(dists.size()>0)
            dists.get(shift_index).w.set_status(false);
        has_selection = false;
    }
    else if(l_target){
        drag_shift+=(mouseY-pmouseY);
        if(dists.size() != 0)
            shift_index = (drag_shift/40)%dists.size();
    }
    else{
        if(mouse_in_screen() && (mouseButton == RIGHT) && !o_point.is_target(mouseX, mouseY)){
            xShift += (mouseX - pmouseX)*2;
            yShift += (mouseY - pmouseY)*2;
        }
        if(mouse_in_screen() && (mouseButton == LEFT) && !o_point.is_target(mouseX, mouseY)){
            xShift += mouseX - pmouseX;
            yShift += mouseY - pmouseY;
        }
        xShift = constrain(xShift, scaler * (width - mapW), 0);
        yShift = constrain(yShift, scaler * (height - mapH), 0);
    }
}

void mouseReleased() {
    if(l_target){
        l_target = false;
        has_selection = true;
    }
    o_target = false;
    drag_shift = 0;
    shift_index = 0;
}

void keyPressed(){
    last_key_pressed = millis();
    if(keyCode == TAB){
        halo_mode = !halo_mode;
    }
    if(key == 'a'){
        o_point.set_X_shift(-10);
        if(millis()-last_key_pressed > 200)
            o_point.set_X_shift(-(millis()-last_key_pressed)/20);
    }
    if(key == 's'){
        o_point.set_Y_shift(10);
        if(millis()-last_key_pressed > 200)
            o_point.set_X_shift((millis()-last_key_pressed)/20);
    }
    if(key == 'd'){
        o_point.set_X_shift(10);
        if(millis()-last_key_pressed > 200)
            o_point.set_X_shift((millis()-last_key_pressed)/20);
    }
    if(key == 'w'){
        o_point.set_Y_shift(-10);
        if(millis()-last_key_pressed > 200)
            o_point.set_Y_shift(-(millis()-last_key_pressed)/20);
    }
    if(dists.size()>0)
        dists.get(shift_index).w.set_status(false);
    has_selection = false;
}

void setup() {
    size(690, 1060);
    background(white);
    map = loadImage(mapFile);
    pin = loadImage(pinFile);
    pinSelect = loadImage(pinFileSelect);
    origin = loadImage(originFile);
    correct = new SoundFile(this, "Windows Ding.wav");
    pois = new ArrayList<POI>();
    bts = new HashMap<String, Button>();
    rims = new ArrayList<Rim>();
    dists = new ArrayList<POI>();
    rnd = new Random();
    task2 = new ArrayList<POI>();
    task5 = new ArrayList<POI>();

    build_POI_list_and_button();
    build_rims();

    mapW = map.width;
    mapH = map.height;
    pinW = pin.width;
    pinH = pin.height;
    originW = origin.width;
    originH = origin.height;
    xShift = centerX - o_point.getX();
    yShift = centerY - o_point.getY();

    table = new Table();
    table.addColumn("Task#");
    table.addColumn("Mode");
    table.addColumn("ElapsedTime");
    table.addColumn("Error#");
}

void draw() {
    if(page == 0){
        int uChoice = showOptionDialog(null, "Please select one of four categories below and start testing.\nTask 1-3 Mode 1.\nTask 4-6 Mode 2.", "Select Category" , DEFAULT_OPTION, PLAIN_MESSAGE, null, options, options[0]);
        if(uChoice == 0) bts.get("NS Liquor").change_status();
        else if(uChoice == 1) bts.get("Shoppers").change_status();
        else if(uChoice == 2) bts.get("Canada Post").change_status();
        else if(uChoice == 3) bts.get("Chatime").change_status();
        halo_mode = true;
        page++;
    }
    else if(page == 1 && !task1_confirm){
        sort_list();
        int uChoice = showOptionDialog(null, "Please select the cloest POI away from the origin point.(Mode 1)", "Task 1" , DEFAULT_OPTION, PLAIN_MESSAGE, null, sControl, sControl[0]);
        if(uChoice == 0){
            task1 = dists.get(0);
            task1_confirm = true;
            halo_mode = true;
            start_time = millis();
        }
        println(start_time);
    }
    else if(page == 2 && !task2_confirm){
        int uChoice = showOptionDialog(null, "Please select all POIs from cloest to furthest.(Mode 1)", "Task 2" , DEFAULT_OPTION, PLAIN_MESSAGE, null, sControl, sControl[0]);
        if(uChoice == 0){
            // task2 = dists.clone();
            for(int i = 0; i < dists.size(); i++)
                task2.add(dists.get(i));
            task2_confirm = true;
            halo_mode = true;
            start_time = millis();
        }
    }
    else if(page == 3 && !task3_confirm){
        Random rnd = new Random();
        index_of_task3 = rnd.nextInt(dists.size()-1);
        int uChoice = showOptionDialog(null, "Please select the certain POI with the distance of " + dists.get(index_of_task3).getDist() + ".(Mode 1)", "Task 3" , DEFAULT_OPTION, PLAIN_MESSAGE, null, sControl, sControl[0]);
        if(uChoice == 0){
            task3 = dists.get(index_of_task3);
            task3_confirm = true;
            halo_mode = true;
            start_time = millis();
        }
    }
    else if(page == 4 && !task4_confirm){
        int uChoice = showOptionDialog(null, "Please select the cloest POI away from the origin point.(Mode 2)", "Task 4" , DEFAULT_OPTION, PLAIN_MESSAGE, null, sControl, sControl[0]);
        if(uChoice == 0){
            task4 = dists.get(0);
            task4_confirm = true;
            halo_mode = false;
            start_time = millis();
        }
    }
    else if(page == 5 && !task5_confirm){
        int uChoice = showOptionDialog(null, "Please select all POIs from cloest to furthest.(Mode 2)", "Task 5" , DEFAULT_OPTION, PLAIN_MESSAGE, null, sControl, sControl[0]);
        if(uChoice == 0){
            for(int i = 0; i < dists.size(); i++)
                task5.add(dists.get(i));
            task5_confirm = true;
            halo_mode = false;
            start_time = millis();
        }
    }
    else if(page == 6 && !task6_confirm){
        index_of_task6 = rnd.nextInt(dists.size()-1);
        int uChoice = showOptionDialog(null, "Please select the certain POI with the distance of " + dists.get(index_of_task3).getDist() + ".(Mode 2)", "Task 6" , DEFAULT_OPTION, PLAIN_MESSAGE, null, sControl, sControl[0]);
        if(uChoice == 0){
            task6 = dists.get(index_of_task6);
            task6_confirm = true;
            start_time = millis();
        }
    }
    else if(page == 7){
        showMessageDialog(null, "Results saved in the same directory", "Info", INFORMATION_MESSAGE);
        String fileName = rnd.nextInt()+"_output.csv";
        saveTable(table, fileName);
        exit();
    }
    if(get_button_object(mouseX, mouseY) != null)
        cursor(HAND);
    else if(mouse_in_screen())
        cursor(MOVE);
    else
        cursor(ARROW);
    background(white);
    pushMatrix();
    translate(-xShift/2, -yShift/2);
    scale(scaler);
    translate(+xShift/2, +yShift/2);
    image(map, mapX + xShift, mapY + yShift, mapW, mapH);
    for(int i = 0; i < pois.size(); i++){
        POI p = pois.get(i);
        p.update_intersection();
        p.update_dist();
        if(p.w != null)
            p.w.update_position();
        p.display();
    }
    popMatrix();
    frame.display();
    for(Button b : bts.values())
        b.display();
    //added
    if(halo_mode == false)
        show_popup_list();
}

static class Frame{
    private static Frame inst;
    private static PApplet p;
    private Frame(){}
    static Frame getInstance(PApplet papp){
        if(inst == null){
            inst = new Frame();
            p = papp;
        }
        return inst;
    }
    void display(){
        p.fill(255);
        p.noStroke();
        p.rect(0, 0, 690, 25);
        p.rect(0, 0, 25, 1060);
        p.rect(665, 0, 690, 1060);
        p.rect(0, 985, 690, 1060);
        p.fill(255, 0);
        p.stroke(0);
        p.rect(25, 25, 640, 960);
    }
}

class POI{
    String category;
    int index;
    float r;
    float dist;
    PVector point;
    PVector intersection;
    Wedge w;

    POI(String category, int x, int y){
        this.category = category;
        this.point = new PVector(x, y);
        this.intersection = new PVector(x, y);
        this.index = 0;
        this.r = 0;
        this.dist = 0;
        if(category.equals("Origin"))
            w = null;
        else
            w = new Wedge(point, o_point.getVector());
    }

    float getX(){return point.x;}

    float getY(){return point.y;}

    float getDist(){return dist;}
    
    void setIndex(int in){index = in;}

    String getCategory(){return category;}

    float get_inter_X(){return intersection.x;}

    float get_inter_Y(){return intersection.y;}

    void update_dist(){dist = sqrt(pow((this.getX()-o_point.getX()),2) + pow((this.getY()-o_point.getY()), 2));}

    int getIndex(){return index;}

    PVector getVector(){return point;}

    void set_X_shift(float x_shift){point.x+=x_shift;}

    void set_Y_shift(float y_shift){point.y+=y_shift;}

    void update_intersection(){
        for(int i = 0; i < rims.size(); i++){
            Rim rim = rims.get(i);
            PVector p = line_intersection(o_point.getX(), o_point.getY(), this.getX(), this.getY(), rim.getV1X(), rim.getV1Y(), rim.getV2X(), rim.getV2Y());
            if(p!=null){
                intersection = p;
                fill(red);
                noStroke();
                r = sqrt(pow((this.getX()-this.get_inter_X()),2)+pow((this.getY()-this.get_inter_Y()), 2))*2 + 50;
                break;
            }
        }
    }

    void display(){
        if(category.equals("Origin"))
            image(origin, this.getX()+xShift - originW/2, this.getY()+yShift - originH/2);
        if(bts.get(category).status == 1){
            if(poi_in_screen(this)){
                if(w.selected)
                    image(pinSelect, this.getX()+xShift - pinW/2, this.getY()+yShift - pinH);
                else
                    image(pin, this.getX()+xShift - pinW/2, this.getY()+yShift - pinH);
            }
            else if(halo_mode){
                noFill();
                stroke(red);
                ellipseMode(CENTER);
                ellipse(point.x+xShift, point.y+yShift, r, r);
            }
            if(((has_selection && w.selected) || !has_selection) && !halo_mode)
                w.display();
        }
    }

    boolean is_target(float x, float y){
        if(category.equals("Origin")){
            if(x-xShift > this.getX()-originW/2 && x-xShift < this.getX()+originW/2 && y-yShift > this.getY()-originH/2 && y-yShift < this.getY()+originH/2)
                return true;
            else
                return false;
        }
        else {
            if(x-xShift > this.getX()-pinW && x-xShift < this.getX()+pinW && y-yShift > this.getY()-pinH && y-yShift < this.getY()+pinH)
                return true;
            else
                return false;
        }
    }
}

class Button{
    int x, y, h, w, status;
    String label;
    Button(int x, int y, int h, int w, String label){
        this.x = x;
        this.y = y;
        this.h = h;
        this.w = w;
        this.status = 0;    //0:inactive  1:active
        this.label = label;
    }

    Button(int x, int y, String label){
        this.x = x;
        this.y = y;
        this.h = 50;
        this.w = 50;
        this.status = 0;
        this.label = label;
    }

    void display(){
        if(label.equals("Origin")){
            image(origin, x, y);
        }
        else{
            if(status == 0)
                fill(blue);
            else
                fill(green);
            rect(x, y, w, h);
            fill(white);
            textAlign(CENTER, CENTER);
            text(label, x+w/2, y+h/2);
        }
    }
    
    boolean is_on_button(int mouse_x, int mouse_y){
        if(mouse_x > x && mouse_x < x+w && mouse_y > y && mouse_y < y+h)
            return true;
        else
            return false;
    }

    void change_status(){
        status = (status+1)%2;
        if(status == 1){
            for(int i = 0; i < pois.size(); i++){
                if(pois.get(i).getCategory().equals(this.label))
                    dists.add(pois.get(i));
            }
            sort_list();
            // println("Add: ",dists.size());
        }
        else{
            for(int i = 0; i < pois.size(); i++){
                if(pois.get(i).getCategory().equals(this.label))
                    dists.remove(pois.get(i));
            }
            sort_list();
            // println("Remove: ",dists.size());
        }
    }
}

class Rim{
    PVector v1, v2;
    Rim(int x1, int y1, int x2, int y2){
        v1 = new PVector(x1, y1);
        v2 = new PVector(x2, y2);
    }
    float getV1X(){return v1.x-xShift;}
    float getV1Y(){return v1.y-yShift;}
    float getV2X(){return v2.x-xShift;}
    float getV2Y(){return v2.y-yShift;}
}

class Wedge{
    PVector t1;
    PVector t2;
    PVector p1;
    PVector p2;
    PVector p3;
    float z;
    float d;
    float l;
    float h;
    float c;
    float r1;
    float r2;
    boolean selected;
    Wedge(PVector t1, PVector t2){
        this.t1 = t1;
        this.t2 = t2;
        this.c = 100;
        this.r1 = 30;
        this.r2 = 80;
        this.z = calculate_z();
        this.p1 = calculate_p1();
        this.d = calculate_d();
        this.l = calculate_l();
        this.h = calculate_h();
        this.p2 = calculate_p2();
        this.p3 = calculate_p3();
        this.selected = false;
    }

    float calculate_z(){return sqrt(pow((t2.x - t1.x), 2) + pow((t2.y - t1.y), 2));}

    float calculate_d(){return sqrt(pow((t2.x - p1.x), 2) + pow((t2.y - p1.y), 2));}

    float calculate_l(){return (pow(r1, 2) - pow(r2, 2) + pow(d, 2))/(2*d);}

    float calculate_h(){return sqrt((pow(r1, 2) - pow(l, 2)));}

    PVector calculate_p1(){
        float x = t2.x - (t2.x - t1.x)*c/z;
        float y = t2.y - (t2.y - t1.y)*c/z;
        return new PVector(x, y);
    }
    PVector calculate_p2(){
        float x = l*(t2.x - p1.x)/d + h*(t2.y - p1.y)/d + p1.x;
        float y = l*(t2.y - p1.y)/d - h*(t2.x - p1.x)/d + p1.y;
        return new PVector(x, y);
    }
    PVector calculate_p3(){
        float x = l*(t2.x - p1.x)/d - h*(t2.y - p1.y)/d + p1.x;
        float y = l*(t2.y - p1.y)/d + h*(t2.x - p1.x)/d + p1.y;
        return new PVector(x, y);
    }

    void set_status(boolean s){this.selected = s;}

    void update_position(){
        this.t2 = o_point.getVector();
        this.z = calculate_z();
        this.p1 = calculate_p1();
        this.d = calculate_d();
        this.l = calculate_l();
        this.h = calculate_h();
        this.p2 = calculate_p2();
        this.p3 = calculate_p3();
    }

    boolean is_target(float px, float py){

        px -= xShift;
        py -= yShift;
        
        // println(px, py, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);

        float areaOrig = abs((p2.x - p1.x) * (p3.y - p1.y) - (p3.x-p1.x)*(p2.y-p1.y));

        // get the area of 3 triangles made between the point
        // and the corners of the triangle
        float area1 = abs( (p1.x-px)*(p2.y-py) - (p2.x-px)*(p1.y-py) );
        float area2 = abs( (p2.x-px)*(p3.y-py) - (p3.x-px)*(p2.y-py) );
        float area3 = abs( (p3.x-px)*(p1.y-py) - (p1.x-px)*(p3.y-py) );

        // if the sum of the three areas equals the original,
        // we're inside the triangle!
        if (area1 + area2 + area3 == areaOrig) {
            return true;
        }
        return false;
    }

    void display(){
        if(!selected){noStroke(); fill(red);}
        else{noStroke(); fill(green);}
        triangle(p1.x+xShift, p1.y+yShift, p2.x+xShift, p2.y+yShift, p3.x+xShift, p3.y+yShift);
    }
}
