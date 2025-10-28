import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/theme/palette.dart';

class HomeGuestPage extends StatefulWidget {
  const HomeGuestPage({super.key});

  @override
  State<HomeGuestPage> createState() => _HomeGuestPageState();
}

class _HomeGuestPageState extends State<HomeGuestPage> {
  final _carousel = CarouselSliderController();
  int _current = 0;

  // URLs ejemplo oficial
  final List<String> _imgList = const [
    'https://images.unsplash.com/photo-1649073005971-37babef31983?auto=format&fit=crop&fm=jpg&w=1400&q=70',
    'https://images.unsplash.com/photo-1624392294437-8fc9f876f4d3?auto=format&fit=crop&fm=jpg&w=1400&q=70',
    'https://plus.unsplash.com/premium_photo-1677011779114-5af7e8c06ee1?auto=format&fit=crop&fm=jpg&w=1400&q=70',
    'https://plus.unsplash.com/premium_photo-1678282075115-de1836c1393d?auto=format&fit=crop&fm=jpg&w=1400&q=70',
    'https://images.unsplash.com/photo-1740325952752-fcedd5644a27?auto=format&fit=crop&fm=jpg&w=1400&q=70',
  ];

  // Helper para inyectar parámetros responsivos
  String _buildResponsiveUrl(String base, double logicalWidth, double dpr) {
    // factorCalidad 1.5 da buen balance (retina-ish sin pesar tanto)
    final targetWidth = (logicalWidth * dpr * 1.5).clamp(800, 2200).round();
    // añadir 'h=' para forzar altura, ej. hero 9:16 -> h=(targetWidth*16/9).round()
    final uri = Uri.parse(base);
    final qp = Map<String, String>.from(uri.queryParameters)
      ..addAll({'fm': 'jpg', 'q': '70', 'w': '$targetWidth'});
    return uri.replace(queryParameters: qp).toString();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    // Genera las URLs optimizadas para ESTE dispositivo
    final responsiveUrls = _imgList
        .map((u) => _buildResponsiveUrl(u, size.width, dpr))
        .toList();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Palette.gradientStart, Palette.gradientEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          CarouselSlider(
            carouselController: _carousel,
            items: responsiveUrls.map((url) {
              return Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                // Además ayuda a Flutter a cachear/redimensionar en cliente
                cacheWidth: (size.width * dpr).round(),
                loadingBuilder: (c, w, p) => p == null
                    ? w
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, __, ___) =>
                    const Center(child: Icon(Icons.broken_image, size: 48)),
                filterQuality: FilterQuality.medium,
              );
            }).toList(),
            options: CarouselOptions(
              height: double.infinity,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              enableInfiniteScroll: true,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 600),
              onPageChanged: (index, _) => setState(() => _current = index),
            ),
          ),
          // Overlay + CTA...
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(responsiveUrls.length, (i) {
                      final active = i == _current;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        height: 8,
                        width: active ? 20 : 8,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.secButton,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      onPressed: () => Modular.to.navigate('/auth/login'),
                      child: const Text(
                        'COMENZAR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
