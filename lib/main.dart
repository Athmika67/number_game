import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data_service.dart'; // Import the data service

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
  // Use the data service
  final DataService _dataService = DataService();
  List<GameData> numberData = [];
  bool isLoading = true;

  // Track active letter positions in a grid format
  List<List<LetterPosition?>> letterGrid = [];

  // Store letter values directly instead of using controllers
  List<List<String>> letterValues = [];

  // Define maximum rows needed (based on longest word)
  int maxRows = 9; // RENEWABLE has 9 letters by default

  final List<EdgeInsets> numberPaddings = [
    EdgeInsets.only(left: 24.0, top: 28.0),
    EdgeInsets.only(left: 30.0, top: 50.0),
    EdgeInsets.only(left: 20.0, top: 98.0),
    EdgeInsets.only(left: 0.0, top: 146.0),
  ];

  // Track selected letters for swapping
  LetterPosition? firstSelectedPosition;
  int? firstSelectedRow;
  int? firstSelectedCol;

  // Visual feedback variables for selection
  List<List<bool>> selectedCells = [];

  // Track completed words and their descriptions
  Set<int> completedWords = Set<int>();
  List<String> shownDescriptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Force hide keyboard when app initializes
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    // Load data from JSON file
    _loadData();
  }

  // Load data from the DataService
  Future<void> _loadData() async {
    try {
      final data = await _dataService.loadGameData();
      setState(() {
        numberData = data;
        isLoading = false;

        // Find the maximum rows needed (based on longest word)
        maxRows = 0;
        for (var item in numberData) {
          if (item.answer.length > maxRows) {
            maxRows = item.answer.length;
          }
        }

        // Initialize selected cells tracking
        selectedCells = List.generate(
            maxRows,
                (_) => List.generate(numberData.length, (_) => false)
        );

        // Initialize the game with the loaded data
        initializeGame();
      });
    } catch (e) {
      print('Error loading data: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load game data. Please try again.')),
      );
    }
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
      for (int col = 0; col < numberData.length; col++) {
        LetterPosition? pos = letterGrid[row][col];
        if (pos != null) {
          String letter = numberData[pos.wordIndex].answer[pos.letterIndex];
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

  // Check if a specific word is completed correctly
  bool isWordCompleted(int wordIndex) {
    String word = numberData[wordIndex].answer;
    for (int letterIndex = 0; letterIndex < word.length; letterIndex++) {
      if (!isLetterInCorrectPosition(letterIndex, wordIndex)) {
        return false;
      }
    }
    return true;
  }

  // Check for newly completed words and show descriptions
  void checkForNewCompletions() {
    Set<int> newlyCompleted = Set<int>();

    for (int wordIndex = 0; wordIndex < numberData.length; wordIndex++) {
      if (isWordCompleted(wordIndex) && !completedWords.contains(wordIndex)) {
        newlyCompleted.add(wordIndex);
        completedWords.add(wordIndex);
      }
    }

    // Show descriptions for newly completed words
    for (int wordIndex in newlyCompleted) {
      showDescriptionDialog(wordIndex);
    }
  }

  // Show description dialog for a completed word
  // Replace your showDescriptionDialog method with this enhanced version

  void showDescriptionDialog(int wordIndex) {
    String number = numberData[wordIndex].number;
    String answer = numberData[wordIndex].answer;
    String description = numberData[wordIndex].description;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, -1),
            end: const Offset(0, 0),
          ).animate(CurvedAnimation(
            parent: anim1,
            curve: Curves.bounceOut,
          )),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[50]!,
                  Colors.purple[50]!,
                  Colors.pink[50]!,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated celebration icon
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 800),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Transform.rotate(
                            angle: value * 0.5,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.yellow[300]!,
                                    Colors.orange[400]!,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.celebration,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 16),

                    // Animated title
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  Colors.purple[600]!,
                                  Colors.blue[600]!,
                                  Colors.teal[600]!,
                                ],
                              ).createShader(bounds),
                              child: Text(
                                "🎉 Amazing! 🎉",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 20),

                    // Word completion info with animated background
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 800),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue[600]!.withOpacity(0.8),
                                  Colors.purple[600]!.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.white, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      "You completed:",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "$number = $answer",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 20),

                    // Description section with fade-in animation
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 1000),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue[200]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: Colors.blue[700], size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Did you know?",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.4,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 24),

                    // Animated button
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 1200),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green[400]!,
                                  Colors.teal[400]!,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(25),
                                onTap: () => Navigator.pop(context),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.thumb_up,
                                          color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        "Awesome!",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Function to handle letter selection for swapping
  void selectLetter(int row, int col) {
    // Always hide keyboard when selecting a letter
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    // Skip if this cell doesn't contain a letter
    if (letterGrid[row][col] == null) return;

    // Determine if this is a fixed position (first or last letter of first word)
    LetterPosition? position = letterGrid[row][col];
    if (position != null) {
      bool isFixed = (position.wordIndex == 0 &&
          (position.letterIndex == 0 ||
              position.letterIndex == numberData[0].answer.length - 1));

      // If we have at least 4 words, also fix last letter of last word like in original code
      if (numberData.length >= 4) {
        int lastWordIndex = numberData.length - 1;
        int lastLetterIndex = numberData[lastWordIndex].answer.length - 1;
        // Add this condition to isFixed
        isFixed = isFixed || (position.wordIndex == lastWordIndex &&
            position.letterIndex == lastLetterIndex);
      }

      // Skip fixed letters
      if (isFixed) return;

      // Skip letters that are already in the correct position
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

        // Check for newly completed words after the swap
        checkForNewCompletions();
      }
    });
  }

  // Fixed method to check if all letters are in the correct positions
  bool areAllLettersCorrect() {
    // For each grid position, check if the letter at that position
    // belongs to the correct word and is in the correct position
    for (int row = 0; row < maxRows; row++) {
      for (int col = 0; col < numberData.length; col++) {
        LetterPosition? pos = letterGrid[row][col];

        // Skip empty cells
        if (pos == null) continue;

        // Get the letter that should be at this position
        String correctLetter = numberData[col].answer.length > row
            ? numberData[col].answer[row]
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
              (_) => List.generate(numberData.length, (_) => false)
      );

      // Reset completed words tracking
      completedWords.clear();
      shownDescriptions.clear();

      // Reinitialize letter grid and values
      initializeGame();
    });
  }

  // Initialize the game with custom letter shuffling logic from the original code
  void initializeGame() {
    // Initialize letter values storage
    letterValues = List.generate(
        numberData.length, // Number of columns (words)
            (i) => List.generate(maxRows, (_) => "")
    );

    // Initialize letter grid with nulls
    letterGrid = List.generate(
        maxRows,
            (_) => List.generate(numberData.length, (_) => null)
    );

    // Set up the grid layout - initially just arrange letters vertically by word
    for (int wordIndex = 0; wordIndex < numberData.length; wordIndex++) {
      String word = numberData[wordIndex].answer;
      for (int letterIndex = 0; letterIndex < word.length; letterIndex++) {
        // Only assign valid letter positions
        if (letterIndex < maxRows) {
          letterGrid[letterIndex][wordIndex] = LetterPosition(wordIndex, letterIndex);
          letterValues[wordIndex][letterIndex] = word[letterIndex];
        }
      }
    }

    // Save any letters that are already in correct positions before shuffling
    List<LetterPosition> correctPositions = [];

    // Define letters that should remain in the correct position
    List<List<int>> keepInPlace = [];

    // Keep first and last letter of first word in place
    if (numberData.isNotEmpty) {
      keepInPlace.add([0, 0]); // First letter of first word
      keepInPlace.add([numberData[0].answer.length - 1, 0]); // Last letter of first word
    }

    // If we have at least 4 words, also fix last letter of last word like in original code
    if (numberData.length >= 4) {
      int lastWordIndex = numberData.length - 1;
      int lastLetterIndex = numberData[lastWordIndex].answer.length - 1;
      if (lastLetterIndex >= 0) {
        keepInPlace.add([lastLetterIndex, lastWordIndex]);
      }
    }

    // If we have the original 4 words, add specific fixed positions from original code
    if (numberData.length == 4 &&
        numberData[0].answer == "RENEWABLE" &&
        numberData[3].answer == "SEA") {
      // Add SEA's A (3rd letter) to fixed positions
      keepInPlace.add([2, 3]); // SEA's A (3rd letter in 4th column)
    }

    // Remember these positions to keep them in place
    for (var position in keepInPlace) {
      int row = position[0];
      int col = position[1];
      if (row < maxRows && col < numberData.length && letterGrid[row][col] != null) {
        correctPositions.add(letterGrid[row][col]!);
      }
    }

    // If we have the original data set, use the specific swapping logic
    if (numberData.length == 4 &&
        numberData[0].answer == "RENEWABLE" &&
        numberData[1].answer == "PLASTIC" &&
        numberData[2].answer == "FOREST" &&
        numberData[3].answer == "SEA") {

      // SWAP 1: Shuffle the E of RENEWABLE (2nd letter) with P of PLASTIC (1st letter)
      _swapIfNotFixed(1, 0, 0, 1, correctPositions);

      // SWAP 2: Shuffle the N of RENEWABLE (3rd letter) with L of PLASTIC (2nd letter) and F of FOREST (1st letter)
      _circularSwapThree([2, 0], [1, 1], [0, 2], correctPositions);

      // SWAP 3: Shuffle the 4th letter of RENEWABLE, 3rd of PLASTIC, 2nd of FOREST, and 1st of SEA
      _circularSwapFour([3, 0], [2, 1], [1, 2], [0, 3], correctPositions);

      // SWAP 4: Shuffle the 5th letter of RENEWABLE, 4th of PLASTIC, 3rd of FOREST and 2nd of SEA
      _circularSwapFour([4, 0], [3, 1], [2, 2], [1, 3], correctPositions);

      // SWAP 5: Shuffle the 6th letter of RENEWABLE, 5th of PLASTIC, 4th of FOREST
      _circularSwapThree([5, 0], [4, 1], [3, 2], correctPositions);

      // SWAP 6: Shuffle the 7th letter of RENEWABLE, 6th of PLASTIC and 5th of FOREST
      _circularSwapThree([6, 0], [5, 1], [4, 2], correctPositions);

      // SWAP 7: Shuffle the 8th letter of RENEWABLE, 7th of PLASTIC and 6th of FOREST
      _circularSwapThree([7, 0], [6, 1], [5, 2], correctPositions);
    }
    else {
      // For other data sets, perform a more generic shuffle
      List<LetterPosition?> allLetters = [];

      // Collect all letter positions except those in correctPositions
      for (int row = 0; row < maxRows; row++) {
        for (int col = 0; col < numberData.length; col++) {
          LetterPosition? pos = letterGrid[row][col];
          if (pos != null && !correctPositions.contains(pos)) {
            allLetters.add(pos);
          }
        }
      }

      // Shuffle the collected letters
      allLetters.shuffle();

      // Place shuffled letters back, skipping positions that should remain fixed
      int letterIndex = 0;
      for (int row = 0; row < maxRows; row++) {
        for (int col = 0; col < numberData.length; col++) {
          // Skip positions that should be kept in place
          bool shouldKeep = false;
          for (var position in keepInPlace) {
            if (position[0] == row && position[1] == col) {
              shouldKeep = true;
              break;
            }
          }

          if (!shouldKeep && letterIndex < allLetters.length && letterGrid[row][col] != null) {
            letterGrid[row][col] = allLetters[letterIndex];
            letterIndex++;
          }
        }
      }
    }

    // Update the letter values with the new arrangement
    updateLetterValuesFromGrid();
  }

  // Helper to swap two specific positions if they're not fixed
  void _swapIfNotFixed(int row1, int col1, int row2, int col2, List<LetterPosition> fixedPositions) {
    LetterPosition? temp1 = letterGrid[row1][col1];
    LetterPosition? temp2 = letterGrid[row2][col2];

    // Only swap if both positions are not null and not in fixed positions
    if (temp1 != null && temp2 != null &&
        !fixedPositions.contains(temp1) && !fixedPositions.contains(temp2)) {
      letterGrid[row1][col1] = temp2;
      letterGrid[row2][col2] = temp1;
    }
  }

  // Helper for circular swapping of three positions
  void _circularSwapThree(List<int> pos1, List<int> pos2, List<int> pos3, List<LetterPosition> fixedPositions) {
    LetterPosition? temp1 = letterGrid[pos1[0]][pos1[1]];
    LetterPosition? temp2 = letterGrid[pos2[0]][pos2[1]];
    LetterPosition? temp3 = letterGrid[pos3[0]][pos3[1]];

    // Check if positions should be protected
    bool protect1 = fixedPositions.contains(temp1);
    bool protect2 = fixedPositions.contains(temp2);
    bool protect3 = fixedPositions.contains(temp3);

    // Swap them in a circular fashion but only if not protected
    if (temp1 != null && temp2 != null && temp3 != null) {
      if (!protect2) letterGrid[pos1[0]][pos1[1]] = protect2 ? temp1 : temp2;
      if (!protect3) letterGrid[pos2[0]][pos2[1]] = protect3 ? temp2 : temp3;
      if (!protect1) letterGrid[pos3[0]][pos3[1]] = protect1 ? temp3 : temp1;
    }
  }

  // Helper for circular swapping of four positions
  void _circularSwapFour(List<int> pos1, List<int> pos2, List<int> pos3, List<int> pos4, List<LetterPosition> fixedPositions) {
    LetterPosition? temp1 = letterGrid[pos1[0]][pos1[1]];
    LetterPosition? temp2 = letterGrid[pos2[0]][pos2[1]];
    LetterPosition? temp3 = letterGrid[pos3[0]][pos3[1]];
    LetterPosition? temp4 = letterGrid[pos4[0]][pos4[1]];

    // Check if positions should be protected
    bool protect1 = fixedPositions.contains(temp1);
    bool protect2 = fixedPositions.contains(temp2);
    bool protect3 = fixedPositions.contains(temp3);
    bool protect4 = fixedPositions.contains(temp4);

    // Swap them in a circular fashion but only if not protected
    if (temp1 != null && temp2 != null && temp3 != null && temp4 != null) {
      if (!protect2) letterGrid[pos1[0]][pos1[1]] = protect2 ? temp1 : temp2;
      if (!protect3) letterGrid[pos2[0]][pos2[1]] = protect3 ? temp2 : temp3;
      if (!protect4) letterGrid[pos3[0]][pos3[1]] = protect4 ? temp3 : temp4;
      if (!protect1) letterGrid[pos4[0]][pos4[1]] = protect1 ? temp4 : temp1;
    }
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

    if (isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFF5F5F7),
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
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
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
                          numberData[colIndex].number,
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

                            // Determine if this is a fixed position (first or last letter of first word)
                            bool isFixed = (position.wordIndex == 0 &&
                                (position.letterIndex == 0 ||
                                    position.letterIndex == numberData[0].answer.length - 1));

                            // If we have at least 4 words, also fix last letter of last word like in original code
                            if (numberData.length >= 4) {
                              int lastWordIndex = numberData.length - 1;
                              int lastLetterIndex = numberData[lastWordIndex].answer.length - 1;
                              isFixed = isFixed || (position.wordIndex == lastWordIndex &&
                                  position.letterIndex == lastLetterIndex);
                            }

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