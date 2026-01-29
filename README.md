## Learmond 

The Learmond Corporation's official unified CLI tool. 

## Includes
- `learmond_flutter`
   * `lpe_sdk`
   * `source_sdk`
   * `lpe`
   * `lpe_with_source`
   * `paysheet`

### Commands
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

## Podman Commands. 
* `learmond podman` - Starts and builds a podman VM machine. 
* `learmond podman start` - Starts a stopped podman VM machine. 
* `learmond podman stop` - Stops the running podman VM machine.
* `learmond podman reset` - Resets the podman VM machine.
* `learmond podman ps` - List running podman VM machines. 
* `learmond podman exec` - Opens the pdoman bash container. 
* `learmond podman clean` - Cleans your podman state.

## Machine Commands. 
* `learmond find` - Find any file in your system or local machine. 
* `learmond open` - Open a file in a nano editor.
* `learmond storage` - Check your local disk space and available storage. 
* `learmond grep` - Grep running ports, and apps. 

## Nginx Commands.
* `learmond nginx start` - Start Nginx.
* `learmond nginx stop` - Stop Nginx. 
* `learmond nginx reload` - Reload Nginx.

## Postgres Commands.
* `learmond postrges install` - Installs postgres in your terminal.
* `learmond postgres db init` - Initializes and cd's into your db folder. 
* `learmond postgres` - Runs your postgres and establishes connection. 

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

## Install on Linux.

To install `learmond` on Linux, follow these steps:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/thelearmondcorporation/learmond.git
   cd learmond
   ```

2. **Install Dart (if not already installed):**
   - Follow instructions at [https://dart.dev/get-dart](https://dart.dev/get-dart) for your distribution.

3. **Activate the CLI globally:**
   ```bash
   dart pub global activate --source=path .
   ```

4. **Ensure Dart pub global bin is in your PATH:**
   Add the following to your `~/.bashrc`, `~/.zshrc`, or relevant shell profile:
   ```bash
   export PATH="$PATH":"$HOME/.pub-cache/bin"
   ```
   Then reload your shell:
   ```bash
   source ~/.bashrc  # or source ~/.zshrc
   ```

5. **Verify installation:**
   ```bash
   learmond --help
   ```

## Install on Windows.

To install `learmond` on Windows:

1. **Clone the repository:**
   - Open PowerShell or Command Prompt:
   ```powershell
   git clone https://github.com/thelearmondcorporation/learmond.git
   cd learmond
   ```

2. **Install Dart SDK:**
   - Download and install Dart from [https://dart.dev/get-dart](https://dart.dev/get-dart).
   - Ensure Dart is added to your system PATH.

3. **Activate the CLI globally:**
   ```powershell
   dart pub global activate --source=path .
   ```

4. **Add Dart pub global bin to your PATH:**
   - The global executables are typically in `%USERPROFILE%\.pub-cache\bin`
   - Add this folder to your system PATH via System Properties > Environment Variables.

5. **Restart your terminal** to reload the PATH.

6. **Verify installation:**
   ```powershell
   learmond --help
   ```

## Examples

See the `example/` folder for a runnable Dart example that demonstrates how to import `package:learmond/learmond.dart` and call its APIs.

```bash
# Resolve dependencies (use Flutter where Flutter SDK is required)
flutter pub get

# Run the example executable from the project root
dart run example:main
``

## LICENSE

MIT

## Author

The Learmond Corporation

