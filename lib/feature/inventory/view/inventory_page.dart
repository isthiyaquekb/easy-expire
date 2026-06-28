import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/feature/inventory/view_model/inventory_view_model.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:easyexpire/widgets/common_button.dart';
import 'package:easyexpire/widgets/filter_chip_button.dart';
import 'package:easyexpire/widgets/product_inventory_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:easyexpire/core/constant/app_assets.dart';
import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/feature/home/viewmodel/home_viewmodel.dart';
import 'package:easyexpire/utils/Formatter/app_date_formatter.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:easyexpire/widgets/overview_card.dart';
import 'package:easyexpire/widgets/urgent_attention_tile.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<FormState> localFormKey = GlobalKey<FormState>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inventoryProvider = Provider.of<InventoryViewModel>(context, listen: false);
      inventoryProvider.initialize();
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      // appBar: CommonAppBar(title: "Products",isBack: false,),
      appBar: CommonAppBar(
        title: "Products",
        isBack: false, // Default false, but can be true if navigated to
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image(image: AssetImage(AppAssets.appLogo),),
        ),
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
      // body: SafeArea(
      //   child: Padding(
      //     padding: const EdgeInsets.all(16.0),
      //     child: Consumer<InventoryViewModel>(
      //       builder: (context, provider, child) => Form(
      //         key: localFormKey,
      //         child: ListView(
      //           children: [
      //             const SizedBox(
      //               height: 16,
      //             ),
      //             Text(
      //                 "Add Product details",
      //                 style: TextStyle(
      //                     color: AppColors.textColor,
      //                     fontWeight: FontWeight.w600,
      //                     fontSize: 18)),
      //             const Text(
      //                 "Fill the form and submit the details of the product",
      //                 style: TextStyle(
      //                     color: AppColors.textColor,
      //                     fontWeight: FontWeight.w400,
      //                     fontSize: 16)),
      //             const SizedBox(
      //               height: 40,
      //             ),
      //             Padding(
      //               padding: const EdgeInsets.symmetric(vertical: 8.0),
      //               child: TextFormField(
      //                 controller: provider.nameController,
      //                 keyboardType: TextInputType.name,
      //                 textInputAction: TextInputAction.next,
      //                 textCapitalization: TextCapitalization.words,
      //                 style: const TextStyle(
      //                     color: AppColors.textColor,
      //                     fontSize: 14,
      //                     fontWeight: FontWeight.w400),
      //                 decoration: InputDecoration(
      //                   label: const Text("Name"),
      //                   labelStyle: const TextStyle(
      //                       color: AppColors.textColor,
      //                       fontSize: 14,
      //                       fontWeight: FontWeight.w500),
      //                   hintText: "name",
      //                   hintStyle: const TextStyle(
      //                       color: Colors.black45,
      //                       fontSize: 14,
      //                       fontWeight: FontWeight.w300),
      //                   enabledBorder: OutlineInputBorder(
      //                       borderRadius: BorderRadius.circular(6),
      //                       borderSide:
      //                           const BorderSide(color: AppColors.textColor)),
      //                   focusedBorder: OutlineInputBorder(
      //                       borderRadius: BorderRadius.circular(6),
      //                       borderSide:
      //                           const BorderSide(color: AppColors.textColor)),
      //                   errorBorder: OutlineInputBorder(
      //                       borderRadius: BorderRadius.circular(6),
      //                       borderSide:
      //                           const BorderSide(color: AppColors.toxicColor)),
      //                 ),
      //                 validator: (value) =>
      //                     provider.nameValidator(value!.trim().toString()),
      //               ),
      //             ),
      //             Padding(
      //               padding: const EdgeInsets.symmetric(vertical: 8.0),
      //               child: TextFormField(
      //                 controller: provider.quantityController,
      //                 keyboardType: TextInputType.number,
      //                 textInputAction: TextInputAction.next,
      //                 style: const TextStyle(
      //                     color: AppColors.textColor,
      //                     fontSize: 14,
      //                     fontWeight: FontWeight.w400),
      //                 decoration: InputDecoration(
      //                   label: const Text("Quantity"),
      //                   labelStyle: const TextStyle(
      //                       color: AppColors.textColor,
      //                       fontSize: 14,
      //                       fontWeight: FontWeight.w500),
      //                   hintText: "quantity",
      //                   hintStyle: const TextStyle(
      //                       color: Colors.black45,
      //                       fontSize: 14,
      //                       fontWeight: FontWeight.w300),
      //                   enabledBorder: OutlineInputBorder(
      //                     borderRadius: BorderRadius.circular(6),
      //                   ),
      //                   focusedBorder: OutlineInputBorder(
      //                     borderRadius: BorderRadius.circular(6),
      //                   ),
      //                   errorBorder: OutlineInputBorder(
      //                       borderRadius: BorderRadius.circular(6),
      //                       borderSide:
      //                           const BorderSide(color: AppColors.toxicColor)),
      //                 ),
      //                 validator: (value) =>
      //                     provider.batchValidator(value!.trim().toString()),
      //               ),
      //             ),
      //             Padding(
      //               padding: const EdgeInsets.symmetric(vertical: 8.0),
      //               child: InkWell(
      //                 onTap: () {
      //                   provider.pickDate(context);
      //                 },
      //                 child: Container(
      //                     height: 60,
      //                     decoration: BoxDecoration(
      //                         borderRadius: BorderRadius.circular(6),
      //                         border: Border.all(color: Colors.grey)),
      //                     child: Align(
      //                       alignment: Alignment.centerLeft,
      //                       child: Padding(
      //                         padding:
      //                         const EdgeInsets.symmetric(horizontal: 16.0),
      //                         child: provider.selectedDate.isNotEmpty
      //                             ? Text(
      //                           provider.selectedDate,
      //                           style: const TextStyle(
      //                               color: AppColors.textColor,
      //                               fontSize: 14,
      //                               fontWeight: FontWeight.w400),
      //                         )
      //                             : const Text(
      //                           "expiry date",
      //                           style: TextStyle(
      //                               color: Colors.black45,
      //                               fontSize: 14,
      //                               fontWeight: FontWeight.w300),
      //                         ),
      //                       ),
      //                     )),
      //               ),
      //               // ),
      //             ),
      //             Padding(
      //               padding: const EdgeInsets.symmetric(vertical: 8.0),
      //               child: TextFormField(
      //                 controller: provider.batchNoController,
      //                 onEditingComplete: () => provider.onSelectingDate(),
      //                 keyboardType: TextInputType.streetAddress,
      //                 textInputAction: TextInputAction.done,
      //                 style: const TextStyle(
      //                     color: AppColors.textColor,
      //                     fontSize: 14,
      //                     fontWeight: FontWeight.w400),
      //                 decoration: InputDecoration(
      //                   label: const Text("Batch No"),
      //                   labelStyle: const TextStyle(
      //                       color: AppColors.textColor,
      //                       fontSize: 14,
      //                       fontWeight: FontWeight.w500),
      //                   hintText: "batch no",
      //                   hintStyle: const TextStyle(
      //                       color: Colors.black45,
      //                       fontSize: 14,
      //                       fontWeight: FontWeight.w300),
      //                   enabledBorder: OutlineInputBorder(
      //                     borderRadius: BorderRadius.circular(6),
      //                   ),
      //                   focusedBorder: OutlineInputBorder(
      //                     borderRadius: BorderRadius.circular(6),
      //                   ),
      //                   errorBorder: OutlineInputBorder(
      //                       borderRadius: BorderRadius.circular(6),
      //                       borderSide:
      //                           const BorderSide(color: AppColors.toxicColor)),
      //                 ),
      //                 validator: (value) =>
      //                     provider.batchValidator(value!.trim().toString()),
      //               ),
      //             ),
      //             const SizedBox(
      //               height: 40,
      //             ),
      //             Align(
      //               alignment: Alignment.center,
      //               child: CommonButton(title: "Submit", tap: () {
      //                 if(localFormKey.currentState!.validate()){
      //                   provider.submit(context);
      //                 }
      //                 },),
      //             ),
      //           ],
      //         ),
      //       ),
      //     ),
      //   ),
      // ),


      ///UUUUUUUUUUU
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Keep an eye on these products, \nit's days are coming to an end",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            // Filter Chips
            SizedBox(
              height: 50, // Adjust height as needed
              child: Consumer<HomeViewModel>(
                builder:
                    (context, homeViewModel, child) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // _buildFilterChip(
                          //   "All",
                          //   homeViewModel,
                          //   null,
                          // ), // Show all products
                          // _buildFilterChip("Expired (0 Days) ", homeViewModel, 0),
                          // _buildFilterChip("Expires in 3 Days", homeViewModel, 3),
                          // _buildFilterChip("Expires in 5 Days", homeViewModel, 5),
                          // _buildFilterChip(
                          //   "Expires in 10 Days",
                          //   homeViewModel,
                          //   10,
                          // ),
                          // _buildFilterChip(
                          //   "Expires in 1 Month",
                          //   homeViewModel,
                          //   30,
                          // ),
                          FilterChipButton(
                            text: "All",
                            isSelected: homeViewModel.selectedFilter == null,
                            onTap: () => homeViewModel.setSelectedFilter(null),
                          ),
                          const SizedBox(width: 8),
                          FilterChipButton(
                            text: "Expired (0 Days)", // Filter for items <= 0 days
                            isSelected: homeViewModel.selectedFilter == 0,
                            onTap: () => homeViewModel.setSelectedFilter(0),
                          ),
                          const SizedBox(width: 8),
                          FilterChipButton(
                            text: "Expires in 3 Days", // Filter for 1 to 3 days
                            isSelected: homeViewModel.selectedFilter == 3,
                            onTap: () => homeViewModel.setSelectedFilter(3),
                          ),
                          const SizedBox(width: 8),
                          FilterChipButton(
                            text: "Expires in 10 Days",
                            isSelected: homeViewModel.selectedFilter == 10,
                            onTap: () => homeViewModel.setSelectedFilter(10),
                          ),
                          const SizedBox(width: 8),
                          FilterChipButton(
                            text: "Expires in 1 Month", // Filter for items <= 0 days
                            isSelected: homeViewModel.selectedFilter == 30,
                            onTap: () => homeViewModel.setSelectedFilter(30),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          /*  Expanded(
              child: Consumer<HomeViewModel>(
                builder:
                    (context, provider, child) =>
                        provider.productFilteredList.isNotEmpty
                            ? ListView.builder(
                              itemCount: provider.productFilteredList.length,
                              shrinkWrap: true,
                              itemBuilder:
                                  (context, index) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      width: double.maxFinite,
                                      decoration: BoxDecoration(
                                        color: AppColors.typeColor.withOpacity(
                                          0.6,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  provider
                                                      .productFilteredList[index]
                                                      .productName,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textColor,
                                                  ),
                                                  maxLines: 2,
                                                ),
                                                RichText(
                                                  text: TextSpan(
                                                    children: [
                                                      const TextSpan(
                                                        text: "Expiry Date:",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color:
                                                              AppColors.textColor,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: AppDateFormatter.dateTimeFromFirebase(
                                                          provider
                                                              .productFilteredList[index]
                                                              .expiryDate,
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              AppColors.textColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                RichText(
                                                  text: TextSpan(
                                                    children: [
                                                      const TextSpan(
                                                        text: "QTY:",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color:
                                                              AppColors.textColor,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            provider
                                                                .productFilteredList[index]
                                                                .quantity
                                                                .toString(),
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              AppColors.textColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                      provider
                                                          .productFilteredList[index]
                                                          .daysLeft
                                                          .toString(),
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        provider
                                                                    .productFilteredList[index]
                                                                    .daysLeft <
                                                                5
                                                            ? AppColors
                                                                .toxicColor
                                                            : provider
                                                                    .productFilteredList[index]
                                                                    .daysLeft <
                                                                30
                                                            ? AppColors
                                                                .mediumColor
                                                            : AppColors
                                                                .goodColor,
                                                  ),
                                                ),
                                                const TextSpan(
                                                  text: " days left",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w400,
                                                    color: AppColors.textColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            )
                            : provider.productFilteredList.isEmpty &&
                                provider.selectedFilter == 0
                            ? SizedBox(
                              child: Column(
                                children: [
                                  Center(
                                    child: Lottie.asset(
                                      AppAssets.notFoundLottie,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  Text("No expired product available"),
                                ],
                              ),
                            )
                            : SizedBox(
                              child: Center(
                                child: Lottie.asset(
                                  AppAssets.notFoundLottie,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
              ),
            ),*/

            Expanded(
              child: Consumer<HomeViewModel>(builder: (context, viewModel, child) => ListView.builder(
                itemCount: viewModel.productFilteredList.length,
                itemBuilder: (context, index) {
                  final product = viewModel.productFilteredList[index];
                  final isExpiredOrToday = product.daysLeft! <= 0;
                  final int maxQuantity = product.quantity != null && product.quantity! > 0
                      ? (product.quantity! + 50) // Example: current quantity + 50, or some other logic
                      : 100;
                  final daysLeftText = product.daysLeft! > 0
                      ? "${product.daysLeft} days left"
                      : (product.daysLeft! == 0 ? "0 days left" : "${product.daysLeft} days left");

                  // return Card(
                  //   margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 6.0),
                  //   elevation: 2,
                  //   shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(12),
                  //     side: BorderSide(
                  //       color: isExpiredOrToday ? Colors.red.shade100 : Colors.teal.shade100,
                  //       width: 1.2,
                  //     ),
                  //   ),
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(16.0),
                  //     child: Row(
                  //       crossAxisAlignment: CrossAxisAlignment.center,
                  //       children: [
                  //         Expanded(
                  //           child: Column(
                  //             crossAxisAlignment: CrossAxisAlignment.start,
                  //             children: [
                  //               Text(
                  //                 product.productName ?? 'Unknown Product',
                  //                 style: const TextStyle(
                  //                   fontSize: 16,
                  //                   fontWeight: FontWeight.bold,
                  //                   color: Colors.black87,
                  //                 ),
                  //                 maxLines: 2,
                  //                 overflow: TextOverflow.ellipsis,
                  //               ),
                  //               const SizedBox(height: 4),
                  //               Text(
                  //                 "Expiry Date: ${product.expiryDate}", // Assuming expiryDate is already formatted
                  //                 style: TextStyle(
                  //                   fontSize: 13,
                  //                   color: Colors.grey[600],
                  //                 ),
                  //               ),
                  //               const SizedBox(height: 2),
                  //               Text(
                  //                 "QTY: ${product.quantity}",
                  //                 style: TextStyle(
                  //                   fontSize: 13,
                  //                   color: Colors.grey[600],
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //         const SizedBox(width: 12),
                  //         // Days Left display
                  //         Text(
                  //           daysLeftText,
                  //           style: TextStyle(
                  //             fontSize: 18,
                  //             fontWeight: FontWeight.bold,
                  //             color: isExpiredOrToday ? Colors.red.shade700 : Colors.green.shade700,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // );
                  return ProductInventoryCard(
                    // productName from InventoryModel
                    productName: product.productName ?? 'Unknown Product',
                    // batchId from InventoryModel (assuming 'batchNo' is the field)
                    batchId: product.batchNo ?? 'N/A',
                    // quantity from InventoryModel
                    quantity: product.quantity ?? 0,
                    // maxQuantity for the progress bar (see calculation above)
                    maxQuantity: maxQuantity,
                    // daysLeft from InventoryModel
                    daysLeft: product.daysLeft ?? 0,
                  );
                },
              ),),
            ),
          ],
        ),
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
}
