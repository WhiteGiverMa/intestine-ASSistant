import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemedSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveTrackColor;
  final Color? thumbColor;

  const ThemedSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.inactiveTrackColor,
    this.thumbColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final effectiveActiveColor = activeColor ?? colors.primary;
    final effectiveInactiveColor = inactiveTrackColor ?? colors.textHint;
    final effectiveThumbColor = thumbColor ?? colors.card;

    return Switch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: effectiveActiveColor,
      inactiveTrackColor: effectiveInactiveColor,
      thumbColor: WidgetStateProperty.all(effectiveThumbColor),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}

class ThemedSwitchWithTitle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String title;
  final String? subtitle;
  final Color? activeColor;

  const ThemedSwitchWithTitle({
    super.key,
    required this.value,
    this.onChanged,
    required this.title,
    this.subtitle,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ],
          ),
          ThemedSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }
}
