import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/core/utils/ocr_parser.dart';
import 'package:easyexpire/feature/inventory/model/inventory_model.dart';
import 'package:easyexpire/feature/inventory/view_model/inventory_view_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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

    test('quantityValidator rejects empty, non-numeric, zero, negative, and accepts positive integers', () {
      expect(viewModel.quantityValidator(''), equals('Please enter a quantity.'));
      expect(viewModel.quantityValidator('   '), equals('Please enter a quantity.'));
      expect(viewModel.quantityValidator('abc'), equals('Please enter a valid whole number.'));
      expect(viewModel.quantityValidator('12.5'), equals('Please enter a valid whole number.'));
      expect(viewModel.quantityValidator('0'), equals('Quantity must be greater than 0.'));
      expect(viewModel.quantityValidator('-5'), equals('Quantity must be greater than 0.'));
      expect(viewModel.quantityValidator('1000000'), equals('Quantity exceeds maximum limit.'));
      expect(viewModel.quantityValidator('1'), isNull);
      expect(viewModel.quantityValidator(' 42 '), isNull);
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

    test('updateProduct rejects product with missing document id', () async {
      final product = InventoryModel(
        id: null,
        productName: 'Milk',
        userId: 'user_1',
        quantity: 2,
        batchNo: 'B-1',
        expiryDate: Timestamp.now(),
        daysLeft: 5,
      );
      final result = await viewModel.updateProduct(product);
      expect(result, isFalse);
    });

    test('updateProduct rejects unauthorized product ownership', () async {
      viewModel.userId = 'user_1';
      final product = InventoryModel(
        id: 'prod_99',
        productName: 'Milk',
        userId: 'user_attacker',
        quantity: 2,
        batchNo: 'B-1',
        expiryDate: Timestamp.now(),
        daysLeft: 5,
      );
      final result = await viewModel.updateProduct(product);
      expect(result, isFalse);
    });

    test('updateProduct successfully updates Firestore document when authorized', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      viewModel = InventoryViewModel(firestore: fakeFirestore);
      viewModel.userId = 'user_1';

      await fakeFirestore.collection('products').doc('prod_1').set({
        'id': 'prod_1',
        'product_name': 'Old Name',
        'user_id': 'user_1',
        'quantity': 1,
        'batch_no': 'B-1',
        'expiry_date': Timestamp.now(),
        'days_left': 5,
      });

      final updated = InventoryModel(
        id: 'prod_1',
        productName: 'Updated Name',
        userId: 'user_1',
        quantity: 5,
        batchNo: 'B-1-EDITED',
        expiryDate: Timestamp.now(),
        daysLeft: 10,
      );

      final result = await viewModel.updateProduct(updated);
      expect(result, isTrue);

      final doc = await fakeFirestore.collection('products').doc('prod_1').get();
      expect(doc.data()!['product_name'], equals('Updated Name'));
      expect(doc.data()!['quantity'], equals(5));
      expect(doc.data()!['batch_no'], equals('B-1-EDITED'));
    });

    test('deleteProduct rejects product with missing document id', () async {
      final product = InventoryModel(
        id: '',
        productName: 'Bread',
        userId: 'user_1',
        batchNo: 'B-2',
        quantity: 1,
        expiryDate: Timestamp.now(),
        daysLeft: 3,
      );
      final result = await viewModel.deleteProduct(product);
      expect(result, isFalse);
    });

    test('deleteProduct rejects unauthorized product ownership', () async {
      viewModel.userId = 'user_1';
      final product = InventoryModel(
        id: 'prod_50',
        productName: 'Bread',
        userId: 'user_attacker',
        batchNo: 'B-2',
        quantity: 1,
        expiryDate: Timestamp.now(),
        daysLeft: 3,
      );
      final result = await viewModel.deleteProduct(product);
      expect(result, isFalse);
    });

    test('deleteProduct successfully removes document from Firestore when authorized', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      viewModel = InventoryViewModel(firestore: fakeFirestore);
      viewModel.userId = 'user_1';

      await fakeFirestore.collection('products').doc('prod_1').set({
        'id': 'prod_1',
        'product_name': 'Bread',
        'user_id': 'user_1',
        'batch_no': 'B-2',
        'quantity': 1,
        'expiry_date': Timestamp.now(),
        'days_left': 3,
      });

      final product = InventoryModel(
        id: 'prod_1',
        productName: 'Bread',
        userId: 'user_1',
        batchNo: 'B-2',
        quantity: 1,
        expiryDate: Timestamp.now(),
        daysLeft: 3,
      );

      final result = await viewModel.deleteProduct(product);
      expect(result, isTrue);

      final doc = await fakeFirestore.collection('products').doc('prod_1').get();
      expect(doc.exists, isFalse);
    });
  });
}
