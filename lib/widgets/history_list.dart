// lib/widgets/history_list.dart

import 'package:flutter/material.dart';

class HistoryList extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final String listName;

  const HistoryList({required this.history, required this.listName, super.key});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox.shrink(); // No mostra res si no hi ha historial
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listName,
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 200, // Alçada fixa per al carrusel
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final songDetails = item['songDetails'] ?? {};
              final title = songDetails['title'] ?? 'Cançó desconeguda';
              final artistName =
                  songDetails['artistName'] ?? 'Artista desconegut';
              final coverUrl =
                  songDetails['coverURL'] ??
                  'https://via.placeholder.com/200?text=Music';

              return Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 130, // Ample de cada element
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imatge de la Cançó
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          coverUrl,
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 130,
                                height: 130,
                                color: Colors.grey.shade800,
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white54,
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
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Artista
                      Text(
                        artistName,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
