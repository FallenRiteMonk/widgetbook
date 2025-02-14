import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/src/providers/injected_theme_provider.dart';
import 'package:widgetbook/src/providers/injected_theme_state.dart';

import '../../helper/provider_helper.dart';
import '../../helper/widget_test_helper.dart';

extension _WidgetTesterProviderExtension on WidgetTester {
  Future<InjectedThemeProvider> pumpProvider({
    ThemeData? lightTheme,
    ThemeData? darkTheme,
  }) async {
    final provider = await pumpBuilderAndReturnProvider<InjectedThemeProvider>(
      InjectedThemeBuilder(
        lightTheme: lightTheme,
        darkTheme: darkTheme,
        child: Container(),
      ),
    );
    return provider;
  }
}

void main() {
  group(
    '$InjectedThemeProvider',
    () {
      final initialLightTheme = ThemeData();
      final initialDarkTheme = ThemeData();

      testWidgets(
        'emits $InjectedThemeState(newTheme, newTheme) when themesChanged is called',
        (WidgetTester tester) async {
          var provider = await tester.pumpProvider(
            lightTheme: initialLightTheme,
            darkTheme: initialDarkTheme,
          );

          // Setting of any ThemeData property is required because otherwise
          // the onStateChanged provider method is never called
          final newLightTheme = ThemeData(
            scaffoldBackgroundColor: Colors.yellow,
          );
          final newDarkTheme = ThemeData(
            scaffoldBackgroundColor: Colors.yellow,
          );

          provider = await tester.invokeMethodAndReturnPumpedProvider(
            () {
              provider.themesChanged(
                lightTheme: newLightTheme,
                darkTheme: newDarkTheme,
              );
            },
          );

          expect(
            provider.state,
            equals(
              InjectedThemeState(
                lightTheme: newLightTheme,
                darkTheme: newDarkTheme,
              ),
            ),
          );
        },
      );

      testWidgets(
        '.of returns $InjectedThemeProvider instance',
        (WidgetTester tester) async {
          await tester.pumpWidgetWithMaterialApp(
            InjectedThemeBuilder(
              child: Container(),
            ),
          );

          final BuildContext context = tester.element(find.byType(Container));
          final provider = InjectedThemeProvider.of(context);
          expect(
            provider,
            isNot(null),
          );
        },
      );

      testWidgets(
        '.state defaults to ${InjectedThemeState()}',
        (WidgetTester tester) async {
          final provider = await tester.pumpProvider();

          expect(
            provider.state,
            equals(InjectedThemeState()),
          );
        },
      );
    },
  );
}
