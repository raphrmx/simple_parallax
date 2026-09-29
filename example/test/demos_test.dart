import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_parallax_example/main.dart';

/// Every screen the menu opens, in the order it lists them.
const List<String> _entries = <String>[
  'One background behind the page',
  'Sideways',
  'Slivers and a controller',
  'A gradient behind the page',
  'Blocks that slide their own background',
  'A carousel in a page',
  'Five hundred blocks',
  'Widgets as the background',
  'Zooming and blurring',
  'Stopping at the middle',
  'A tint over the image',
  'Leaning with the pointer',
];

/// Opens [entry] from the menu, scrolls it, and comes back.
Future<void> _visit(WidgetTester tester, String entry) async {
  await tester.scrollUntilVisible(
    find.text(entry),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text(entry));
  await tester.pumpAndSettle();

  final Finder scrollable = find.byType(Scrollable).first;
  await tester.drag(scrollable, const Offset(0, -600));
  await tester.drag(scrollable, const Offset(-600, 0));
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.arrow_back));
  await tester.pumpAndSettle();
}

void main() {
  for (final bool reduce in <bool>[false, true]) {
    testWidgets(
      'opens and scrolls every screen${reduce ? ' under reduced motion' : ''}',
      (WidgetTester tester) async {
        // The tilt demo reads the accelerometer on Android, which the tests
        // run as. Stand in for the plugin with a phone held upright, then
        // tipped to one side.
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/sensors/method'),
          (MethodCall _) async => null,
        );
        tester.binding.defaultBinaryMessenger.setMockStreamHandler(
          const EventChannel('dev.fluttercommunity.plus/sensors/accelerometer'),
          MockStreamHandler.inline(
            onListen: (Object? _, MockStreamHandlerEventSink events) {
              events.success(<double>[0, 9.81, 0, 0]);
              events.success(<double>[-2, 9.6, 0, 0]);
            },
          ),
        );

        tester.view.physicalSize = const Size(1200, 1800);
        tester.view.devicePixelRatio = 1.5;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const ExampleApp());
        if (reduce) {
          await tester.tap(find.byType(Switch));
          await tester.pumpAndSettle();
        }

        for (final String entry in _entries) {
          await _visit(tester, entry);
        }
        expect(find.text(_entries.last), findsOneWidget);
      },
    );
  }
}
