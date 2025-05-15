import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Define letter position class at the top level
class LetterPosition {
  final int wordIndex;
  final int letterIndex;

  LetterPosition(this.wordIndex, this.letterIndex);
}

void main() {
  // Add focus handlers to ensure keyboard never shows
  WidgetsFlutterBinding.ensureInitialized();
  SystemChannels.textInput.invokeMethod('TextInput.hide');
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

class _NumberMatchingGameState extends State<NumberMatchingGame> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);

    // Force hide keyboard when app initializes
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    // Initialize selected cells tracking
    selectedCells = List.generate(
        maxRows,
            (_) => List.generate(4, (_) => false)
    );

    // Initialize the game
    initializeGame();
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

  // Check if a letter is in the correct position
  bool isLetterInCorrectPosition(int row, int col) {
    LetterPosition? position = letterGrid[row][col];
    if (position == null) return false;

    // A letter is in correct position if it belongs to this column and is in the right row
    return position.wordIndex == col && position.letterIndex == row;
  }

  // Function to handle letter selection for swapping
  void selectLetter(int row, int col) {
    // Always hide keyboard when selecting a letter
    SystemChannels.textInput.invokeMethod('TextInput.hide');

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

      // NEW: Skip letters that are already in the correct position
      if (isLetterInCorrectPosition(row, col)) return;
    }

    setState(() {
      if (firstSelectedPosition == null) {
        // First selection
        firstSelectedPosition = letterGrid[row][col];
        firstSelectedRow = row;
        firstSelectedCol = col;
        selectedCells[row][col] = true;
      } else {
        // Check if second selected letter is in correct position
        if (isLetterInCorrectPosition(row, col)) {
          // Show a message that this letter can't be swapped
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Letters in the correct position cannot be swapped."),
                duration: Duration(seconds: 2),
              )
          );

          // Reset the first selection
          selectedCells[firstSelectedRow!][firstSelectedCol!] = false;
          firstSelectedPosition = null;
          firstSelectedRow = null;
          firstSelectedCol = null;
          return;
        }

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
    // Hide keyboard
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    setState(() {
      // Clear current selections
      firstSelectedPosition = null;
      firstSelectedRow = null;
      firstSelectedCol = null;

      // Reset selection tracking
      selectedCells = List.generate(
          maxRows,
              (_) => List.generate(4, (_) => false)
      );

      // Reinitialize letter grid and values
      initializeGame();
    });
  }

  // Move initialization logic to a separate method that can be called for reset
  void initializeGame() {
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

    // Save any letters that are already in correct positions before shuffling
    // so they can remain in the correct positions after shuffling
    List<LetterPosition> correctPositions = [];

    // Define letters that should remain in the correct position
    // For this example, let's keep SEA's A (3rd letter) in the correct position
    // Also keep letter combinations you want to remain in correct positions
    // The format is: [row, column]
    List<List<int>> keepInPlace = [
      [2, 3], // SEA's A (3rd letter in 4th column)
      [0, 0], // R of RENEWABLE (already fixed)
      [8, 0], // E of RENEWABLE (already fixed)
    ];

    // Remember these positions to keep them in place
    for (var position in keepInPlace) {
      int row = position[0];
      int col = position[1];
      if (row < maxRows && col < 4 && letterGrid[row][col] != null) {
        correctPositions.add(letterGrid[row][col]!);
      }
    }

    // Shuffle the E of RENEWABLE (2nd letter) with P of PLASTIC (1st letter)
    // Save the original positions
    LetterPosition? tempE = letterGrid[1][0]; // E from RENEWABLE (second letter, first column)
    LetterPosition? tempP = letterGrid[0][1]; // P from PLASTIC (first letter, second column)

    // Swap them if they are not in the keep-in-place list
    if (tempE != null && tempP != null &&
        !correctPositions.contains(tempE) && !correctPositions.contains(tempP)) {
      letterGrid[1][0] = tempP; // Put P in RENEWABLE's E position
      letterGrid[0][1] = tempE; // Put E in PLASTIC's P position
    }

    // NEW SWAP: Shuffle the N of RENEWABLE (3rd letter) with L of PLASTIC (2nd letter) and F of FOREST (1st letter)
    // Save the original positions
    LetterPosition? tempN = letterGrid[2][0]; // N from RENEWABLE (third letter, first column)
    LetterPosition? tempL = letterGrid[1][1]; // L from PLASTIC (second letter, second column)
    LetterPosition? tempF = letterGrid[0][2]; // F from FOREST (first letter, third column)

    // Check if any of these positions should be protected
    bool protectN = correctPositions.contains(tempN);
    bool protectL = correctPositions.contains(tempL);
    bool protectF = correctPositions.contains(tempF);

    // Swap them in a circular fashion but only if not protected
    if (tempN != null && tempL != null && tempF != null) {
      if (!protectL) letterGrid[2][0] = protectL ? tempN : tempL; // Put L in RENEWABLE's N position
      if (!protectF) letterGrid[1][1] = protectF ? tempL : tempF; // Put F in PLASTIC's L position
      if (!protectN) letterGrid[0][2] = protectN ? tempF : tempN; // Put N in FOREST's F position
    }

    // ADDITIONAL SWAP: Shuffle the 4th letter of RENEWABLE, 3rd letter of PLASTIC, 2nd letter of FOREST, and 1st letter of SEA
    // Save the original positions
    LetterPosition? tempW = letterGrid[3][0]; // W from RENEWABLE (fourth letter, first column)
    LetterPosition? tempA = letterGrid[2][1]; // A from PLASTIC (third letter, second column)
    LetterPosition? tempO = letterGrid[1][2]; // O from FOREST (second letter, third column)
    LetterPosition? tempS = letterGrid[0][3]; // S from SEA (first letter, fourth column)

    // Check if any of these positions should be protected
    bool protectW = correctPositions.contains(tempW);
    bool protectA = correctPositions.contains(tempA);
    bool protectO = correctPositions.contains(tempO);
    bool protectS = correctPositions.contains(tempS);

    // Swap them in a circular fashion but only if not protected
    if (tempW != null && tempA != null && tempO != null && tempS != null) {
      if (!protectA) letterGrid[3][0] = protectA ? tempW : tempA; // Put A in RENEWABLE's W position
      if (!protectO) letterGrid[2][1] = protectO ? tempA : tempO; // Put O in PLASTIC's A position
      if (!protectS) letterGrid[1][2] = protectS ? tempO : tempS; // Put S in FOREST's O position
      if (!protectW) letterGrid[0][3] = protectW ? tempS : tempW; // Put W in SEA's S position
    }

    // ANOTHER SWAP: Shuffle the 5th letter of RENEWABLE, 4th letter of PLASTIC, 3rd letter of FOREST and 2nd letter of SEA
    // Save the original positions
    LetterPosition? tempA2 = letterGrid[4][0]; // A from RENEWABLE (fifth letter, first column)
    LetterPosition? tempS2 = letterGrid[3][1]; // S from PLASTIC (fourth letter, second column)
    LetterPosition? tempR = letterGrid[2][2]; // R from FOREST (third letter, third column)
    LetterPosition? tempE2 = letterGrid[1][3]; // E from SEA (second letter, fourth column)

    // Check if any of these positions should be protected
    bool protectA2 = correctPositions.contains(tempA2);
    bool protectS2 = correctPositions.contains(tempS2);
    bool protectR = correctPositions.contains(tempR);
    bool protectE2 = correctPositions.contains(tempE2);

    // Swap them in a circular fashion but only if not protected
    if (tempA2 != null && tempS2 != null && tempR != null && tempE2 != null) {
      if (!protectS2) letterGrid[4][0] = protectS2 ? tempA2 : tempS2; // Put S in RENEWABLE's A position
      if (!protectR) letterGrid[3][1] = protectR ? tempS2 : tempR; // Put R in PLASTIC's S position
      if (!protectE2) letterGrid[2][2] = protectE2 ? tempR : tempE2; // Put E in FOREST's R position
      if (!protectA2) letterGrid[1][3] = protectA2 ? tempE2 : tempA2; // Put A in SEA's E position
    }

    // FIFTH SWAP: Shuffle the 6th letter of RENEWABLE, 5th letter of PLASTIC, 4th letter of FOREST
    // Note: SEA only has 3 letters, so we're not involving it in this swap
    // Save the original positions
    LetterPosition? tempB = letterGrid[5][0]; // B from RENEWABLE (sixth letter, first column)
    LetterPosition? tempT = letterGrid[4][1]; // T from PLASTIC (fifth letter, second column)
    LetterPosition? tempE3 = letterGrid[3][2]; // E from FOREST (fourth letter, third column)
    // No fourth position because SEA only has 3 letters

    // Check if any of these positions should be protected
    bool protectB = correctPositions.contains(tempB);
    bool protectT = correctPositions.contains(tempT);
    bool protectE3 = correctPositions.contains(tempE3);

    // Swap them in a circular fashion but only if not protected
    if (tempB != null && tempT != null && tempE3 != null) {
      if (!protectT) letterGrid[5][0] = protectT ? tempB : tempT; // Put T in RENEWABLE's B position
      if (!protectE3) letterGrid[4][1] = protectE3 ? tempT : tempE3; // Put E in PLASTIC's T position
      if (!protectB) letterGrid[3][2] = protectB ? tempE3 : tempB; // Put B in FOREST's E position
    }

    // SIXTH SWAP: Shuffle the 7th letter of RENEWABLE, 6th letter of PLASTIC and 5th letter of FOREST
    // Save the original positions
    LetterPosition? tempL2 = letterGrid[6][0]; // L from RENEWABLE (seventh letter, first column)
    LetterPosition? tempI = letterGrid[5][1]; // I from PLASTIC (sixth letter, second column)
    LetterPosition? tempS3 = letterGrid[4][2]; // S from FOREST (fifth letter, third column)

    // Check if any of these positions should be protected
    bool protectL2 = correctPositions.contains(tempL2);
    bool protectI = correctPositions.contains(tempI);
    bool protectS3 = correctPositions.contains(tempS3);

    // Swap them in a circular fashion but only if not protected
    if (tempL2 != null && tempI != null && tempS3 != null) {
      if (!protectI) letterGrid[6][0] = protectI ? tempL2 : tempI; // Put I in RENEWABLE's L position
      if (!protectS3) letterGrid[5][1] = protectS3 ? tempI : tempS3; // Put S in PLASTIC's I position
      if (!protectL2) letterGrid[4][2] = protectL2 ? tempS3 : tempL2; // Put L in FOREST's S position
    }

    // SEVENTH SWAP: Shuffle the 8th letter of RENEWABLE, 7th letter of PLASTIC and 6th letter of FOREST
    // Save the original positions
    LetterPosition? tempE4 = letterGrid[7][0]; // E from RENEWABLE (eighth letter, first column)
    LetterPosition? tempC = letterGrid[6][1]; // C from PLASTIC (seventh letter, second column)
    LetterPosition? tempT2 = letterGrid[5][2]; // T from FOREST (sixth letter, third column)

    // Check if any of these positions should be protected
    bool protectE4 = correctPositions.contains(tempE4);
    bool protectC = correctPositions.contains(tempC);
    bool protectT2 = correctPositions.contains(tempT2);

    // Swap them in a circular fashion but only if not protected
    if (tempE4 != null && tempC != null && tempT2 != null) {
      if (!protectC) letterGrid[7][0] = protectC ? tempE4 : tempC; // Put C in RENEWABLE's E position
      if (!protectT2) letterGrid[6][1] = protectT2 ? tempC : tempT2; // Put T in PLASTIC's C position
      if (!protectE4) letterGrid[5][2] = protectE4 ? tempT2 : tempE4; // Put E in FOREST's T position
    }

    // Update the letter values with the new arrangement
    updateLetterValuesFromGrid();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Hide keyboard when metrics change (like when keyboard might appear)
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  @override
  Widget build(BuildContext context) {
    // Force hide keyboard on each build
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    return Scaffold(
      // Disable resizeToAvoidBottomInset to prevent keyboard from pushing up content
      resizeToAvoidBottomInset: false,
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
        // Disable keyboard focus when tapping in the scrollable area
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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

                            // Check if the letter is in the correct position
                            bool isCorrectPosition = isLetterInCorrectPosition(rowIndex, colIndex);

                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.0),
                              child: Material(
                                color: Colors.transparent,
                                shape: CircleBorder(),
                                clipBehavior: Clip.hardEdge,
                                child: InkWell(
                                  onTap: () {
                                    // Hide keyboard and trigger letter selection
                                    FocusScope.of(context).unfocus();
                                    SystemChannels.textInput.invokeMethod('TextInput.hide');
                                    selectLetter(rowIndex, colIndex);
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selectedCells[rowIndex][colIndex]
                                            ? Colors.blue
                                            : Colors.black,
                                        width: selectedCells[rowIndex][colIndex] ? 3 : 2,
                                      ),
                                      color: isFixed || isCorrectPosition ? Colors.blue[900] : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        letterValues[colIndex][rowIndex],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isFixed || isCorrectPosition ? Colors.white : Colors.black,
                                        ),
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
                  onPressed: () {
                    SystemChannels.textInput.invokeMethod('TextInput.hide');
                    submitAnswers();
                  },
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
                  onPressed: () {
                    SystemChannels.textInput.invokeMethod('TextInput.hide');
                    resetGame();
                  },
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
            SizedBox(height: 8),
            Text(
              "Letters in correct position (dark blue) can't be swapped.",
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.blue[700],
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