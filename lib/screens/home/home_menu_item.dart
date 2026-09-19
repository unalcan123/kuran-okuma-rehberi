import 'package:flutter/material.dart';

/// One card on the home / table-of-contents screen.
class HomeMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color foreground;
  final WidgetBuilder screenBuilder;

  const HomeMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.screenBuilder,
  });
}
