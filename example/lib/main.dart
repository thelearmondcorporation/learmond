import 'package:learmond/learmond.dart';

/// Example library entrypoint showing `learmond` package usage.
///
/// This is intentionally a simple example so it can be shown on pub.dev and
/// executed locally. The package re-exports `learmond_flutter`, so Flutter
/// consumers can also access Flutter-specific APIs via `package:learmond`.

void runExample() {
  print('Running Learmond example...');
  // Small sanity check using the helper exported by this package.
  print('calculate() => ${calculate()}');

  // TODO: Replace with actual `learmond_flutter` usage when running in a
  // Flutter-aware context. Example:
  // final client = SomeFlutterClient();
  // client.doSomething();
}

void main() => runExample();
