class WeatherInteraction {
  final DateTime date;
  final String userWeatherStatus;
  final String? apiWeatherStatus;
  final int points;
  final bool isConsecutiveDay;

  WeatherInteraction({
    required this.date,
    required this.userWeatherStatus,
    this.apiWeatherStatus,
    required this.points,
    this.isConsecutiveDay = false,
  });
}

class UserRanking {
  final String userId;
  final String userName;
  int totalPoints;
  int currentLevel;
  int consecutiveDays;
  final List<WeatherInteraction> interactions;
  final Map<String, int> monthlyPoints;

  UserRanking({
    required this.userId,
    required this.userName,
    this.totalPoints = 0,
    this.currentLevel = 0,
    this.consecutiveDays = 0,
    List<WeatherInteraction>? interactions,
    Map<String, int>? monthlyPoints,
  })  : interactions = interactions ?? [],
        monthlyPoints = monthlyPoints ?? {};

  String get levelName {
    switch (currentLevel) {
      case 0:
        return 'Bronze';
      case 1:
        return 'Prata';
      case 2:
        return 'Ouro';
      case 3:
        return 'Platina';
      default:
        return 'Bronze';
    }
  }

  String get levelEmoji {
    switch (currentLevel) {
      case 0:
        return '🥉';
      case 1:
        return '🥈';
      case 2:
        return '🥇';
      case 3:
        return '💎';
      default:
        return '🥉';
    }
  }

  int get pointsToNextLevel {
    switch (currentLevel) {
      case 0:
        return 21 - totalPoints;
      case 1:
        return 51 - totalPoints;
      case 2:
        return 101 - totalPoints;
      case 3:
        return 0;
      default:
        return 0;
    }
  }
}
