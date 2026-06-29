import 'package:flutter/material.dart';
import 'network_logger_screen.dart';
import 'network_logger_service.dart';

/// Wrap your app's root widget with this to show a floating network logger button.
class NetworkLoggerOverlay extends StatelessWidget {
  final Widget child;
  const NetworkLoggerOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          const _FloatingLogButton(),
        ],
      ),
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
          listenable: NetworkLoggerService.instance,
          builder: (context, _) {
            final count = NetworkLoggerService.instance.logs.length;
            return FloatingActionButton.small(
              heroTag: 'network_logger_fab',
              onPressed: () => NetworkLoggerScreen.show(context),
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
