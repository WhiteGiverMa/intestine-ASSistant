import 'package:flutter/material.dart';

class ThemedSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;
  final Color inactiveTrackColor;
  final Color thumbColor;

  const ThemedSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor = const Color(0xFF2E7D32),
    this.inactiveTrackColor = Colors.grey,
    this.thumbColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: activeColor,
      inactiveTrackColor: inactiveTrackColor,
      thumbColor: WidgetStateProperty.all(thumbColor),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}

class ThemedSwitchWithTitle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String title;
  final String? subtitle;
  final Color activeColor;

  const ThemedSwitchWithTitle({
    super.key,
    required this.value,
    this.onChanged,
    required this.title,
    this.subtitle,
    this.activeColor = const Color(0xFF2E7D32),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
