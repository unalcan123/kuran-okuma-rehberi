import 'package:flutter/material.dart';

/// One card on the home / table-of-contents screen.
///
/// With an [image] the card is just that illustration (it carries its own
/// title); [title] is then only read out by screen readers. Without one, a
/// placeholder shows [icon], [title] and [subtitle].
class HomeMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color foreground;
  final WidgetBuilder screenBuilder;

  /// Asset path of the card's illustration (4:3, like the grid cells).
  final String? image;

  const HomeMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.screenBuilder,
    this.image,
  });
}
