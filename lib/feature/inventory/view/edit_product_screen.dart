import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/core/utils/expiry_date_calculator.dart';
import 'package:easyexpire/feature/inventory/model/inventory_model.dart';
import 'package:easyexpire/feature/inventory/view_model/inventory_view_model.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:easyexpire/widgets/custom_text_field.dart';
import 'package:easyexpire/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EditProductScreen extends StatefulWidget {
  final InventoryModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _batchController;
  late TextEditingController _dateController;
  late DateTime _selectedExpiryDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.productName);
    _quantityController = TextEditingController(
      text: widget.product.quantity.toString(),
    );
    _batchController = TextEditingController(text: widget.product.batchNo);
    _selectedExpiryDate = widget.product.expiryDate.toDate();
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_selectedExpiryDate),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _batchController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = _selectedExpiryDate.isBefore(today) ? today : _selectedExpiryDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );

    if (picked != null) {
      setState(() {
        _selectedExpiryDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          now.hour,
          now.minute,
          now.second,
        );
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _handleSave(InventoryViewModel provider) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final daysRemaining = calculateCalendarDaysRemaining(
      _selectedExpiryDate,
      DateTime.now(),
    );

    final updated = InventoryModel(
      id: widget.product.id,
      userId: widget.product.userId,
      productName: _nameController.text.trim(),
      batchNo: _batchController.text.trim(),
      quantity: int.parse(_quantityController.text.trim()),
      expiryDate: Timestamp.fromDate(_selectedExpiryDate),
      daysLeft: daysRemaining,
    );

    final success = await provider.updateProduct(updated, context);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<InventoryViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CommonAppBar(title: 'Edit Product'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white12 : AppColors.borderColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    label: 'Product Name',
                    hintText: 'e.g. Organic Avocados',
                    controller: _nameController,
                    validator: (v) => provider.nameValidator(v?.trim() ?? ''),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Quantity (Units)',
                          hintText: '1',
                          keyboardType: TextInputType.number,
                          controller: _quantityController,
                          validator: (v) => provider.quantityValidator(v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          label: 'Batch Number',
                          hintText: 'B-12345',
                          controller: _batchController,
                          validator: (v) => provider.batchValidator(v?.trim() ?? ''),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Expiry Date',
                    hintText: 'dd/MM/yyyy',
                    readOnly: true,
                    controller: _dateController,
                    validator: (v) => provider.dateValidator(v?.trim() ?? ''),
                    onTap: _pickDate,
                    suffixIcon: Icon(
                      Icons.calendar_month_outlined,
                      color: isDark ? Colors.white70 : AppColors.labelTextColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppPrimaryButton(
                    text: _isSaving ? 'Saving...' : 'Save Changes',
                    onPressed: _isSaving ? () {} : () => _handleSave(provider),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
