{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };
        # nixpkgs' `flutter` tracks the newest stable (3.47 here); this app is built
        # against the 3.35 line it was developed on.
        flutter = pkgs.flutter335;
        fromYAMLFile = path:
          builtins.fromJSON (
            builtins.readFile (
              pkgs.runCommand "fromYAMLFile" {} ''
                ${pkgs.remarshal}/bin/remarshal -if yaml -i "${path}" -of json -o $out
              ''
            )
          );
      in {
        devShells.default = let
          androidConfig = {
            # AGP defaults to build-tools 35.0.0, while the app's compileSdk 36 wants
            # 36.0.0.
            buildToolsVersions = ["35.0.0" "36.0.0"];
            # The app compiles against 36, but plugins still declare their own older
            # compileSdk (media_kit_libs_android_audio 31, flutter_displaymode 33,
            # audio_session 34, ...). AGP fails the build when a plugin's platform is
            # absent, and it cannot install it because this SDK is read-only.
            platformVersions = ["31" "32" "33" "34" "35" "36"];
            # a native dependency configures CMake through the SDK's own cmake package
            cmakeVersions = ["3.22.1"];
            abiVersion = "x86_64";
            ndkVersion = "27.0.12077973";
            emulatorPlatformVersion = "36";
          };

          androidComposition = pkgs.androidenv.composeAndroidPackages (with androidConfig; {
            inherit buildToolsVersions platformVersions cmakeVersions;
            abiVersions = [abiVersion];
            includeNDK = true;
            inherit ndkVersion;
          });
          androidSdk = androidComposition.androidsdk;

          emulator = pkgs.androidenv.emulateApp {
            name = "emulator";
            platformVersion = androidConfig.emulatorPlatformVersion;
            abiVersion = androidConfig.abiVersion;
            systemImageType = "google_apis_playstore";
          };
        in
          pkgs.mkShell rec {
            packages = with pkgs; [
              flutter
              android-tools
              temurin-bin-21
              androidSdk
              emulator
            ];

            ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
            ANDROID_SDK_ROOT = ANDROID_HOME;
            ANDROID_NDK_ROOT = "${androidSdk}/libexec/android-sdk/ndk/${androidConfig.ndkVersion}";
            JAVA_HOME = "${pkgs.temurin-bin-21}";

            # flutter prefers its own settings file (~/.config/flutter/settings) over
            # ANDROID_HOME when locating the SDK, and that file outlives this repo, so a
            # stale path in it would outlive any change to the SDK in this flake.
            shellHook = ''
              flutter config --android-sdk "$ANDROID_SDK_ROOT" >/dev/null 2>&1 || true
            '';
          };
        packages.default = flutter.buildFlutterApplication rec {
          pname = "asterfox";
          src = self;
          version = (fromYAMLFile "${src}/pubspec.yaml").version;

          nativeBuildInputs = with pkgs; [
            pkg-config
          ];

          propagatedBuildInputs = with pkgs; [
            mpv
          ];

          autoDepsList = true;
          autoPubspecLock = "${src}/pubspec.lock";

          gitHashes = {
            receive_sharing_intent = "sha256-8D5ZENARPZ7FGrdIErxOoV3Ao35/XoQ2tleegI42ZUY=";
            youtube_explode_dart = "sha256-lKjNaQqi58vBZ12Nvx/kYJ/35kHxeyFiZEajyF4Pt5A=";
          };

          preBuild = ''
            flutter gen-l10n

            mkdir -p .git/refs/heads
            echo "ref: refs/heads/nix" > .git/HEAD
            echo "${self.rev or "unknown"}" > .git/refs/heads/nix
          '';

          postFixup = ''
            wrapProgram $out/bin/asterfox \
              --set LD_LIBRARY_PATH ${pkgs.lib.makeLibraryPath [pkgs.mpv]}
          '';
        };
      }
    );
}
