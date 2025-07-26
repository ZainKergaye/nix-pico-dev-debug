{
  description = "A very basic flake with picoprobe build capabilities";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    picoprobe = {
      flake = false;
      url = "github:raspberrypi/picoprobe";
    };
    freeRTOS-kernel = {
      flake = false;
      url = "github:FreeRTOS/FreeRTOS-kernel";
    };
  };

  outputs =
    { self
    , nixpkgs
    , picoprobe
    , freeRTOS-kernel
    ,
    }:
    let
      pkgs = nixpkgs.legacyPackages."x86_64-linux";

      freeRTOSKernel = pkgs.fetchFromGitHub {
        owner = "FreeRTOS";
        repo = "FreeRTOS-Kernel";
        rev = "0030d609a4b99118d9a400340d88c3c3c4816f2b"; # The specific commit hash
        sha256 = "sha256-uiAXeuyE40fMf14dfgf0WW3agd+93L/akfABWcXfOjA=";
      };

      # Define the picoprobe package
      picoprobePackage = pkgs.stdenv.mkDerivation {
        name = "picoprobe";
        src = picoprobe;

        buildInputs = with pkgs; [
          cmake
          gcc-arm-embedded # Required for ARM cross-compilation
          gnumake
          pico-sdk
          libtool
          automake
          libusb
          wget
          pkg-config
          gcc
          texinfo
        ];

        env = {
          DPICO_SDK_PATH = "${pkgs.pico-sdk}/lib/pico-sdk";
          PICO_BOARD = "pico";
          DFREERTOS_DIR = "${freeRTOSKernel}";
        };

        configurePhase = ''
                 mkdir -p $out/build
                 cd $out/build
                 cmake . -G "Unix Makefiles" \
                   -DCMAKE_BUILD_TYPE=Release \
                   -DFREERTOS_DIR=${freeRTOSKernel} \
          -DPICO_SDK_PATH=${pkgs.pico-sdk}/lib/pico-sdk
        '';

        buildPhase = ''
          cd $out/build
          make
        '';

        installPhase = ''
          mkdir -p $out/bin
          cp $out/build/probe $out/bin/
        '';
      };
    in
    {
      devShells."x86_64-linux".default = pkgs.mkShell {
        packages = with pkgs; [
          openocd-rp2040
          cmake
          python3
          gcc-arm-embedded
          newlib
        ];
        shellHook = ''
          echo "Welcome to the pico debug devshell"
        '';
      };

      # Add an output for the picoprobe package itself
      packages."x86_64-linux".picoprobe = picoprobePackage;
      packages.x86_64-linux.default = self.packages.x86_64-linux.picoprobe;
    };
}
