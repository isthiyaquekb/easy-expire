
import 'package:easyexpire/core/constant/app_assets.dart';
import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/feature/home/viewmodel/home_viewmodel.dart';
import 'package:easyexpire/utils/Formatter/app_date_formatter.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
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
    });



    return Scaffold(
      backgroundColor: AppColors.scaffoldColor,
        appBar: CommonAppBar(title: "Home",isBack: false,),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Text(
                  "Keep an eye on these products, \nit's days are coming to an end",
                  style: TextStyle(
                      color: AppColors.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 18)),
            ),
            // Filter Chips
            SizedBox(
              height: 50, // Adjust height as needed
              child: Consumer<HomeViewModel>(builder: (context, homeViewModel, child) => ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip("All", homeViewModel, null), // Show all products
                  _buildFilterChip("Expired (0 Days) ", homeViewModel, 0),
                  _buildFilterChip("Expires in 3 Days", homeViewModel, 3),
                  _buildFilterChip("Expires in 5 Days", homeViewModel, 5),
                  _buildFilterChip("Expires in 10 Days", homeViewModel, 10),
                  _buildFilterChip("Expires in 1 Month", homeViewModel, 30),
                ],
              ),)
            ),
            Expanded(
                child: Consumer<HomeViewModel>(
              builder: (context, provider, child) => provider
                      .productFilteredList.isNotEmpty
                  ? ListView.builder(
                      itemCount: provider.productFilteredList.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          width: double.maxFinite,
                          decoration: BoxDecoration(
                              color: AppColors.typeColor.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider
                                        .productFilteredList[index].productName,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textColor),
                                  ),
                                  RichText(
                                      text: TextSpan(children: [
                                        const TextSpan(
                                            text: "Expiry Date:",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400,
                                                color: AppColors.textColor)),
                                        TextSpan(
                                            text: AppDateFormatter.dateTimeFromFirebase(provider
                                                .productFilteredList[index]
                                                .expiryDate),
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textColor)),
                                      ])),
                                  RichText(
                                      text: TextSpan(children: [
                                        const TextSpan(
                                            text: "QTY:",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400,
                                                color: AppColors.textColor)),
                                        TextSpan(
                                            text: provider
                                                .productFilteredList[index].quantity
                                                .toString(),
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textColor)),
                                      ])),
                                ],
                              ),
                              RichText(
                                  text: TextSpan(children: [
                                TextSpan(
                                    text: provider
                                        .productFilteredList[index].daysLeft
                                        .toString(),
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: provider
                                                    .productFilteredList[index]
                                                    .daysLeft <
                                                5
                                            ? AppColors.toxicColor
                                            : provider
                                                        .productFilteredList[
                                                            index]
                                                        .daysLeft <
                                                    30
                                                ? AppColors.mediumColor
                                                : AppColors.goodColor)),
                                const TextSpan(
                                    text: " days left",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.textColor)),
                              ]))
                            ],
                          ),
                        ),
                      ),
                    )
                  : provider
                  .productFilteredList.isEmpty && provider
                  .selectedFilter==0?SizedBox(
                child: Column(
                  children: [
                    Center(
                        child: Lottie.asset(AppAssets.notFoundLottie,
                            fit: BoxFit.contain)),
                    Text("No expired product available")
                  ],
                ),
              ):SizedBox(
                      child: Center(
                          child: Lottie.asset(AppAssets.notFoundLottie,
                              fit: BoxFit.contain)),
                    ),
            ))
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
