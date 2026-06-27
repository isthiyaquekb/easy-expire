import 'package:flutter/material.dart';

class LabeledDivider extends StatelessWidget {
  final String label;

  const LabeledDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE0E0E0), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(label.toUpperCase(),style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.grey[600],
            letterSpacing: 1.2,
          ),),
        ),
        const Expanded(child: Divider(color: Color(0xFFE0E0E0), thickness: 1)),
      ],
    );
  }
}