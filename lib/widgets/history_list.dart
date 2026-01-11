import 'package:flutter/material.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/widgets/save_content.dart';
import 'package:projecte_pm/services/UserService.dart';

class HorizontalCardList extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String listName;
  final Function(String id, String type)? onTap;
  final PlayerService? playerService;
  final dynamic playlistService;
  final dynamic albumService;
  final bool showSaveButton;

  const HorizontalCardList({
    required this.items,
    required this.listName,
    this.onTap,
    this.playerService,
    this.playlistService,
    this.albumService,
    this.showSaveButton = false,
    super.key,
  });

  @override
  State<HorizontalCardList> createState() => _HorizontalCardListState();
}

class _HorizontalCardListState extends State<HorizontalCardList> {
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            widget.listName,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];

              // Extracció de dades
              final title = item['title'] ?? 'Sense títol';
              final subtitle = item['subtitle'] ?? '';
              final coverUrl =
                  item['imageUrl'] ??
                  'https://via.placeholder.com/200?text=Music';
              final id = item['id'] ?? '';
              final type = item['type'] ?? 'unknown';

              bool isCircular = (type == 'user' || type == 'artist');
              final showSaveButtonForItem =
                  widget.showSaveButton &&
                  widget.playerService?.userService != null &&
                  (type == 'playlist' || type == 'album') &&
                  !isCircular;

              return GestureDetector(
                onTap: () => widget.onTap?.call(id, type),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: isCircular
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: [
                        // Contenidor de la Imatge amb forma variable
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                isCircular ? 70.0 : 8.0,
                              ),
                              child: Image.network(
                                coverUrl,
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 140,
                                      height: 140,
                                      color: Colors.grey.shade800,
                                      child: Icon(
                                        isCircular
                                            ? Icons.person
                                            : Icons.music_note,
                                        color: Colors.white54,
                                        size: 50,
                                      ),
                                    ),
                              ),
                            ),

                            // Botó SaveContentButton
                            if (showSaveButtonForItem && widget.playerService != null)
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: SaveContentButton(
                                  contentId: id,
                                  type: type == 'playlist'
                                      ? SaveType.playlist
                                      : SaveType.album,
                                  userService: widget.playerService!.userService,
                                  contentService: type == 'playlist'
                                      ? widget.playlistService
                                      : widget.albumService,
                                  size: 24,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Títol
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: isCircular
                              ? TextAlign.center
                              : TextAlign.start,
                        ),
                        // Subtítol
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: isCircular
                                ? TextAlign.center
                                : TextAlign.start,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
