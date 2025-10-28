import 'package:flutter/material.dart';
import 'package:quimisol/features/admin/presentation/widgets/common/glass.dart';

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key});
  @override
  Widget build(BuildContext context) {
    Widget skel() => Glass(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                _Circle(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bar(width: 160),
                      SizedBox(height: 8),
                      _Bar(width: 220, height: 10, opacity: .18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 8,
      itemBuilder: (_, __) => skel(),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration:
          const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
    );
  }
}

class _Bar extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;
  const _Bar({required this.width, this.height = 12, this.opacity = .26});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
