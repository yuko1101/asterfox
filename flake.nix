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
      }
    );
}
