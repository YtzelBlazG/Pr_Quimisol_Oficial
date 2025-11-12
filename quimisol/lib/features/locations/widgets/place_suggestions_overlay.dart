import 'package:flutter/material.dart';
import 'package:quimisol/features/locations/models/place_suggestions.dart';

class PlaceSuggestionsOverlay extends StatelessWidget {
  const PlaceSuggestionsOverlay({
    super.key,
    required this.suggestions,
    required this.selectedIndex,
    required this.onTapItem,
  });

  final List<PlaceSuggestion> suggestions;
  final int selectedIndex;
  final void Function(PlaceSuggestion) onTapItem;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
          itemBuilder: (_, i) {
            final p = suggestions[i];
            final selected = i == selectedIndex;
            return InkWell(
              onTap: () => onTapItem(p),
              child: Container(
                color: selected ? const Color(0xFFF1F5F9) : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      p.provider == 'mapbox' ? Icons.map : Icons.public,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
