import 'package:easyexpire/feature/inventory/view_model/inventory_view_model.dart';
import 'package:easyexpire/widgets/app_primary_button.dart';
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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.inventory_2_outlined, color: Colors.black87),
          onPressed: () {},
        ),
        title: const Text(
          "New Inventory",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
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
                      const Text(
                        "Add New Product",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Log inventory items quickly.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Scan Barcode Button
                      CustomOutlinedIconButton(
                        text: "Scan Barcode / QR",
                        icon: Icons.qr_code_scanner_rounded,
                        onTap: () {
                          // TODO: Trigger QR / Barcode Scanner
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
                          color: Colors.white,
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