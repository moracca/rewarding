import 'package:flutter/services.dart';

class EmojiSets {
  static List<String>? _cachedImageAvatars;

  /// Dynamically discovers all PNGs in assets/avatars/.
  static Future<List<String>> getImageAvatars() async {
    if (_cachedImageAvatars != null) return _cachedImageAvatars!;
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    _cachedImageAvatars = manifest
        .listAssets()
        .where((p) => p.startsWith('assets/avatars/') && p.endsWith('.png'))
        .toList()
      ..sort();
    return _cachedImageAvatars!;
  }

  /// Check if a string is an image avatar path vs an emoji.
  static bool isImageAvatar(String? value) =>
      value != null && value.startsWith('assets/');

  static const avatars = [
    // People
    '😊', '😎', '🤩', '😇', '🥳', '🤠', '🧐', '😏',
    '👦', '👧', '👨', '👩', '🧑', '👴', '👵',
    // Animals
    '🦊', '🐱', '🐶', '🦄', '🐸', '🐻', '🐼', '🦁',
    '🐯', '🐰', '🐨', '🦋', '🐙', '🦖', '🐲', '🦈',
    '🐬', '🦅', '🦉', '🐺', '🐵', '🐧', '🐢', '🦜',
    // Fantasy & fun
    '👻', '🤖', '👽', '🦸', '🧙', '🧚', '🥷', '🎃',
    '⭐', '🌈', '🔥', '💎', '🚀', '🎯', '🏆', '⚡',
  ];

  static const prizes = [
    // Gifts & rewards
    '🎁', '🏆', '🥇', '🎖️', '💰', '💎', '👑', '🌟',
    '🎀', '🧧', '💵', '🪙', '🎊', '🎋',
    // Food & treats
    '🍕', '🍦', '🍩', '🍫', '🍪', '🧁', '🎂', '🍔',
    '🌮', '🍿', '🥤', '☕', '🍰', '🥞', '🧇', '🍟',
    '🌯', '🥨', '🍡', '🧋', '🥧', '🍭', '🍬', '🥡',
    '🍱', '🍜', '🍝', '🥘',
    // Entertainment
    '🎮', '🎬', '🎵', '🎧', '📱', '💻', '🎪', '🎠',
    '🕹️', '🎲', '🎴', '🃏', '📀', '🎤', '🎸', '🎹',
    '🎻', '📸', '📹', '🎞️',
    // Activities & sports
    '⚽', '🏀', '🎳', '🏊', '🚴', '⛷️', '🎨', '🎭',
    '🏈', '⚾', '🎾', '🏐', '🏓', '🛹', '🛼', '⛸️',
    '🤸', '🧗', '🏄', '🎿', '🏇', '🥊', '🏋️',
    // Shopping & stuff
    '🛍️', '👟', '👗', '🧸', '📚', '🎒', '👕', '👖',
    '👒', '🧢', '👑', '💍', '⌚', '🕶️', '🎩',
    // Nature & outings
    '🏖️', '⛺', '🎣', '🌴', '🎡', '🗺️', '🏕️', '🌊',
    '⛵', '🚣', '🏔️', '🌸', '🌺', '🦀', '🐚',
    // Home & relaxation
    '⏰', '🛏️', '📺', '🎉', '✨', '💫', '🛋️', '🧩',
    '♟️', '🪁', '🎈', '🫧', '🕯️', '🧘',
    // Tech & gadgets
    '🖥️', '⌨️', '🖱️', '💡', '🔋', '📡', '🤖', '🛸',
    // Pets & animals
    '🐶', '🐱', '🐠', '🐹', '🐰', '🦎', '🐦', '🐴',
  ];
}
