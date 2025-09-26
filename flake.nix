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
            buildToolsVersion = "34.0.0";
            platformVersion = "34";
            abiVersion = "x86_64";
          };

          androidComposition = pkgs.androidenv.composeAndroidPackages (with androidConfig; {
            buildToolsVersions = [buildToolsVersion];
            platformVersions = [platformVersion];
            abiVersions = [abiVersion];
          });
          androidSdk = androidComposition.androidsdk;

          emulator = pkgs.androidenv.emulateApp {
            name = "emulator";
            inherit (androidConfig) platformVersion abiVersion;
            systemImageType = "google_apis_playstore";
          };
        in
          pkgs.mkShell {
            packages = with pkgs; [
              flutter
              android-tools
              temurin-bin-17
              androidSdk
              emulator
            ];

            ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          };
        packages.default = pkgs.flutter.buildFlutterApplication rec {
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

          preBuild = ''
            flutter gen-l10n

            mkdir -p .git/refs/heads
            echo "ref: refs/heads/nix" > .git/HEAD
            echo "${self.rev}" > .git/refs/heads/nix
          '';

          postFixup = ''
            wrapProgram $out/bin/asterfox \
              --set LD_LIBRARY_PATH ${pkgs.lib.makeLibraryPath [pkgs.mpv]}
          '';
        };
      }
    );
}
