import 'package:flutter/material.dart';

class CrosswordGame extends StatefulWidget {
  @override
  _CrosswordGameState createState() => _CrosswordGameState();
}

class _CrosswordGameState extends State<CrosswordGame> {
  List<List<TextEditingController>> controllers = List.generate(
    3,
        (_) => List.generate(3, (_) => TextEditingController()),
  );

  final List<String> clues = [
    "1. Across (Top Row): A vehicle (3 letters)",
    "2. Down (Middle Column): Opposite of night (3 letters)",
    "3. Across (Bottom Row): A wild animal (3 letters)"
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  @override
  void dispose() {
    for (var row in controllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F5E9), // light green background
      appBar: AppBar(
        backgroundColor: Color(0xFF66BB6A), // theme green
        title: Text("Crossword Game"),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Fill the crossword below:",
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                Table(
                  border: TableBorder.all(),
                  children: List.generate(3, (row) {
                    return TableRow(
                      children: List.generate(3, (col) {
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: TextField(
                            controller: controllers[row][col],
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            decoration: InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ),
                SizedBox(height: 20),
                ...clues.map((clue) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(clue, style: TextStyle(fontSize: 16)),
                )),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Answers submitted!")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF66BB6A),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text("Submit", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
