import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_parallax/simple_parallax.dart';

import 'helpers.dart';

void main() {
  group('SimpleParallaxWidget', () {
    testWidgets('scrolls the blocks it is given', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxWidget(
            children: <Widget>[
              const SizedBox(height: 400, child: Text('First')),
              SimpleParallaxItem(image: testImage, height: 300),
              const SizedBox(height: 800, child: Text('Last')),
            ],
          ),
        ),
      );

      expect(find.text('First'), findsOneWidget);
      await tester.drag(find.text('First'), const Offset(0, -900));
      await tester.pumpAndSettle();

      expect(find.text('Last'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('builds its blocks only as they come into view', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxWidget(
            children: <Widget>[
              const SizedBox(height: 400, child: Text('First')),
              SimpleParallaxItem(image: testImage, height: 800),
              const SizedBox(height: 800, child: Text('Last')),
            ],
          ),
        ),
      );

      expect(find.text('Last'), findsNothing);

      await tester.drag(find.text('First'), const Offset(0, -900));
      await tester.pumpAndSettle();

      expect(find.text('Last'), findsOneWidget);
    });

    testWidgets('creates its blocks only as they come into view', (
      WidgetTester tester,
    ) async {
      final Set<int> created = <int>{};

      await tester.pumpWidget(
        app(
          SimpleParallaxWidget.builder(
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              created.add(index);
              return SimpleParallaxItem(
                background: testLayer,
                height: 300,
                child: Text('Block $index'),
              );
            },
          ),
        ),
      );

      expect(created.length, lessThan(10));

      final ScrollPosition position = scrollPosition(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(find.text('Block 99'), findsOneWidget);
      expect(created, isNot(contains(100)));
    });

    testWidgets('pads the list it is given', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxWidget(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              const SizedBox(height: 400, child: Text('First')),
              SimpleParallaxItem(image: testImage, height: 300),
            ],
          ),
        ),
      );

      expect(tester.getTopLeft(find.text('First')).dy, 20);
      expect(find.byType(SliverPadding), findsOneWidget);
    });

    testWidgets('lays its blocks out along the horizontal axis', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxWidget(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              const SizedBox(width: 400, child: Text('First')),
              SimpleParallaxItem(image: testImage, width: 300),
              const SizedBox(width: 800, child: Text('Last')),
            ],
          ),
        ),
      );

      expect(
        tester.widget<Scrollable>(find.byType(Scrollable)).axisDirection,
        AxisDirection.right,
      );
      expect(find.text('First'), findsOneWidget);
      await tester.drag(find.text('First'), const Offset(-900, 0));
      await tester.pumpAndSettle();

      expect(find.text('Last'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the scroll view', () {
    testWidgets('takes what a container hands it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxContainer(
            background: testLayer,
            restorationId: 'page',
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            clipBehavior: Clip.none,
            child: Column(children: tallList()),
          ),
        ),
      );

      final CustomScrollView view =
          tester.widget<CustomScrollView>(find.byType(CustomScrollView));
      expect(view.restorationId, 'page');
      expect(
        view.keyboardDismissBehavior,
        ScrollViewKeyboardDismissBehavior.onDrag,
      );
      expect(view.clipBehavior, Clip.none);
    });

    testWidgets('takes what a widget hands it', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          SimpleParallaxWidget(
            restorationId: 'list',
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            clipBehavior: Clip.none,
            children: tallList(),
          ),
        ),
      );

      final CustomScrollView view =
          tester.widget<CustomScrollView>(find.byType(CustomScrollView));
      expect(view.restorationId, 'list');
      expect(
        view.keyboardDismissBehavior,
        ScrollViewKeyboardDismissBehavior.onDrag,
      );
      expect(view.clipBehavior, Clip.none);
    });
  });
}
