# Learmond Example

This small example demonstrates how to import the `learmond` package and run
an example entrypoint. Because `learmond` re-exports `learmond_flutter`, Flutter
users can access those APIs via `package:learmond/learmond.dart` as well.

Quick start:

```bash
# From the project root (run Flutter pub get to resolve Flutter deps)
flutter pub get

# Run the example executable
dart run example:main
```

Notes:
- If you only need to run Dart-only pieces (like `calculate()`), `dart run`
  will work once dependencies are resolved by `flutter pub get` where
  `learmond` depends on Flutter-based packages.
- To experiment interactively, edit `example/lib/main.dart`.
