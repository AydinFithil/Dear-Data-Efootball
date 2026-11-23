// Dear Data 100: my eFootball matches
// Every ball is ONE match, and every ball is an OBJECT made from the Match class.
// The balls drop into a tower for the day they were played.
//   Colour = result (green = win, yellow = draw, red = loss)
//   Size   = mood after the match (press G to size by goals scored instead)
// Move the mouse over a ball to see its details.

Table table;                                          // my data from matches.csv
ArrayList<Match> matches = new ArrayList<Match>();    // all of my Match objects
ArrayList<String> days = new ArrayList<String>();     // each different day, in order
int[] dayCounts;                                      // how many matches on each day

boolean sizeByMood = true;                            // true = size by mood, false = by goals
color winColor, drawColor, lossColor;
int wins = 0;
int draws = 0;
int losses = 0;

float margin = 80;
float baselineY = 615;                                // the line the towers stand on
float rowStep = 21;                                   // height of one ball slot in a tower



// The Match class for one ball
class Match {
  // the data for this match
  int matchNo;
  String date;
  int goalsFor;
  int goalsAgainst;
  String result;
  int mood;

  // how the ball is drawn
  float x;            
  float targetY;      
  float y;            
  float diameter;     
  int dropFrame;      

  
  Match(int matchNo, String date, int goalsFor, int goalsAgainst, String result, int mood) {
    this.matchNo = matchNo;
    this.date = date;
    this.goalsFor = goalsFor;
    this.goalsAgainst = goalsAgainst;
    this.result = result;
    this.mood = mood;
    restartDrop();
  }

  void restartDrop() {
    y = -20;                              // start above the top of the window
    diameter = 0;
    dropFrame = frameCount + matchNo * 2; // balls fall in the order they were played
  }

  void place(float x, float targetY) {
    this.x = x;
    this.targetY = targetY;
  }


  int goalDifference() {
    return goalsFor - goalsAgainst;
  }

  
  String differenceText() {
    int diff = goalDifference();
    if (diff > 0) {
      return "+" + diff;
    } else {
      return "" + diff;
    }
  }

  // returns the colour for this match's result
  color resultColor() {
    if (result.equals("Win")) {
      return winColor;
    } else if (result.equals("Loss")) {
      return lossColor;
    } else {
      return drawColor;
    }
  }

  
  float targetDiameter() {
    if (sizeByMood) {
      return map(mood, 1, 5, 7, 20);
    } else {
      return map(goalsFor, 0, 10, 5, 20);
    }
  }

  // returns true if the mouse is over this ball
  boolean isMouseOver() {
    return dist(mouseX, mouseY, x, y) < max(diameter / 2, 8);
  }

  // returns the lines of text shown when you hover over this ball
  String[] infoLines() {
    String[] lines = new String[3];
    lines[0] = "Match " + matchNo + "  |  " + date;
    lines[1] = result + ": " + goalsFor + " - " + goalsAgainst + "  (goal difference " + differenceText() + ")";
    lines[2] = "Mood after: " + mood + " / 5";
    return lines;
  }

  // moves the ball a little closer to where it should be
  void update() {
    if (frameCount >= dropFrame) {
      y = lerp(y, targetY, 0.08);
    }
    diameter = lerp(diameter, targetDiameter(), 0.1);
  }

  // draws the ball
  void display(boolean hovered) {
    noStroke();
    fill(resultColor());
    ellipse(x, y, diameter, diameter);
    if (hovered) {
      noFill();
      stroke(255);
      strokeWeight(2);
      ellipse(x, y, diameter + 8, diameter + 8);
      noStroke();
    }
  }
}



void setup() {
  size(1200, 690);
  winColor = color(70, 200, 110);
  drawColor = color(245, 200, 50);
  lossColor = color(235, 80, 80);

  table = loadTable("matches.csv", "header");
  loadMatches();
  layoutMatches();
}

void draw() {
  background(18, 22, 36);
  drawHeader();
  drawBaseline();

  // update every ball and find out which one (if any) the mouse is over
  Match hovered = null;
  for (Match m : matches) {
    m.update();
    if (m.isMouseOver()) {
      hovered = m;
    }
  }

  // draw every ball, then the hovered one on top
  for (Match m : matches) {
    if (m != hovered) {
      m.display(false);
    }
  }
  if (hovered != null) {
    hovered.display(true);
    drawTooltip(hovered);
  }

  drawLegend();
}

// reads each row of the table and makes one Match object for it
void loadMatches() {
  for (TableRow row : table.rows()) {
    String result = row.getString(5);
    if (result == null || result.trim().length() == 0) {
      continue;                                       // skip blank rows
    }
    result = result.trim();

    int matchNo = row.getInt(0);
    String date = row.getString(1).trim();
    int goalsFor = row.getInt(3);
    int goalsAgainst = row.getInt(4);
    int mood = row.getInt(6);

    Match m = new Match(matchNo, date, goalsFor, goalsAgainst, result, mood);
    matches.add(m);

    if (days.indexOf(date) == -1) {
      days.add(date);                                
    }
    if (result.equals("Win")) {
      wins++;
    } else if (result.equals("Loss")) {
      losses++;
    } else {
      draws++;
    }
  }
}

// works out where each ball belongs: column = its day, height = how many came before it that day
void layoutMatches() {
  dayCounts = new int[days.size()];
  float colWidth = (width - 2 * margin) / days.size();
  for (Match m : matches) {
    int d = days.indexOf(m.date);
    float x = margin + d * colWidth + colWidth / 2;
    float y = baselineY - dayCounts[d] * rowStep - rowStep / 2;
    m.place(x, y);
    dayCounts[d]++;
  }
}

void keyPressed() {
  if (key == 'g' || key == 'G') {
    sizeByMood = false;
  }
  if (key == 'm' || key == 'M') {
    sizeByMood = true;
  }
  if (key == 'r' || key == 'R') {
    for (Match m : matches) {
      m.restartDrop();
    }
  }
}


void drawHeader() {
  textAlign(LEFT, BASELINE);
  fill(255);
  textSize(26);
  text("Dear Data 100: my eFootball matches", margin, 36);
  fill(190, 200, 225);
  textSize(14);
  text(matches.size() + " matches, " + days.get(0) + " to " + days.get(days.size() - 1), margin, 58);
  fill(150, 160, 185);
  textSize(12);
  text("Each ball is one match. Colour = result. Hover over a ball for details.   Keys:  M = size by mood,  G = size by goals scored,  R = replay the drop", margin, 78);
}

void drawBaseline() {
  stroke(70, 80, 110);
  strokeWeight(1);
  line(margin - 10, baselineY, width - margin + 10, baselineY);
  noStroke();

  textAlign(CENTER, BASELINE);
  textSize(12);
  float colWidth = (width - 2 * margin) / days.size();
  for (int i = 0; i < days.size(); i++) {
    float x = margin + i * colWidth + colWidth / 2;
    fill(190, 200, 225);
    text(days.get(i), x, baselineY + 22);                                  // the day
    fill(120, 130, 160);
    text("" + dayCounts[i], x, baselineY - dayCounts[i] * rowStep - 8);    // matches that day
  }
}

void drawTooltip(Match m) {
  String[] lines = m.infoLines();
  textSize(13);
  textAlign(LEFT, TOP);

  float boxWidth = 0;
  for (int i = 0; i < lines.length; i++) {
    boxWidth = max(boxWidth, textWidth(lines[i]));
  }
  boxWidth = boxWidth + 20;
  float boxHeight = lines.length * 18 + 14;

  float bx = constrain(mouseX + 16, 8, width - boxWidth - 8);
  float by = constrain(mouseY + 16, 8, height - boxHeight - 8);

  stroke(m.resultColor());
  strokeWeight(2);
  fill(30, 36, 60);
  rect(bx, by, boxWidth, boxHeight, 6);

  noStroke();
  fill(255);
  for (int i = 0; i < lines.length; i++) {
    text(lines[i], bx + 10, by + 8 + i * 18);
  }
}

void drawLegend() {
  float y = height - 22;
  float x = margin;
  textAlign(LEFT, CENTER);
  textSize(13);
  noStroke();

  fill(winColor);
  ellipse(x, y, 14, 14);
  fill(255);
  text("Win  " + wins, x + 14, y);

  x = x + 110;
  fill(drawColor);
  ellipse(x, y, 14, 14);
  fill(255);
  text("Draw  " + draws, x + 14, y);

  x = x + 110;
  fill(lossColor);
  ellipse(x, y, 14, 14);
  fill(255);
  text("Loss  " + losses, x + 14, y);

  x = x + 130;
  if (sizeByMood) {
    text("Ball size = mood after the match (1 to 5)", x, y);
  } else {
    text("Ball size = goals scored", x, y);
  }
}
