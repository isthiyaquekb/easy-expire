import 'package:flutter/material.dart';

class UrgentAttentionTile extends StatelessWidget {
  final String productName;
  final String subtitle; // batch no or location
  final int daysLeft;
  final int quantity;
  final int itemLength;
  final int index;

  const UrgentAttentionTile({
    super.key,
    required this.productName,
    required this.subtitle,
    required this.daysLeft,
    required this.quantity,
    required this.itemLength,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = daysLeft < 0;
    final isExpiringToday = daysLeft == 0;
    final statusText = isExpired ? "Expired" : (isExpiringToday ? "Exp. Today" : "Urgent"); // 'Urgent' for positive days but near
    final statusColor = isExpired ? const Color(0xFFD32F2F) : (isExpiringToday ? const Color(0xFFE65100) : Colors.amber.shade700);

    final dividerColor = Theme.of(context).brightness == Brightness.dark ? Colors.white12 : const Color(0xFFEEEEEE);
    return Container(
      decoration:  BoxDecoration(
        border:(itemLength - 1) == index
            ? null
            : Border(
          bottom: BorderSide(color: dividerColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          // Icon Container
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_bag_outlined, // Changed to shopping_bag_outlined for general product
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          // Title & Location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Status & Qty
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Qty: $quantity",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}