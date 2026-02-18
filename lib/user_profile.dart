import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  int xp;
  int level;

  UserProfile({this.xp = 0, this.level = 0});

  // XP required for each level
  static int xpForLevel(int level) {
    if (level == 0) return 100;
    if (level == 1) return 150;
    if (level >= 2 && level <= 4) return 250;
    if (level >= 5 && level <= 9) return 500;
    if (level >= 10 && level <= 24) return 750;
    if (level >= 25 && level <= 49) return 1000;
    if (level >= 50 && level <= 74) return 1250;
    if (level >= 75 && level <= 99) return 1500;
    return 1500;
  }

  // Add XP and handle level up
  void addXp(int amount) {
    xp += amount;
    while (xp >= xpForLevel(level)) {
      xp -= xpForLevel(level);
      level++;
    }
  }

  // Remove XP and handle level down if necessary
  void removeXp(int amount) {
    xp -= amount;
    while (xp < 0 && level > 0) {
      level--;
      xp += xpForLevel(level);
    }
    if (xp < 0) xp = 0;
  }

  // Save to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_xp', xp);
    await prefs.setInt('user_level', level);
  }

  // Load from SharedPreferences
  static Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final xp = prefs.getInt('user_xp') ?? 0;
    final level = prefs.getInt('user_level') ?? 0;
    return UserProfile(xp: xp, level: level);
  }
}
