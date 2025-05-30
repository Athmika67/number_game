class GameItem {
  final String number;
  final String answer;
  final String category;
  final String hint;

  GameItem({
    required this.number,
    required this.answer,
    required this.category,
    required this.hint,
  });

  factory GameItem.fromJson(Map<String, dynamic> json) {
    return GameItem(
      number: json['number'],
      answer: json['answer'],
      category: json['category'],
      hint: json['hint'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'answer': answer,
      'category': category,
      'hint': hint,
    };
  }
}

class GameData {
  final List<GameItem> gameData;

  GameData({required this.gameData});

  factory GameData.fromJson(Map<String, dynamic> json) {
    return GameData(
      gameData: (json['gameData'] as List)
          .map((item) => GameItem.fromJson(item))
          .toList(),
    );
  }
}