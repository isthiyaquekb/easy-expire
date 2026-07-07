import 'dart:developer';

import 'package:easyexpire/core/constant/app_assets.dart';
import 'package:easyexpire/core/utils/ocr_parser.dart';
import 'package:easyexpire/feature/inventory/view/barcode_scanner_screen.dart';
import 'package:easyexpire/feature/inventory/view/ocr_scanner_screen.dart';
import 'package:easyexpire/feature/inventory/view_model/inventory_view_model.dart';
import 'package:easyexpire/widgets/app_primary_button.dart';
import 'package:easyexpire/widgets/common_app_text.dart';
import 'package:easyexpire/widgets/common_button.dart';
import 'package:easyexpire/widgets/custom_text_field.dart';
import 'package:easyexpire/widgets/labeled_divider.dart';
import 'package:easyexpire/widgets/outlined_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddNewProductScreen  extends StatelessWidget {
  const AddNewProductScreen({super.key});


  @override
  Widget build(BuildContext context) {

    final GlobalKey<FormState> localFormKey = GlobalKey<FormState>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inventoryProvider = Provider.of<InventoryViewModel>(context, listen: false);
      inventoryProvider.initialize();
    });

    return Scaffold(
      // backgroundColor: const Color(0xFFFAFAFA),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image(image: AssetImage(AppAssets.appLogo),),
        ),
        title: Text(
          "New Inventory",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface,),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Consumer<InventoryViewModel>(builder: (context, provider, child) => Form(
                  key: localFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      CommonAppText("Add New Product", variant: AppTextVariant.headlineLg,color: Theme.of(context).colorScheme.primary,),
                      // Text(
                      //   "Add New Product",
                      //   style: TextStyle(
                      //     fontSize: 24,
                      //     fontWeight: FontWeight.bold,
                      //     color: Colors.black,
                      //   ),
                      // ),
                      const SizedBox(height: 4),
                      CommonAppText("Log inventory items quickly.", variant: AppTextVariant.bodySm,color: Theme.of(context).colorScheme.secondary,),
                      // Text(
                      //   "Log inventory items quickly.",
                      //   style: TextStyle(
                      //     fontSize: 14,
                      //     color: Colors.grey[600],
                      //   ),
                      // ),
                      const SizedBox(height: 24),

                      // Scan Barcode Button
                      CustomOutlinedIconButton(
                        text: "Scan Barcode / QR",
                        icon: Icons.qr_code_scanner_rounded,
                        onTap: () async {
                          // TODO: Trigger QR / Barcode Scanner
                          final scannedBarcode = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const BarcodeScannerScreen(),
                            ),
                          );

                          if (scannedBarcode != null && scannedBarcode is String) {
                            log("BARCODE FOUND======>:${scannedBarcode}");
                            provider.setBarCode(scannedBarcode);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Scan Package (OCR) Button
                      CustomOutlinedIconButton(
                        text: "Scan Package (Batch/Expiry)",
                        icon: Icons.document_scanner_outlined,
                        onTap: () async {
                          final result = await Navigator.of(context).push<OcrParseResult>(
                            MaterialPageRoute(
                              builder: (context) => const OcrScannerScreen(),
                            ),
                          );

                          if (result != null) {
                            log("OCR RESULT======>: $result");
                            provider.applyOcrResult(result);
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Divider Line
                      const LabeledDivider(label: "or enter manually"),
                      const SizedBox(height: 24),

                      // Form Container
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Column(
                          children: [
                            // Product Name
                            CustomTextField(
                              label: "Product Name",
                              hintText: "e.g. Organic Avocados",
                              controller: provider.nameController,
                            ),
                            const SizedBox(height: 16),

                            // Quantity and Batch Row
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    label: "Quantity (Units)",
                                    hintText: "0",
                                    keyboardType: TextInputType.number,
                                    controller: provider.quantityController,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: CustomTextField(
                                    label: "Batch Number",
                                    hintText: "B-12345",
                                    controller: provider.batchNoController,

                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Expiry Date Field
                            CustomTextField(
                              label: "Expiry Date",
                              hintText: "mm/dd/yyyy",
                              readOnly: true,
                              controller: provider.dateController,
                              onTap: () => provider.pickDate(context),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_view_day_outlined, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Icon(Icons.calendar_month_outlined, color: Colors.grey[600]),
                                  const SizedBox(width: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),),
              ),
            ),

            // Fixed Bottom Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Consumer<InventoryViewModel>(builder: (context, provider, child) => AppPrimaryButton(text: "Submit Product",
                onPressed:() {
                  if (localFormKey.currentState?.validate() ?? false) {
                    provider.submit(context);
                  }
                },
              ),)
            ),
          ],
        ),
      ),
    );
  }

}