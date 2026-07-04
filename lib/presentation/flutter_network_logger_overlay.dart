import 'package:flutter/material.dart';
import 'flutter_network_logger_screen.dart';
import '../provider/flutter_network_logger_notifier.dart';

/// Wrap your app's root widget with this to show a floating network logger button.
class FlutterNetworkLoggerOverlay extends StatelessWidget {
  final Widget child;
  const FlutterNetworkLoggerOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(children: [child, const _FloatingLogButton()]),
    );
  }
}

class _FloatingLogButton extends StatefulWidget {
  const _FloatingLogButton();

  @override
  State<_FloatingLogButton> createState() => _FloatingLogButtonState();
}

class _FloatingLogButtonState extends State<_FloatingLogButton> {
  Offset _offset = const Offset(16, 100);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: GestureDetector(
        onPanUpdate: (d) => setState(() => _offset += d.delta),
        child: ListenableBuilder(
          listenable: FlutterNetworkLoggerNotifier.instance,
          builder: (context, _) {
            final count = FlutterNetworkLoggerNotifier.instance.logs.length;
            return FloatingActionButton.small(
              heroTag: 'network_logger_fab',
              onPressed: () => FlutterNetworkLoggerScreen.show(context),
              backgroundColor: Colors.deepPurple,
              child: Badge(
                isLabelVisible: count > 0,
                label: Text('$count', style: const TextStyle(fontSize: 9)),
                child: const Icon(Icons.wifi, color: Colors.white, size: 20),
              ),
            );
          },
        ),
      ),
    );
  }
}
