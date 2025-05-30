import 'dart:convert';
import 'package:flutter/services.dart';

// Define a GameData class to store structured data
class GameData {
  final String number;
  final String answer;
  final String description;

  GameData({required this.number, required this.answer, required this.description});

  factory GameData.fromJson(Map<String, dynamic> json) {
    return GameData(
      number: json['number'],
      answer: json['answer'],
      description: json['description'] ?? '', // Default to empty string if description is missing
    );
  }
}

class DataService {
  // Method to load game data from assets
  Future<List<GameData>> loadGameData() async {
    try {
      // Try loading from JSON file
      final String jsonString = await rootBundle.loadString('assets/game_data.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      return jsonData.map((item) => GameData.fromJson(item)).toList();
    } catch (e) {
      print('Error loading game data from JSON: $e');

      // Fallback to default data if JSON load fails
      return [
        GameData(number: "29.8%", answer: "RENEWABLE", description: "Global renewable energy"),
        GameData(number: "11 M \n tons", answer: "PLASTIC", description: "Plastic waste in oceans"),
        GameData(number: "4.7 M  \n Hectares", answer: "FOREST", description: "Forest area lost annually"),
        GameData(number: "3.8  \n millimeter", answer: "SEA", description: "Sea level rise per year")
      ];
    }
  }
}