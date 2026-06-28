import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:flutter/material.dart';

class ProductInventoryCard extends StatelessWidget {
  final String productName;
  final String batchId;
  final int quantity;
  final int maxQuantity; // Used to calculate progress bar percentage
  final int daysLeft; // Positive for days remaining, 0 for today, negative for expired

  const ProductInventoryCard({
    super.key,
    required this.productName,
    required this.batchId,
    required this.quantity,
    required this.maxQuantity,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    // Determine badge text and colors based on daysLeft
    String badgeText;
    Color badgeBgColor;
    Color badgeTextColor;
    Color progressBarFillColor;
    IconData? badgeIcon; // Optional icon for the badge

    if (daysLeft < 0) {
      badgeText = "Expired";
      badgeBgColor = AppColors.errorContainerBackground;
      badgeTextColor = AppColors.onErrorContainerText;
      progressBarFillColor = AppColors.errorProgressBarFill;
      badgeIcon = Icons.error_outline; // Exclamation mark icon for expired
    } else if (daysLeft == 0) {
      badgeText = "Today";
      badgeBgColor = AppColors.warningContainerBackground;
      badgeTextColor = AppColors.onWarningContainerText;
      progressBarFillColor = AppColors.warningProgressBarFill;
      badgeIcon = Icons.access_time; // Clock icon for expiring today
    } else if (daysLeft <= 3) {
      badgeText = "$daysLeft Days";
      badgeBgColor = AppColors.errorContainerBackground; // Red for immediate warning
      badgeTextColor = AppColors.onErrorContainerText;
      progressBarFillColor = AppColors.errorProgressBarFill;
      badgeIcon = Icons.warning_amber_rounded; // Warning icon
    } else if (daysLeft <= 7) {
      badgeText = "$daysLeft Days";
      badgeBgColor = AppColors.warningContainerBackground; // Orange for medium warning
      badgeTextColor = AppColors.onWarningContainerText;
      progressBarFillColor = AppColors.warningProgressBarFill;
      badgeIcon = Icons.watch_later_outlined; // Watch icon
    }
    else {
      badgeText = "$daysLeft Days"; // Default for longer expiry
      badgeBgColor = AppColors.goodContainerBackground;
      badgeTextColor = AppColors.onGoodContainerText;
      progressBarFillColor = AppColors.goodProgressBarFill;
      badgeIcon = null; // No icon for normal state
    }

    // Calculate progress for the bar (percentage of quantity left vs max)
    final double progress = maxQuantity > 0 ? (quantity / maxQuantity).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Space between cards
      padding: const EdgeInsets.all(20.0), // Matches 'p-5'
      decoration: BoxDecoration(
        color:  Theme.of(context).colorScheme.surface, // bg-surface-container-lowest
        border: Border.all(color: AppColors.borderColor), // border-outline-variant
        borderRadius: BorderRadius.circular(12.0), // rounded-xl (adjust for desired roundness)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section: Product Name, Batch ID, and Expiry Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.headlineTextColor, // text-headline-md
                        fontWeight: FontWeight.bold,
                        fontSize: 18, // Adjust as needed for 'headline-md'
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4), // mt-1
                    Text(
                      "Batch ID: $batchId",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.labelTextColor, // text-on-surface-variant text-body-sm
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12), // Spacing between text and badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // px-3 py-1
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(999.0), // rounded-full
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Ensures the row only takes necessary width
                  children: [
                    if (badgeIcon != null) ...[
                      Icon(badgeIcon, size: 16, color: badgeTextColor), // material-symbols-outlined text-[16px]
                      const SizedBox(width: 4), // gap-1
                    ],
                    Text(
                      badgeText.toUpperCase(), // text-label-caps font-label-caps
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: badgeTextColor,
                        fontWeight: FontWeight.w900, // Very bold for caps
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // gap-stack-md (adjust as needed, 16px fits well here)

          // Bottom section: Quantity and Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Quantity".toUpperCase(), // text-label-caps font-label-caps
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.labelTextColor, // text-on-surface-variant
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        quantity.toString(),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.headlineTextColor, // text-headline-lg
                          fontWeight: FontWeight.bold,
                          fontSize: 28, // Adjust as needed for 'headline-lg'
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "units",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.labelTextColor, // text-body-sm font-normal text-on-surface-variant
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 16), // Spacing before progress bar
              Expanded(
                flex: 1, // w-1/2, ensure it takes remaining space with a max width constraint
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 120), // max-w-[120px]
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The actual progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999), // rounded-full
                        child: Container(
                          height: 4.0, // h-1 (assuming 1 unit = 4px)
                          color: AppColors.progressBarTrack, // bg-surface-container-high
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: progress, // dynamic width
                              child: Container(
                                height: 4.0,
                                color: progressBarFillColor, // bg-error
                              ),
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
        ],
      ),
    );
  }
}