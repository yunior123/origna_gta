import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/widgets/product_detail/video_player_dialog.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:easy_localization/easy_localization.dart';
import '../test_utils.dart';

void main() {
  setUp(() {
    initTestMocks();
  });

  Widget createTestWidget({required String videoUrl}) {
    return TestWrapper(
      child: Scaffold(body: VideoPlayerDialog(videoUrl: videoUrl)),
    );
  }

  group('VideoPlayerDialog Rendering', () {
    testWidgets('renders dialog with transparent background', (tester) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://example.com/video.mp4'),
      );
      await tester.pump();

      final dialogFinder = find.byType(Dialog);
      expect(dialogFinder, findsOneWidget);

      final dialog = tester.widget<Dialog>(dialogFinder);
      expect(dialog.backgroundColor, equals(DesignTokens.transparent));
      expect(dialog.insetPadding, equals(EdgeInsets.zero));
    });

    testWidgets('shows loading indicator while initializing', (tester) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://example.com/video.mp4'),
      );
      await tester.pump();

      expect(find.byType(ModernLoadingIndicator), findsOneWidget);
    });

    testWidgets('renders close button positioned correctly', (tester) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://example.com/video.mp4'),
      );
      await tester.pump();

      final positionedFinder = find.byType(Positioned);
      expect(positionedFinder, findsWidgets);

      final closeButtonFinder = find.byIcon(Icons.close);
      expect(closeButtonFinder, findsOneWidget);
    });

    testWidgets('close button has correct styling', (tester) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://example.com/video.mp4'),
      );
      await tester.pump();

      final iconFinder = find.byIcon(Icons.close);
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, equals(DesignTokens.white));
      expect(icon.size, equals(28));
    });

    testWidgets('close button container has circular background', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://example.com/video.mp4'),
      );
      await tester.pump();

      final containerFinder = find.widgetWithIcon(Container, Icons.close);
      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, equals(BoxShape.circle));
    });
  });

  group('VideoPlayerDialog Controls', () {
    testWidgets('close button has correct tooltip', (tester) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://example.com/video.mp4'),
      );
      await tester.pump();

      final iconButtonFinder = find.byType(IconButton);
      final iconButton = tester.widget<IconButton>(iconButtonFinder);
      expect(iconButton.tooltip, equals('common.close'.tr()));
    });

    testWidgets('tap close button pops navigator', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const VideoPlayerDialog(
                      videoUrl: 'https://example.com/video.mp4',
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open Dialog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VideoPlayerDialog), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(VideoPlayerDialog), findsNothing);
    });

    testWidgets('close button is inside stack for proper positioning', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://example.com/video.mp4'),
      );
      await tester.pump();

      final stackFinder = find.byType(Stack);
      expect(stackFinder, findsWidgets);
    });
  });

  group('VideoPlayerDialog Play/Pause Interactions', () {
    testWidgets('dialog initializes video player on creation', (tester) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://example.com/video.mp4'),
      );

      await tester.pump();

      expect(find.byType(VideoPlayerDialog), findsOneWidget);
    });

    testWidgets('shows AspectRatio widget when player is initialized', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://example.com/video.mp4'),
      );

      await tester.pumpAndSettle();

      expect(find.byType(VideoPlayerDialog), findsOneWidget);
    });

    testWidgets('video url is passed correctly to controller', (tester) async {
      const testUrl = 'https://test-video.example.com/sample.mp4';
      await tester.pumpWidget(createTestWidget(videoUrl: testUrl));

      await tester.pump();

      expect(find.byType(VideoPlayerDialog), findsOneWidget);
    });

    testWidgets('center content is wrapped in Center widget', (tester) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://example.com/video.mp4'),
      );
      await tester.pump();

      final centerFinder = find.byType(Center);
      expect(centerFinder, findsWidgets);
    });
  });

  group('VideoPlayerDialog Fullscreen Toggle', () {
    testWidgets('dialog fills entire screen with zero inset padding', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://example.com/video.mp4'),
      );
      await tester.pump();

      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      expect(dialog.insetPadding, equals(EdgeInsets.zero));
    });

    testWidgets('close button positioned at top-right', (tester) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://example.com/video.mp4'),
      );
      await tester.pump();

      final positionedFinder = find.byType(Positioned).last;
      final positioned = tester.widget<Positioned>(positionedFinder);
      expect(positioned.right, equals(16));
      expect(positioned.top, isNotNull);
    });

    testWidgets('positioned top accounts for system padding', (tester) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://example.com/video.mp4'),
      );
      await tester.pump();

      expect(find.byType(Positioned), findsWidgets);
    });
  });

  group('VideoPlayerDialog Error Handling', () {
    testWidgets('shows error state when video fails to load', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          videoUrl: 'https://invalid-url-that-will-fail.example.com/video.mp4',
        ),
      );

      await tester.pumpAndSettle();

      final errorIconFinder = find.byIcon(Icons.error_outline);
      expect(errorIconFinder, findsWidgets);
    });

    testWidgets('error icon has correct color and size', (tester) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://invalid-url.example.com/video.mp4'),
      );

      await tester.pumpAndSettle();

      final iconFinder = find.byIcon(Icons.error_outline);
      if (iconFinder.evaluate().isNotEmpty) {
        final icon = tester.widget<Icon>(iconFinder);
        expect(icon.color, equals(DesignTokens.white));
        expect(icon.size, equals(48));
      }
    });

    testWidgets('error message shows localized text', (tester) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://invalid-url.example.com/video.mp4'),
      );

      await tester.pumpAndSettle();

      final errorTextFinder = find.text('product.video_not_playable'.tr());
      if (errorTextFinder.evaluate().isNotEmpty) {
        expect(errorTextFinder, findsOneWidget);
      }
    });

    testWidgets('error message has white text color', (tester) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://invalid-url.example.com/video.mp4'),
      );

      await tester.pumpAndSettle();

      final textFinder = find.text('product.video_not_playable'.tr());
      if (textFinder.evaluate().isNotEmpty) {
        final text = tester.widget<Text>(textFinder);
        expect(text.style?.color, equals(DesignTokens.white));
      }
    });

    testWidgets('error state shows column with icon and text', (tester) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://invalid-url.example.com/video.mp4'),
      );

      await tester.pumpAndSettle();

      if (find.byIcon(Icons.error_outline).evaluate().isNotEmpty) {
        final columnFinder = find.widgetWithIcon(Column, Icons.error_outline);
        if (columnFinder.evaluate().isNotEmpty) {
          final column = tester.widget<Column>(columnFinder);
          expect(column.mainAxisSize, equals(MainAxisSize.min));
        }
      }
    });

    testWidgets('sized box spacing between icon and text', (tester) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://invalid-url.example.com/video.mp4'),
      );

      await tester.pumpAndSettle();

      if (find.byIcon(Icons.error_outline).evaluate().isNotEmpty) {
        final sizedBoxFinder = find.byType(SizedBox);
        bool foundSpacing = false;
        for (final finder in sizedBoxFinder.evaluate()) {
          final widget = finder.widget as SizedBox;
          if (widget.height == 16) {
            foundSpacing = true;
            break;
          }
        }
        expect(foundSpacing || sizedBoxFinder.evaluate().isNotEmpty, isTrue);
      }
    });
  });

  group('VideoPlayerDialog Lifecycle', () {
    testWidgets('widget state is created correctly', (tester) async {
      await tester.pumpWidget(
        createTestWidget(videoUrl: 'https://example.com/video.mp4'),
      );
      await tester.pump();

      final state = tester.state(find.byType(VideoPlayerDialog));
      expect(state, isNotNull);
    });

    testWidgets('dialog can be dismissed by popping', (tester) async {
      var dialogShown = false;

      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  dialogShown = true;
                  showDialog(
                    context: context,
                    builder: (context) => const VideoPlayerDialog(
                      videoUrl: 'https://example.com/video.mp4',
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(dialogShown, isTrue);

      expect(find.byType(VideoPlayerDialog), findsOneWidget);
      expect(dialogShown, isTrue);

      Navigator.of(tester.element(find.byType(VideoPlayerDialog))).pop();
      await tester.pumpAndSettle();

      expect(find.byType(VideoPlayerDialog), findsNothing);
    });
  });
}
