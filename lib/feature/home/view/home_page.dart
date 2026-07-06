import 'package:easyexpire/core/constant/app_assets.dart';
import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/core/theme/theme_view_model.dart';
import 'package:easyexpire/feature/home/viewmodel/home_viewmodel.dart';
import 'package:easyexpire/feature/notification/viewmodel/notification_viewmodel.dart';
import 'package:easyexpire/utils/Formatter/app_date_formatter.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:easyexpire/widgets/overview_card.dart';
import 'package:easyexpire/widgets/urgent_attention_tile.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProvider = Provider.of<HomeViewModel>(context, listen: false);
      homeProvider.checkForUpdate(context);
      homeProvider.initialize();
      final effectiveUserId = homeProvider.userId.isEmpty ? null : homeProvider.userId;
      if(effectiveUserId!=null){
        Provider.of<NotificationViewModel>(context, listen: false).fetchNotifications(effectiveUserId);
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // appBar: CommonAppBar(title: "Home", isBack: false),
        appBar: CommonAppBar(
          title: "Home",
          isBack: false, // Default false, but can be true if navigated to
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image(image: AssetImage(AppAssets.appLogo),),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () {
                // TODO: Implement search functionality for notifications
                print("Search notifications tapped!");
              },
            ),
            Consumer<ThemeViewModel>(builder: (context, themeProvider, child) => IconButton(
              icon: Icon(Theme.of(context).brightness == Brightness.dark
    ? Icons.light_mode
        : Icons.dark_mode, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () {
                Provider.of<ThemeViewModel>(context, listen: false).toggleTheme();
              },
            ),)
          ],
         ),
      body: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          // Calculate statistics based on productList
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final expiredItems = viewModel.productList.where((p) => p.daysLeft < 0).toList();
          final expiringTodayItems = viewModel.productList.where((p) => p.daysLeft == 0).toList();
          final totalSKUs = viewModel.productList.length; // Assuming each InventoryModel is one SKU
          final urgentAttentionItems = [
            ...expiredItems,
            ...expiringTodayItems.where((p) => !expiredItems.contains(p)), // Avoid duplicates
          ]..sort((a,b) => a.daysLeft!.compareTo(b.daysLeft!)); // Sort by days left, most expired first

          // Safely calculate total quantity for safe status
          int safeStatusSKUs = 0;
          for (var product in viewModel.productList) {
            safeStatusSKUs += product.quantity ?? 0; // Assuming quantity is int?
          }


          return RefreshIndicator(
            onRefresh: () async {
              await viewModel.getAllProduct(viewModel.userId);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // Allows pull-to-refresh even if content is short
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dashboard",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Daily Overview",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Expired Items Card
                  OverviewCard(
                    title: "Expired",
                    count: expiredItems.length.toString(),
                    subtitle: "SKUs to pull immediately",
                    badgeText: "Action Required",
                    // badgeBgColor: const Color(0xFFFEE8E6), // Light red
                    // badgeTextColor: const Color(0xFFD32F2F), // Darker red
                    // borderColor: const Color(0xFFEF9A9A), // Red border
                    badgeBgColor: Theme.of(context).brightness == Brightness.dark ? Colors.red.shade900.withOpacity(0.3) : const Color(0xFFFEE8E6),
                    badgeTextColor: Theme.of(context).brightness == Brightness.dark ? Colors.red.shade200 : const Color(0xFFD32F2F),
                    borderColor: Theme.of(context).brightness == Brightness.dark ? Colors.red.shade800 : const Color(0xFFEF9A9A),
                  ),

                  // Expiring Today Card
                  OverviewCard(
                    title: "Expiring Today",
                    count: expiringTodayItems.length.toString(),
                    subtitle: "SKUs need discount review",
                    badgeText: "Markdowns",
                    badgeBgColor: const Color(0xFFFFF3E0), // Light orange
                    badgeTextColor: const Color(0xFFE65100), // Darker orange
                    borderColor: const Color(0xFFFFCC80), // Orange border
                  ),

                  // Safe Status Card
                  OverviewCard(
                    title: "Safe Status",
                    count: safeStatusSKUs.toString(),
                    subtitle: "Total fresh inventory SKUs",
                    badgeText: "Optimal",
                    badgeBgColor: const Color(0xFFE8F5E9), // Light green
                    badgeTextColor: const Color(0xFF388E3C), // Darker green
                    borderColor: const Color(0xFFA5D6A7), // Green border
                  ),
                  const SizedBox(height: 24),

                  // Urgent Attention Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Urgent Attention",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to a detailed urgent attention list screen
                          Navigator.pushNamed(context, '/home'); // Navigate to the other Home screen
                        },
                        child: Text(
                          "View All",
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // List of Urgent Attention Items
                  if (urgentAttentionItems.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          "No urgent attention items at the moment.",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                  // Limit to 3-5 items for the dashboard preview
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        border: Border.all(color: AppColors.borderColor)
                      ),
                      child: Column(
                        children: urgentAttentionItems
                            .take(5) // Display top 5 urgent items
                            .map((product) => UrgentAttentionTile(
                          productName: product.productName ?? 'N/A',
                          subtitle: product.batchNo ?? 'N/A', // Prioritize batchNo, then location
                          daysLeft: product.daysLeft ?? 0,
                          quantity: product.quantity ?? 0,
                          itemLength: urgentAttentionItems.length,
                          index: urgentAttentionItems.indexOf(product),
                        ))
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Quick Actions Section
                  Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActionButton(
                    context,
                    Theme.of(context).brightness,
                      Icons.qr_code_scanner_outlined, "Scan Batch", () {
                    // TODO: Implement scan batch action
                  }),
                  const SizedBox(height: 8),
                  _buildQuickActionButton(
                    context,
                      Theme.of(context).brightness,
                      Icons.print_outlined, "Print Report", () {
                    // TODO: Implement print report action
                  }),
                  const SizedBox(height: 8),
                  _buildQuickActionButton(
                    context,
                      Theme.of(context).brightness,
                      Icons.inventory_outlined, "Inventory Check", () {
                    // TODO: Implement inventory check action
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, HomeViewModel viewModel, int? days) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: viewModel.selectedFilter == days,
        onSelected: (_) => viewModel.setSelectedFilter(days),
      ),
    );
  }

  Widget _buildQuickActionButton(
      BuildContext context,
  Brightness? isDark, IconData icon, String text, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: text=="Scan Batch"?Theme.of(context).colorScheme.primary:Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Icon(icon, color:  text=="Scan Batch"?Theme.of(context).colorScheme.surface:Theme.of(context).colorScheme.onSurface, size: 24),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color:text=="Scan Batch"?Theme.of(context).colorScheme.surface: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: text=="Scan Batch"?Theme.of(context).colorScheme.surface:Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }
}
