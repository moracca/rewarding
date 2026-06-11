import 'package:flutter/material.dart';
import '../theme/emoji_sets.dart';

Future<String?> showEmojiPicker(
  BuildContext context, {
  required List<String> emojis,
  String title = 'Pick an emoji',
  String? selected,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 320,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: emojis.length,
          itemBuilder: (context, i) {
            final e = emojis[i];
            final isSelected = e == selected;
            return GestureDetector(
              onTap: () => Navigator.pop(ctx, e),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(e, style: const TextStyle(fontSize: 28)),
              ),
            );
          },
        ),
      ),
    ),
  );
}

/// Avatar picker that shows image avatars first, then emojis.
Future<String?> showAvatarPicker(
  BuildContext context, {
  String? selected,
}) async {
  final imageAvatars = await EmojiSets.getImageAvatars();
  if (!context.mounted) return null;

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(context).colorScheme;
      return AlertDialog(
        title: const Text('Pick an avatar'),
        content: SizedBox(
          width: 340,
          height: 420,
          child: DefaultTabController(
            length: 2,
            initialIndex: EmojiSets.isImageAvatar(selected) ? 0 : 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  tabs: [
                    Tab(text: 'Images (${imageAvatars.length})'),
                    Tab(text: 'Emojis'),
                  ],
                  labelColor: cs.primary,
                  indicatorColor: cs.primary,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Image avatars tab
                      imageAvatars.isEmpty
                          ? Center(
                              child: Text(
                                'No images yet.\nAdd PNGs to assets/avatars/images/',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            )
                          : GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                              itemCount: imageAvatars.length,
                              itemBuilder: (context, i) {
                                final path = imageAvatars[i];
                                final isSelected = path == selected;
                                return GestureDetector(
                                  onTap: () => Navigator.pop(ctx, path),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? cs.primaryContainer
                                          : cs.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(12),
                                      border: isSelected
                                          ? Border.all(
                                              color: cs.primary, width: 2)
                                          : null,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Image.asset(path, fit: BoxFit.contain),
                                  ),
                                );
                              },
                            ),
                      // Emojis tab
                      GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                        itemCount: EmojiSets.avatars.length,
                        itemBuilder: (context, i) {
                          final e = EmojiSets.avatars[i];
                          final isSelected = e == selected;
                          return GestureDetector(
                            onTap: () => Navigator.pop(ctx, e),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.primaryContainer
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(e,
                                  style: const TextStyle(fontSize: 28)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
