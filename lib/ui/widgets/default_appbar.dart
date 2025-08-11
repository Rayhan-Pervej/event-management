import 'package:event_management/core/constants/build_text.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class DefaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? textColor;
  final double elevation;
  final Widget? leading;
  final Widget? titleWidget;
  final bool centerTitle;
  final bool scrollElevation;
  final bool isShowBackButton;

  const DefaultAppBar({
    super.key,
    this.title = '',
    this.actions,
    this.backgroundColor,
    this.textColor,
    this.elevation = 0,
    this.leading,
    this.titleWidget,
    this.centerTitle = false,
    this.scrollElevation = true,
    this.isShowBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.onPrimary,
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            backgroundColor: backgroundColor ?? colorScheme.primaryContainer,
            foregroundColor: textColor ?? colorScheme.onSurface,
            title:
                titleWidget ??
                BuildText(
                  text: title,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? colorScheme.onSurface,
                ),
            centerTitle: centerTitle,
            elevation:
                0, // Remove AppBar's elevation since we use Container's shadow
            scrolledUnderElevation: 0,
            leading: isShowBackButton
                ? (leading ??
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Iconsax.arrow_left_2_outline,
                          color: textColor ?? colorScheme.onSurface,
                        ),
                      ))
                : leading,
            automaticallyImplyLeading: isShowBackButton,
            actions: [...?actions],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
