import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quimisol/features/locations/models/place_suggestions.dart';
import '../services/place_search_service.dart';

typedef OnPick = void Function(PlaceSuggestion s);

class LocationSearchBar extends StatefulWidget {
  final PlaceSearchService service;
  final OnPick onPick;
  const LocationSearchBar({super.key, required this.service, required this.onPick});

  @override
  State<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _deb;
  List<PlaceSuggestion> _items = [];

  void _onChanged(String v) {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 300), () async {
      final r = await widget.service.search(v);
      if (!mounted) return;
      setState(() => _items = r);
    });
  }

  @override
  void dispose() {
    _deb?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            onChanged: _onChanged,
            decoration: const InputDecoration(
              hintText: 'Buscar dirección o lugar...',
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (_items.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = _items[i];
                return ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(s.name),
                  subtitle: Text(s.placeName, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    _focus.unfocus();
                    setState(() => _items = []);
                    widget.onPick(s);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
