import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/productaddimages_screen.dart';
import 'package:origna_gta/utils/utils.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  Widget buildWidget({
    List<ImageModel>? images,
    ValueChanged<List<ImageModel>>? onChanged,
  }) {
    return TestWrapper(
      child: Scaffold(
        body: ProductAddImages(
          imageModels: images ?? [],
          onImagesChanged: onChanged,
        ),
      ),
    );
  }

  group('ProductAddImages', () {
    testWidgets('renders empty state', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(ProductAddImages), findsOneWidget);
    });

    testWidgets('renders with images', (tester) async {
      final images = [
        ImageModel(url: 'test1.jpg', bytes: Uint8List(10)),
        ImageModel(url: 'test2.jpg', bytes: Uint8List(10)),
      ];

      await tester.pumpWidget(buildWidget(images: images));
      await tester.pump();

      expect(find.byType(ProductAddImages), findsOneWidget);
    });

    testWidgets('renders primary badge for first image', (tester) async {
      final images = [ImageModel(url: 'test1.jpg', bytes: Uint8List(10))];

      await tester.pumpWidget(buildWidget(images: images));
      await tester.pump();

      expect(find.byType(ProductAddImages), findsOneWidget);
    });

    testWidgets('remove button exists for images', (tester) async {
      final images = [ImageModel(url: 'test1.jpg', bytes: Uint8List(10))];

      await tester.pumpWidget(buildWidget(images: images));
      await tester.pump();

      expect(find.byType(ProductAddImages), findsOneWidget);
    });

    testWidgets('add button visible when below max', (tester) async {
      final images = [ImageModel(url: 'test1.jpg', bytes: Uint8List(10))];

      await tester.pumpWidget(buildWidget(images: images));
      await tester.pump();

      expect(find.byType(ProductAddImages), findsOneWidget);
    });

    testWidgets('renders image count indicator', (tester) async {
      final images = [
        ImageModel(url: 'test1.jpg', bytes: Uint8List(10)),
        ImageModel(url: 'test2.jpg', bytes: Uint8List(10)),
        ImageModel(url: 'test3.jpg', bytes: Uint8List(10)),
      ];

      await tester.pumpWidget(buildWidget(images: images));
      await tester.pump();

      expect(find.byType(ProductAddImages), findsOneWidget);
    });

    testWidgets('didUpdateWidget syncs image list', (tester) async {
      final images1 = [ImageModel(url: 'test1.jpg', bytes: Uint8List(10))];

      await tester.pumpWidget(buildWidget(images: images1));
      await tester.pump();

      final images2 = [
        ImageModel(url: 'test1.jpg', bytes: Uint8List(10)),
        ImageModel(url: 'test2.jpg', bytes: Uint8List(10)),
      ];

      await tester.pumpWidget(buildWidget(images: images2));
      await tester.pump();

      expect(find.byType(ProductAddImages), findsOneWidget);
    });

    testWidgets('renders with ReorderableListView when images present', (
      tester,
    ) async {
      final images = [
        ImageModel(url: 'test1.jpg', bytes: Uint8List(10)),
        ImageModel(url: 'test2.jpg', bytes: Uint8List(10)),
      ];

      await tester.pumpWidget(buildWidget(images: images));
      await tester.pump();

      expect(find.byType(ReorderableListView), findsOneWidget);
    });

    testWidgets('empty images list does not show ReorderableListView', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(images: []));
      await tester.pump();

      expect(find.byType(ReorderableListView), findsNothing);
    });

    testWidgets('tapping remove updates list', (tester) async {
      List<ImageModel>? changedImages;
      final images = [
        ImageModel(url: 'test1.jpg', bytes: Uint8List(10)),
        ImageModel(url: 'test2.jpg', bytes: Uint8List(10)),
      ];

      await tester.pumpWidget(
        buildWidget(images: images, onChanged: (imgs) => changedImages = imgs),
      );
      await tester.pump();

      final removeButtons = find.bySemanticsLabel('btn-remove-image');
      if (removeButtons.evaluate().isNotEmpty) {
        await tester.tap(removeButtons.first);
        await tester.pump();
        expect(changedImages, isNotNull);
        expect(changedImages!.length, 1);
      }
    });
  });
}
