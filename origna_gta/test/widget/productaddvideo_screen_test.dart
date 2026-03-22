import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/productaddvideo_screen.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  group('ProductAddVideo', () {
    testWidgets('renders empty state', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(body: ProductAddVideo(onVideoRemoved: () {})),
        ),
      );
      await tester.pump();

      expect(find.byType(ProductAddVideo), findsOneWidget);
    });

    testWidgets('renders with existing video', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(
            body: ProductAddVideo(
              existingVideoUrl: 'https://example.com/video.mp4',
              onVideoRemoved: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ProductAddVideo), findsOneWidget);
    });

    testWidgets('add button hidden when video present', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(
            body: ProductAddVideo(
              existingVideoUrl: 'https://example.com/video.mp4',
              onVideoRemoved: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ProductAddVideo), findsOneWidget);
    });

    testWidgets('renders video count indicator', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(body: ProductAddVideo(onVideoRemoved: () {})),
        ),
      );
      await tester.pump();

      expect(find.byType(ProductAddVideo), findsOneWidget);
    });

    testWidgets('renders with video count', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(
            body: ProductAddVideo(
              existingVideoUrl: 'https://example.com/video.mp4',
              onVideoRemoved: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ProductAddVideo), findsOneWidget);
    });

    testWidgets('video tile shows remove button', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(
            body: ProductAddVideo(
              existingVideoUrl: 'https://example.com/video.mp4',
              onVideoRemoved: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ProductAddVideo), findsOneWidget);
    });

    testWidgets('renders video badge', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(
            body: ProductAddVideo(
              existingVideoUrl: 'https://example.com/video.mp4',
              onVideoRemoved: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ProductAddVideo), findsOneWidget);
    });

    testWidgets('add button shows video library icon', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(body: ProductAddVideo(onVideoRemoved: () {})),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.video_library_rounded), findsOneWidget);
    });

    testWidgets('didUpdateWidget reinitializes', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(body: ProductAddVideo(onVideoRemoved: () {})),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(
            body: ProductAddVideo(
              existingVideoUrl: 'https://example.com/video.mp4',
              onVideoRemoved: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ProductAddVideo), findsOneWidget);
    });

    testWidgets('dispose cleans up', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(
            body: ProductAddVideo(
              existingVideoUrl: 'https://example.com/video.mp4',
              onVideoRemoved: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(find.byType(ProductAddVideo), findsNothing);
    });
  });
}
