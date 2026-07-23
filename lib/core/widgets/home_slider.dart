import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ProfessionalSlider extends StatefulWidget {
  const ProfessionalSlider({super.key});

  @override
  State<ProfessionalSlider> createState() => _ProfessionalSliderState();
}

class _ProfessionalSliderState extends State<ProfessionalSlider> {
  late final PageController _pageController;
  int activeIndex = 0;
  bool _disposed = false;

  final List<String> banners = [
    'https://images.unsplash.com/photo-1773439877855-cd193d949717?q=80&w=870&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1705921345715-4428776b8cb0?q=80&w=870&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1702974779263-6de52dbe29a3?q=80&w=387&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1702974777184-a128dcb8dd76?q=80&w=820&auto=format&fit=crop',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    Future.delayed(const Duration(seconds: 1), () {
      if (!_disposed && mounted) _startAutoPlay();
    });
  }

  void _startAutoPlay() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 4));
      if (_disposed || !mounted) return false;
      if (!_pageController.hasClients) return false;
      final next = (activeIndex + 1) % banners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      return true;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _pageController,
            itemCount: banners.length,
            onPageChanged: (index) {
              if (!_disposed && mounted) {
                setState(() => activeIndex = index);
              }
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => Get.toNamed(
                  AppRoutes.artistList,
                  arguments: {'featured': true},
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: DecorationImage(
                      image: NetworkImage(banners[index]),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Premium Fashion',
                          style: AppTextStyles.h3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Discover trending styles & elegant stitching',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Explore Now',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: AppColors.primary,
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
          ),
        ),
        const SizedBox(height: 14),
        // ─── Safe indicator — sirf tab show karo jab controller active ho ───
        if (!_disposed && _pageController.hasClients)
          SmoothPageIndicator(
            controller: _pageController,
            count: banners.length,
            effect: ExpandingDotsEffect(
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: AppColors.primary,
              dotColor: Colors.grey.shade300,
            ),
          )
        else
          // Fallback: simple dot indicators without controller
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              banners.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == activeIndex ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == activeIndex
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
      ],
    );
  }
}