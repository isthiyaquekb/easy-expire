import 'package:easyexpire/core/utils/ocr_parser.dart';
import 'package:easyexpire/feature/inventory/view_model/inventory_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test_helper.dart';

void main() {
  setupTestEnvironment();

  group('InventoryViewModel Tests', () {
    late InventoryViewModel viewModel;

    setUp(() {
      viewModel = InventoryViewModel();
    });

    test('nameValidator validates non-empty product name', () {
      expect(viewModel.nameValidator(''), equals('Please enter a name.'));
      expect(viewModel.nameValidator('Organic Apples'), isNull);
    });

    test('dateValidator validates non-empty date', () {
      expect(viewModel.dateValidator(''), equals('Please enter a date.'));
      expect(viewModel.dateValidator('25/12/2026'), isNull);
    });

    test('batchValidator validates non-empty batch number', () {
      expect(
        viewModel.batchValidator(''),
        equals('This field cannot be empty.'),
      );
      expect(viewModel.batchValidator('LOT-1002'), isNull);
    });

    test('applyOcrResult fills batch and formatted date controllers', () {
      final date = DateTime(2026, 12, 1);
      final ocrResult = OcrParseResult(expiryDate: date, batchNumber: 'B-9911');

      viewModel.applyOcrResult(ocrResult);

      expect(viewModel.batchNoController.text, equals('B-9911'));
      expect(viewModel.dateController.text, equals('01/12/2026'));
    });

    test('resetFields clears all controllers', () {
      viewModel.nameController.text = 'Test Product';
      viewModel.batchNoController.text = 'B-123';
      viewModel.quantityController.text = '10';
      viewModel.dateController.text = '01/01/2027';

      viewModel.resetFields();

      expect(viewModel.nameController.text, isEmpty);
      expect(viewModel.batchNoController.text, isEmpty);
      expect(viewModel.quantityController.text, isEmpty);
      expect(viewModel.dateController.text, isEmpty);
    });
  });
}
