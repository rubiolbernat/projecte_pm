import 'package:flutter/material.dart';

class HorizontalCardList extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String listName;
  final Function(String id, String type)? onTap;

  const HorizontalCardList({
    required this.items,
    required this.listName,
    this.onTap,
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
              final coverUrl = item['imageUrl'] ?? 'https://via.placeholder.com/200?text=Music';
              final id = item['id'] ?? '';
              final type = item['type'] ?? 'unknown';

              bool isCircular = (type == 'user' || type == 'artist');

              return GestureDetector(
                onTap: () => widget.onTap?.call(id, type),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: isCircular ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                      children: [
                        // Contenidor de la Imatge amb forma variable
                        ClipRRect(
                          borderRadius: BorderRadius.circular(isCircular ? 70.0 : 8.0),
                          child: Image.network(
                            coverUrl,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 140,
                              height: 140,
                              color: Colors.grey.shade800,
                              child: Icon(
                                isCircular ? Icons.person : Icons.music_note,
                                color: Colors.white54,
                                size: 50,
                              ),
                            ),
                          ),
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
                          textAlign: isCircular ? TextAlign.center : TextAlign.start,
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
                            textAlign: isCircular ? TextAlign.center : TextAlign.start,
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