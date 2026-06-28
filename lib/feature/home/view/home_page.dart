import 'package:easyexpire/core/constant/app_assets.dart';
import 'package:easyexpire/core/constant/app_colors.dart';
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
      backgroundColor: AppColors.scaffoldBackground,
      // appBar: CommonAppBar(title: "Home", isBack: false),
        appBar: CommonAppBar(
          title: "Home",
          isBack: false, // Default false, but can be true if navigated to
          leading: Image(image: AssetImage(AppAssets.appLogo)),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.primary),
              onPressed: () {
                // TODO: Implement search functionality for notifications
                print("Search notifications tapped!");
              },
            ),
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
                    badgeBgColor: const Color(0xFFFEE8E6), // Light red
                    badgeTextColor: const Color(0xFFD32F2F), // Darker red
                    borderColor: const Color(0xFFEF9A9A), // Red border
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
                    Column(
                      children: urgentAttentionItems
                          .take(5) // Display top 5 urgent items
                          .map((product) => UrgentAttentionTile(
                        productName: product.productName ?? 'N/A',
                        subtitle: product.batchNo ?? 'N/A', // Prioritize batchNo, then location
                        daysLeft: product.daysLeft ?? 0,
                        quantity: product.quantity ?? 0,
                      ))
                          .toList(),
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
                      Icons.qr_code_scanner_outlined, "Scan Batch", () {
                    // TODO: Implement scan batch action
                  }),
                  const SizedBox(height: 8),
                  _buildQuickActionButton(
                      Icons.print_outlined, "Print Report", () {
                    // TODO: Implement print report action
                  }),
                  const SizedBox(height: 8),
                  _buildQuickActionButton(
                      Icons.inventory_outlined, "Inventory Check", () {
                    // TODO: Implement inventory check action
                  }),
                ],
              ),
            ),
          );
        },
      ),
      // body: Padding(
      //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.start,
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       Padding(
      //         padding: const EdgeInsets.all(8.0),
      //         child: const Text(
      //           "Keep an eye on these products, \nit's days are coming to an end",
      //           style: TextStyle(
      //             color: AppColors.textColor,
      //             fontWeight: FontWeight.w600,
      //             fontSize: 18,
      //           ),
      //         ),
      //       ),
      //       // Filter Chips
      //       SizedBox(
      //         height: 50, // Adjust height as needed
      //         child: Consumer<HomeViewModel>(
      //           builder:
      //               (context, homeViewModel, child) => ListView(
      //                 scrollDirection: Axis.horizontal,
      //                 children: [
      //                   _buildFilterChip(
      //                     "All",
      //                     homeViewModel,
      //                     null,
      //                   ), // Show all products
      //                   _buildFilterChip("Expired (0 Days) ", homeViewModel, 0),
      //                   _buildFilterChip("Expires in 3 Days", homeViewModel, 3),
      //                   _buildFilterChip("Expires in 5 Days", homeViewModel, 5),
      //                   _buildFilterChip(
      //                     "Expires in 10 Days",
      //                     homeViewModel,
      //                     10,
      //                   ),
      //                   _buildFilterChip(
      //                     "Expires in 1 Month",
      //                     homeViewModel,
      //                     30,
      //                   ),
      //                 ],
      //               ),
      //         ),
      //       ),
      //       Expanded(
      //         child: Consumer<HomeViewModel>(
      //           builder:
      //               (context, provider, child) =>
      //                   provider.productFilteredList.isNotEmpty
      //                       ? ListView.builder(
      //                         itemCount: provider.productFilteredList.length,
      //                         shrinkWrap: true,
      //                         itemBuilder:
      //                             (context, index) => Padding(
      //                               padding: const EdgeInsets.symmetric(
      //                                 vertical: 4,
      //                               ),
      //                               child: Container(
      //                                 padding: const EdgeInsets.all(10),
      //                                 width: double.maxFinite,
      //                                 decoration: BoxDecoration(
      //                                   color: AppColors.typeColor.withOpacity(
      //                                     0.6,
      //                                   ),
      //                                   borderRadius: BorderRadius.circular(10),
      //                                 ),
      //                                 child: Row(
      //                                   mainAxisAlignment:
      //                                       MainAxisAlignment.spaceBetween,
      //                                   crossAxisAlignment:
      //                                       CrossAxisAlignment.start,
      //                                   children: [
      //                                     Expanded(
      //                                       child: Column(
      //                                         mainAxisAlignment:
      //                                             MainAxisAlignment.start,
      //                                         crossAxisAlignment:
      //                                             CrossAxisAlignment.start,
      //                                         children: [
      //                                           Text(
      //                                             provider
      //                                                 .productFilteredList[index]
      //                                                 .productName,
      //                                             style: const TextStyle(
      //                                               fontSize: 18,
      //                                               fontWeight: FontWeight.w600,
      //                                               color: AppColors.textColor,
      //                                             ),
      //                                             maxLines: 2,
      //                                           ),
      //                                           RichText(
      //                                             text: TextSpan(
      //                                               children: [
      //                                                 const TextSpan(
      //                                                   text: "Expiry Date:",
      //                                                   style: TextStyle(
      //                                                     fontSize: 16,
      //                                                     fontWeight:
      //                                                         FontWeight.w400,
      //                                                     color:
      //                                                         AppColors.textColor,
      //                                                   ),
      //                                                 ),
      //                                                 TextSpan(
      //                                                   text: AppDateFormatter.dateTimeFromFirebase(
      //                                                     provider
      //                                                         .productFilteredList[index]
      //                                                         .expiryDate,
      //                                                   ),
      //                                                   style: const TextStyle(
      //                                                     fontSize: 16,
      //                                                     fontWeight:
      //                                                         FontWeight.w700,
      //                                                     color:
      //                                                         AppColors.textColor,
      //                                                   ),
      //                                                 ),
      //                                               ],
      //                                             ),
      //                                           ),
      //                                           RichText(
      //                                             text: TextSpan(
      //                                               children: [
      //                                                 const TextSpan(
      //                                                   text: "QTY:",
      //                                                   style: TextStyle(
      //                                                     fontSize: 16,
      //                                                     fontWeight:
      //                                                         FontWeight.w400,
      //                                                     color:
      //                                                         AppColors.textColor,
      //                                                   ),
      //                                                 ),
      //                                                 TextSpan(
      //                                                   text:
      //                                                       provider
      //                                                           .productFilteredList[index]
      //                                                           .quantity
      //                                                           .toString(),
      //                                                   style: const TextStyle(
      //                                                     fontSize: 16,
      //                                                     fontWeight:
      //                                                         FontWeight.w700,
      //                                                     color:
      //                                                         AppColors.textColor,
      //                                                   ),
      //                                                 ),
      //                                               ],
      //                                             ),
      //                                           ),
      //                                         ],
      //                                       ),
      //                                     ),
      //                                     RichText(
      //                                       text: TextSpan(
      //                                         children: [
      //                                           TextSpan(
      //                                             text:
      //                                                 provider
      //                                                     .productFilteredList[index]
      //                                                     .daysLeft
      //                                                     .toString(),
      //                                             style: TextStyle(
      //                                               fontSize: 24,
      //                                               fontWeight: FontWeight.w700,
      //                                               color:
      //                                                   provider
      //                                                               .productFilteredList[index]
      //                                                               .daysLeft <
      //                                                           5
      //                                                       ? AppColors
      //                                                           .toxicColor
      //                                                       : provider
      //                                                               .productFilteredList[index]
      //                                                               .daysLeft <
      //                                                           30
      //                                                       ? AppColors
      //                                                           .mediumColor
      //                                                       : AppColors
      //                                                           .goodColor,
      //                                             ),
      //                                           ),
      //                                           const TextSpan(
      //                                             text: " days left",
      //                                             style: TextStyle(
      //                                               fontSize: 16,
      //                                               fontWeight: FontWeight.w400,
      //                                               color: AppColors.textColor,
      //                                             ),
      //                                           ),
      //                                         ],
      //                                       ),
      //                                     ),
      //                                   ],
      //                                 ),
      //                               ),
      //                             ),
      //                       )
      //                       : provider.productFilteredList.isEmpty &&
      //                           provider.selectedFilter == 0
      //                       ? SizedBox(
      //                         child: Column(
      //                           children: [
      //                             Center(
      //                               child: Lottie.asset(
      //                                 AppAssets.notFoundLottie,
      //                                 fit: BoxFit.contain,
      //                               ),
      //                             ),
      //                             Text("No expired product available"),
      //                           ],
      //                         ),
      //                       )
      //                       : SizedBox(
      //                         child: Center(
      //                           child: Lottie.asset(
      //                             AppAssets.notFoundLottie,
      //                             fit: BoxFit.contain,
      //                           ),
      //                         ),
      //                       ),
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Test Notification',
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.notifications_active, color: Colors.white),
        onPressed: () {
          Provider.of<HomeViewModel>(
            context,
            listen: false,
          ).triggerTestNotification();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test notification triggered!')),
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
      IconData icon, String text, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 24),
            const SizedBox(width: 16),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }
}
