import 'package:flutter/material.dart';
import '../theme/emoji_sets.dart';

class AvatarWidget extends StatelessWidget {
  final String? avatar;
  final double size;
  final double fontSize;

  const AvatarWidget({
    super.key,
    this.avatar,
    this.size = 44,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      clipBehavior: Clip.antiAlias,
      child: EmojiSets.isImageAvatar(avatar)
          ? Image.asset(avatar!, fit: BoxFit.cover)
          : Center(
              child: Text(
                avatar ?? '😊',
                style: TextStyle(fontSize: fontSize),
              ),
            ),
    );
  }
}
