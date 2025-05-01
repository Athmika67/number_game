import 'package:flutter/material.dart';

// Define letter position class at the top level
class LetterPosition {
  final int wordIndex;
  final int letterIndex;

  LetterPosition(this.wordIndex, this.letterIndex);
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      debugShowCheckedModeBanner: false,
      home: NumberMatchingGame(),
    );
  }
}

class NumberMatchingGame extends StatefulWidget {
  @override
  _NumberMatchingGameState createState() => _NumberMatchingGameState();
}

class _NumberMatchingGameState extends State<NumberMatchingGame> {
  final List<Map<String, dynamic>> numberData = [
    {"number": "29.8%", "answer": "RENEWABLE"},
    {"number": "11 M \n tons", "answer": "PLASTIC"},
    {"number": "4.7 M  \n Hectares", "answer": "FOREST"},
    {"number": "3.8  \n millimeter", "answer": "SEA"}
  ];

  // Track active letter positions in a grid format
  List<List<LetterPosition?>> letterGrid = [];

  // Store letter values directly instead of using controllers
  List<List<String>> letterValues = [];

  // Define maximum rows needed (based on longest word)
  int maxRows = 9; // RENEWABLE has 9 letters

  final List<EdgeInsets> numberPaddings = [
    EdgeInsets.only(left: 24.0, top: 28.0),
    EdgeInsets.only(left: 30.0, top: 50.0),
    EdgeInsets.only(left: 20.0, top: 100.0),
    EdgeInsets.only(left: 0.0, top: 150.0),
  ];

  // Track selected letters for swapping
  LetterPosition? firstSelectedPosition;
  int? firstSelectedRow;
  int? firstSelectedCol;

  // Visual feedback variables for selection
  List<List<bool>> selectedCells = [];

  @override
  void initState() {
    super.initState();

    // Initialize letter values storage
    letterValues = List.generate(
        4, // Number of columns (words)
            (i) => List.generate(maxRows, (_) => "")
    );

    // Initialize letter grid with nulls
    letterGrid = List.generate(
        maxRows,
            (_) => List.generate(4, (_) => null)
    );

    // Initialize selected cells tracking
    selectedCells = List.generate(
        maxRows,
            (_) => List.generate(4, (_) => false)
    );

    // Set up the grid layout - initially just arrange letters vertically by word
    for (int wordIndex = 0; wordIndex < numberData.length; wordIndex++) {
      String word = numberData[wordIndex]["answer"];
      for (int letterIndex = 0; letterIndex < word.length; letterIndex++) {
        // Only assign valid letter positions
        if (letterIndex < maxRows) {
          letterGrid[letterIndex][wordIndex] = LetterPosition(wordIndex, letterIndex);
          letterValues[wordIndex][letterIndex] = word[letterIndex];
        }
      }
    }

    // Shuffle the E of RENEWABLE (2nd letter) with P of PLASTIC (1st letter)
    // Save the original positions
    LetterPosition? tempE = letterGrid[1][0]; // E from RENEWABLE (second letter, first column)
    LetterPosition? tempP = letterGrid[0][1]; // P from PLASTIC (first letter, second column)

    // Swap them
    if (tempE != null && tempP != null) {
      letterGrid[1][0] = tempP; // Put P in RENEWABLE's E position
      letterGrid[0][1] = tempE; // Put E in PLASTIC's P position
    }

    // NEW SWAP: Shuffle the N of RENEWABLE (3rd letter) with L of PLASTIC (2nd letter) and F of FOREST (1st letter)
    // Save the original positions
    LetterPosition? tempN = letterGrid[2][0]; // N from RENEWABLE (third letter, first column)
    LetterPosition? tempL = letterGrid[1][1]; // L from PLASTIC (second letter, second column)
    LetterPosition? tempF = letterGrid[0][2]; // F from FOREST (first letter, third column)

    // Swap them in a circular fashion: N -> L -> F -> N
    if (tempN != null && tempL != null && tempF != null) {
      letterGrid[2][0] = tempL; // Put L in RENEWABLE's N position
      letterGrid[1][1] = tempF; // Put F in PLASTIC's L position
      letterGrid[0][2] = tempN; // Put N in FOREST's F position
    }

    // ADDITIONAL SWAP: Shuffle the 4th letter of RENEWABLE, 3rd letter of PLASTIC, 2nd letter of FOREST, and 1st letter of SEA
    // Save the original positions
    LetterPosition? tempW = letterGrid[3][0]; // W from RENEWABLE (fourth letter, first column)
    LetterPosition? tempA = letterGrid[2][1]; // A from PLASTIC (third letter, second column)
    LetterPosition? tempO = letterGrid[1][2]; // O from FOREST (second letter, third column)
    LetterPosition? tempS = letterGrid[0][3]; // S from SEA (first letter, fourth column)

    // Swap them in a circular fashion: W -> A -> O -> S -> W
    if (tempW != null && tempA != null && tempO != null && tempS != null) {
      letterGrid[3][0] = tempA; // Put A in RENEWABLE's W position
      letterGrid[2][1] = tempO; // Put O in PLASTIC's A position
      letterGrid[1][2] = tempS; // Put S in FOREST's O position
      letterGrid[0][3] = tempW; // Put W in SEA's S position
    }

    // ANOTHER SWAP: Shuffle the 5th letter of RENEWABLE, 4th letter of PLASTIC, 3rd letter of FOREST and 2nd letter of SEA
    // Save the original positions
    LetterPosition? tempA2 = letterGrid[4][0]; // A from RENEWABLE (fifth letter, first column)
    LetterPosition? tempS2 = letterGrid[3][1]; // S from PLASTIC (fourth letter, second column)
    LetterPosition? tempR = letterGrid[2][2]; // R from FOREST (third letter, third column)
    LetterPosition? tempE2 = letterGrid[1][3]; // E from SEA (second letter, fourth column)

    // Swap them in a circular fashion: A -> S -> R -> E -> A
    if (tempA2 != null && tempS2 != null && tempR != null && tempE2 != null) {
      letterGrid[4][0] = tempS2; // Put S in RENEWABLE's A position
      letterGrid[3][1] = tempR; // Put R in PLASTIC's S position
      letterGrid[2][2] = tempE2; // Put E in FOREST's R position
      letterGrid[1][3] = tempA2; // Put A in SEA's E position
    }

    // FIFTH SWAP: Shuffle the 6th letter of RENEWABLE, 5th letter of PLASTIC, 4th letter of FOREST and 3rd letter of SEA
    // Save the original positions
    LetterPosition? tempB = letterGrid[5][0]; // B from RENEWABLE (sixth letter, first column)
    LetterPosition? tempT = letterGrid[4][1]; // T from PLASTIC (fifth letter, second column)
    LetterPosition? tempE3 = letterGrid[3][2]; // E from FOREST (fourth letter, third column)
    LetterPosition? tempA3 = letterGrid[2][3]; // A from SEA (third letter, fourth column)

    // Swap them in a circular fashion: B -> T -> E -> A -> B
    if (tempB != null && tempT != null && tempE3 != null && tempA3 != null) {
      letterGrid[5][0] = tempT; // Put T in RENEWABLE's B position
      letterGrid[4][1] = tempE3; // Put E in PLASTIC's T position
      letterGrid[3][2] = tempA3; // Put A in FOREST's E position
      letterGrid[2][3] = tempB; // Put B in SEA's A position
    }

    // SIXTH SWAP: Shuffle the 7th letter of RENEWABLE, 6th letter of PLASTIC and 5th letter of FOREST
    // Save the original positions
    LetterPosition? tempL2 = letterGrid[6][0]; // L from RENEWABLE (seventh letter, first column)
    LetterPosition? tempI = letterGrid[5][1]; // I from PLASTIC (sixth letter, second column)
    LetterPosition? tempS3 = letterGrid[4][2]; // S from FOREST (fifth letter, third column)

    // Swap them in a circular fashion: L -> I -> S -> L
    if (tempL2 != null && tempI != null && tempS3 != null) {
      letterGrid[6][0] = tempI; // Put I in RENEWABLE's L position
      letterGrid[5][1] = tempS3; // Put S in PLASTIC's I position
      letterGrid[4][2] = tempL2; // Put L in FOREST's S position
    }

    // SEVENTH SWAP: Shuffle the 8th letter of RENEWABLE, 7th letter of PLASTIC and 6th letter of FOREST
    // Save the original positions
    LetterPosition? tempE4 = letterGrid[7][0]; // E from RENEWABLE (eighth letter, first column)
    LetterPosition? tempC = letterGrid[6][1]; // C from PLASTIC (seventh letter, second column)
    LetterPosition? tempT2 = letterGrid[5][2]; // T from FOREST (sixth letter, third column)

    // Swap them in a circular fashion: E -> C -> T -> E
    if (tempE4 != null && tempC != null && tempT2 != null) {
      letterGrid[7][0] = tempC; // Put C in RENEWABLE's E position
      letterGrid[6][1] = tempT2; // Put T in PLASTIC's C position
      letterGrid[5][2] = tempE4; // Put E in FOREST's T position
    }

    // Update the letter values with the new arrangement
    updateLetterValuesFromGrid();
  }

  // Update letter values to match the current grid arrangement
  void updateLetterValuesFromGrid() {
    // First clear all values
    for (var i = 0; i < letterValues.length; i++) {
      for (var j = 0; j < letterValues[i].length; j++) {
        letterValues[i][j] = "";
      }
    }

    // Then fill based on the current grid
    for (int row = 0; row < maxRows; row++) {
      for (int col = 0; col < 4; col++) {
        LetterPosition? pos = letterGrid[row][col];
        if (pos != null) {
          String letter = numberData[pos.wordIndex]["answer"][pos.letterIndex];
          letterValues[col][row] = letter;
        }
      }
    }
  }

  // Function to handle letter selection for swapping
  void selectLetter(int row, int col) {
    // Skip if this cell doesn't contain a letter
    if (letterGrid[row][col] == null) return;

    // Determine if this is a fixed position (first or last letter of RENEWABLE)
    LetterPosition? position = letterGrid[row][col];
    if (position != null) {
      bool isFixed = (position.wordIndex == 0 &&
          (position.letterIndex == 0 ||
              position.letterIndex == numberData[0]["answer"].length - 1));

      // Skip fixed letters
      if (isFixed) return;
    }

    setState(() {
      if (firstSelectedPosition == null) {
        // First selection
        firstSelectedPosition = letterGrid[row][col];
        firstSelectedRow = row;
        firstSelectedCol = col;
        selectedCells[row][col] = true;
      } else {
        // Second selection - perform the swap
        final secondSelectedPosition = letterGrid[row][col];

        // Swap the positions in the grid
        letterGrid[firstSelectedRow!][firstSelectedCol!] = secondSelectedPosition;
        letterGrid[row][col] = firstSelectedPosition;

        // Update letter values to reflect the swap
        updateLetterValuesFromGrid();

        // Reset selections
        selectedCells[firstSelectedRow!][firstSelectedCol!] = false;
        firstSelectedPosition = null;
        firstSelectedRow = null;
        firstSelectedCol = null;
      }
    });
  }

  // Fixed method to check if all letters are in the correct positions
  bool areAllLettersCorrect() {
    // For each grid position, check if the letter at that position
    // belongs to the correct word and is in the correct position
    for (int row = 0; row < maxRows; row++) {
      for (int col = 0; col < 4; col++) {
        LetterPosition? pos = letterGrid[row][col];

        // Skip empty cells
        if (pos == null) continue;

        // Get the letter that should be at this position
        String correctLetter = numberData[col]["answer"].length > row
            ? numberData[col]["answer"][row]
            : "";

        // If this position should have a letter (not empty)
        if (correctLetter.isNotEmpty) {
          // Get the actual letter at this position
          String actualLetter = letterValues[col][row];

          // If they don't match, return false
          if (actualLetter != correctLetter) {
            return false;
          }
        }
      }
    }

    return true;
  }

  void submitAnswers() {
    bool allCorrect = areAllLettersCorrect();

    String message = allCorrect
        ? "Congratulations! All answers are correct 🎉"
        : "Oops! Some answers are incorrect. Try again.";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Result"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void resetGame() {
    // Reset to original arrangement with shuffles
    initState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Number Game",
          style: TextStyle(
            color: Colors.blue[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white60,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(numberData.length, (colIndex) {
                  return Padding(
                    padding: colIndex < numberPaddings.length
                        ? numberPaddings[colIndex]
                        : EdgeInsets.only(left: 20.0, top: colIndex * 30.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          numberData[colIndex]["number"],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        SizedBox(height: 4),
                        Icon(Icons.arrow_downward, size: 16, color: Colors.blue[900]),
                        SizedBox(height: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(maxRows, (rowIndex) {
                            LetterPosition? position = letterGrid[rowIndex][colIndex];

                            // Skip rendering if there's no letter at this position
                            if (position == null) {
                              return SizedBox.shrink();
                            }

                            // Determine if this is a fixed position (first or last letter of RENEWABLE)
                            bool isFixed = (position.wordIndex == 0 &&
                                (position.letterIndex == 0 ||
                                    position.letterIndex == numberData[0]["answer"].length - 1));

                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.0),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selectedCells[rowIndex][colIndex]
                                        ? Colors.blue
                                        : (colIndex < numberData.length &&
                                        rowIndex < numberData[colIndex]["answer"].length &&
                                        letterValues[colIndex][rowIndex] == numberData[colIndex]["answer"][rowIndex])
                                        ? Colors.green
                                        : Colors.black,
                                    width: selectedCells[rowIndex][colIndex] ? 3 : 2,
                                  ),
                                  color: isFixed ? Colors.blue[900] : null,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    // Trigger letter selection when tapped
                                    selectLetter(rowIndex, colIndex);
                                  },
                                  child: Center(
                                    child: Text(
                                      letterValues[colIndex][rowIndex],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isFixed ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: submitAnswers,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.blue[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Submit",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: resetGame,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Reset",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              "Tap on letters to swap them!",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            firstSelectedPosition != null
                ? Text(
              "Select another letter to swap...",
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.blue,
              ),
            )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}