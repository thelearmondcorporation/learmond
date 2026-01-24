## Learmond 

The Learmond Corporation's official CLI tool. 

## Includes
- `learmond_flutter`
   * `lpe_sdk`
   * `source_sdk`
   * `lpe`
   * `lpe_with_source`
   * `paysheet`

### Commands
* `learmond install` – Compile the CLI and install it to your workspace.
* `learmond doctor` – Check your environment for required tools and setup.
* `learmond repo` – Initialize and manage a git repository.
* `learmond create` – Create a new project for Flutter, React Native, Ruby, or NPM and move into the project directory.
* `learmond format` – Run formatting and linting based on the project type.
* `learmond analyze` – Run static analysis on the current project (Flutter, Dart, React Native, NPM, Ruby).
* `learmond test` – Run tests for the detected project type.
* `learmond changelog` – Generate or update the project `CHANGELOG.md` and `README.md`.
* `learmond license` - Generate or update the project `LICENSE`. Supports `MIT`, `APACHE`, `GNU`.
* `learmond build` – Build project APK or AppBundle.
* `learmond push` – Stage, commit, and push changes to the current branch on origin.
* `learmond publish` – Run preflight checks and publish the project (if you intend to publish, supports pub.dev, npm, or RubyGems).

## Install via Homebrew (macOS) 🔧

You can install `learmond` via Homebrew using the provided Homebrew tap or directly from the formula in this repository.

- Tap and install from the public GitHub tap:

```bash
brew tap thelearmondcorporation/homebrew-learmond https://github.com/thelearmondcorporation/homebrew-learmond
brew install learmond
```

- Or install directly (single-line) from the tap without tapping first:

```bash
brew install thelearmondcorporation/homebrew-learmond/learmond
```

- Update or upgrade:

```bash
brew update
brew upgrade learmond
```

Note: The tap's formula is located in `homebrew-learmond/learmond.rb` in this repository.

## Examples

See the `example/` folder for a runnable Dart example that demonstrates how to import `package:learmond/learmond.dart` and call its APIs.

```bash
# Resolve dependencies (use Flutter where Flutter SDK is required)
flutter pub get

# Run the example executable from the project root
dart run example:main
```



## LICENSE

MIT

## Author

The Learmond Corporation

