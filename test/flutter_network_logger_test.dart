import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_network_logger/flutter_network_logger.dart';

void main() {
  test('barrel file exports all public types', () {
    // Verifies the barrel export file compiles and exports types
    expect(FlutterNetworkLoggerNotifier.instance, isNotNull);
    expect(
      FlutterNetworkLoggerHttpOverrides,
      isA<Type>(),
    );
    expect(
      FlutterNetworkLoggerScreen,
      isA<Type>(),
    );
    expect(
      FlutterNetworkLoggerOverlay,
      isA<Type>(),
    );
  });
}
