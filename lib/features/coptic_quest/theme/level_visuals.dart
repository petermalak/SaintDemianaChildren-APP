import 'package:flutter/material.dart';

/// Emoji & color helpers for child-friendly visuals (no image assets required).
class LevelVisuals {
  static const _levelEmojis = {
    'bible_001': '🌍',
    'bible_002': '🌈',
    'bible_003': '⭐',
    'bible_004': '🎨',
    'bible_005': '🔥',
    'bible_006': '👶',
    'bible_007': '✨',
    'bible_008': '✝️',
  };

  static const _stickerEmojis = {
    'creation_icon': '🌍',
    'noah_icon': '🌈',
    'abraham_icon': '⭐',
    'joseph_icon': '🎨',
    'moses_icon': '🔥',
    'nativity_icon': '👶',
    'miracles_icon': '✨',
    'resurrection_icon': '🕊️',
  };

  static const _slideEmojis = {
    'bible_001': ['🌌', '💡', '🦁', '😊'],
    'bible_002': ['☁️', '🌧️', '🚢', '🌈'],
    'bible_003': ['🏕️', '⭐', '🐑', '🙏'],
    'bible_004': ['👕', '🕳️', '👑', '🤝'],
    'bible_005': ['👶', '🌊', '📜', '🗻'],
    'bible_006': ['⭐', '🐴', '🐑', '👶'],
    'bible_007': ['🍞', '👁️', '🌊', '❤️'],
    'bible_008': ['🌿', '🍷', '✝️', '🌅'],
  };

  static const _pathEmojis = {
    'bible': '📖',
    'letters': '🔤',
    'prayers': '🙏',
  };

  static String levelEmoji(String levelId) =>
      _levelEmojis[levelId] ?? '🎯';

  static String stickerEmoji(String? stickerId) =>
      _stickerEmojis[stickerId] ?? '🏆';

  static String pathEmoji(String pathId) =>
      _pathEmojis[pathId] ?? '📚';

  static String slideEmoji(String levelId, int slideIndex) {
    final list = _slideEmojis[levelId];
    if (list == null || list.isEmpty) {
      const fallback = ['📖', '✨', '🌟', '💫', '🎉'];
      return fallback[slideIndex % fallback.length];
    }
    return list[slideIndex % list.length];
  }

  static List<Color> levelGradient(String levelId) {
    switch (levelId) {
      case 'bible_001':
        return [const Color(0xFF4FC3F7), const Color(0xFF81D4FA)];
      case 'bible_002':
        return [const Color(0xFF42A5F5), const Color(0xFF7E57C2)];
      case 'bible_003':
        return [const Color(0xFFFFB74D), const Color(0xFFFFD54F)];
      case 'bible_004':
        return [const Color(0xFF66BB6A), const Color(0xFFA5D6A7)];
      case 'bible_005':
        return [const Color(0xFFFF7043), const Color(0xFFFFAB91)];
      case 'bible_006':
        return [const Color(0xFF9575CD), const Color(0xFFB39DDB)];
      case 'bible_007':
        return [const Color(0xFF26C6DA), const Color(0xFF80DEEA)];
      case 'bible_008':
        return [const Color(0xFFEC407A), const Color(0xFFF48FB1)];
      default:
        return [const Color(0xFF64B5F6), const Color(0xFF90CAF9)];
    }
  }

  static List<Color> pathGradient(String pathId) {
    switch (pathId) {
      case 'bible':
        return [const Color(0xFF5C6BC0), const Color(0xFF7986CB)];
      case 'letters':
        return [const Color(0xFF26A69A), const Color(0xFF4DB6AC)];
      case 'prayers':
        return [const Color(0xFFAB47BC), const Color(0xFFCE93D8)];
      default:
        return [const Color(0xFF42A5F5), const Color(0xFF64B5F6)];
    }
  }

  static const List<Color> optionColors = [
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFFF7043),
    Color(0xFFAB47BC),
  ];
}
