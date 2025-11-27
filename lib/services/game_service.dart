// services/game_service.dart
import 'package:flutter/foundation.dart';

class GameService with ChangeNotifier {
  int _points = 850;
  int _karma = 245;
  int _currentXP = 150;
  int _maxXP = 300;
  int _currentLevel = 3;

  // Getters
  int get points => _points;
  int get karma => _karma;
  int get currentXP => _currentXP;
  int get maxXP => _maxXP;
  int get currentLevel => _currentLevel;

  // Reward methods
  void rewardItemPost() {
    _points += 2;
    _karma += 1;
    _currentXP += 5; // XP for posting
    _checkLevelUp();
    notifyListeners();
    _logAchievement('Item Posted', '+2 Points, +1 Karma');
  }

  void rewardSuccessfulReturn() {
    _points += 8;
    _karma += 10;
    _currentXP += 25; // XP for successful return
    _checkLevelUp();
    notifyListeners();
    _logAchievement('Successful Return', '+8 Points, +10 Karma');
  }

  void rewardVerifiedClaim() {
    _points += 20;
    _karma += 15;
    _currentXP += 40; // XP for verified claim
    _checkLevelUp();
    notifyListeners();
    _logAchievement('Verified Claim', '+20 Points, +15 Karma');
  }

  void _checkLevelUp() {
    if (_currentXP >= _maxXP) {
      // Level up!
      _currentLevel++;
      _currentXP = _currentXP - _maxXP;
      _maxXP = (_maxXP * 1.2).round(); // Increase XP needed for next level
      
      // You could trigger a level-up celebration here
      if (kDebugMode) {
        print('Level up! Now level $_currentLevel');
      }
    }
  }

  void _logAchievement(String action, String reward) {
    if (kDebugMode) {
      print('$action: $reward | Total: $_points Points, $_karma Karma');
    }
    // TODO: Save to Firebase analytics or local storage
  }
}