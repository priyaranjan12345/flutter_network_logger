## Usage

```dart
import 'package:flutter_network_logger/flutter_network_logger.dart';

void main() {
    WidgetsFlutterBinding.ensureInitialized();

    HttpOverrides.global = NetworkLoggerHttpOverrides();

    runApp(const ExampleApp());
}
```

and inside your home widget to naviagte log view
```dart
Scafold(
    appbar: MyAppBar(),
    body: MyBody(),
    floatingActionButton: FloatingActionButton(
        onPressed: () {
          NetworkLoggerScreen.show(context); // <----------------
        },
        child: const Icon(Icons.wifi),
    ),
);
```

thats it, now enjoy :) 