// File: ui/widgets/home_stat_card.dart
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:event_management/core/constants/build_text.dart';
import 'package:icons_plus/icons_plus.dart';

class HomeStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showTrend;
  final bool isPositiveTrend;

  const HomeStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
    this.showTrend = false,
    this.isPositiveTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space12),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // Center all content vertically
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center all content horizontally
            children: [
              // Icon with trend in top right if needed
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radius8,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (showTrend)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isPositiveTrend ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isPositiveTrend
                              ? Iconsax.arrow_up_3_outline
                              : Iconsax.arrow_down_outline,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Value
              BuildText(
                text: value,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              // Title
              BuildText(
                text: title,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Subtitle
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                BuildText(
                  text: subtitle!,
                  fontSize: 11,
                  color: colorScheme.onSurface.withOpacity(0.6),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
