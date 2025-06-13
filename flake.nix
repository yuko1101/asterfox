{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        fromYAMLFile =
          path:
          builtins.fromJSON (
            builtins.readFile (
              pkgs.runCommand "fromYAMLFile" { } ''
                ${pkgs.remarshal}/bin/remarshal -if yaml -i "${path}" -of json -o $out
              ''
            )
          );
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
          ];

          buildInputs = with pkgs; [
          ];

          packages = with pkgs; [
            flutter
            android-tools
            temurin-bin-17
          ];

          LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath (
            with pkgs;
            [
              # to launch android emulators (e.g. ldd path/to/android-sdk/emulator/lib64/qt/plugins/platforms/libqxcbAndroidEmu.so)
              libpulseaudio
              libpng
              libdrm
              xorg.libXi
              xorg.libxkbfile
              libbsd
              xorg.libxcb
              libxkbcommon
              xorg.libX11
              xcb-util-cursor
              libcxx
              xorg.libSM
              xorg.libICE
              xorg.xcbutilrenderutil
              xorg.xcbutilkeysyms
              xorg.xcbutilimage
              xorg.xcbutilwm
            ]
          )}";
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

          gitHashes = {
            firebase_auth = "sha256-JiLugiDGod07ynW7MCWCBxDtkjvqRT+dZzHbizLGMNc=";
          };

          preBuild = ''
            flutter gen-l10n

            mkdir -p .git/refs/heads
            echo "ref: refs/heads/nix" > .git/HEAD
            echo "${src}" > .git/refs/heads/nix
          '';

          postFixup = ''
            wrapProgram $out/bin/asterfox \
              --set LD_LIBRARY_PATH ${pkgs.lib.makeLibraryPath [ pkgs.mpv ]}
          '';
        };
      }
    );
}
