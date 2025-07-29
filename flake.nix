{
  description = "A very basic flake with picoprobe build capabilities";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    ,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages."x86_64-linux";
        pico-sdk-211 = with pkgs; (pico-sdk.overrideAttrs (o: rec {
          pname = "pico-sdk";
          version = "2.1.1";
          src = fetchFromGitHub {
            fetchSubmodules = true; # TinyUSB not included in store package
            owner = "raspberrypi";
            repo = pname;
            rev = version;
            sha256 = "sha256-8ru1uGjs11S2yQ+aRAvzU53K8mreZ+CC3H+ijfctuqg=";
          };
        }));
      in
      with pkgs; {
        devShell = mkShell {
          buildInputs = [
            openocd-rp2040
            cmake
            python3
            gcc-arm-embedded
            pico-sdk-211
            picotool
          ];
          PICO_SDK_PATH = "${pico-sdk}/lib/pico-sdk";
          PICO_BOARD = "pico";
          PICO_PLATFORM = "rp2040";
          PICO_COMPILER = "pico_arm_cortex_m0plus_gcc";
        };

        shellHook = ''
          echo "Welcome to the pico debug devshell"
        '';

        packages.buildScript = pkgs.writeShellApplication {
          name = "build-and-test";
          runtimeInputs = with pkgs; [
            cmake
            gcc-arm-embedded
            pico-sdk-211
          ];
          runtimeEnv = {
            PICO_SDK_PATH = "${pkgs.pico-sdk}/lib/pico-sdk";
            PICO_BOARD = "pico";
            PICO_PLATFORM = "rp2040";
            PICO_COMPILER = "pico_arm_cortex_m0plus_gcc";
          };
          text = ''
            echo "Removing cache"
                     rm -f CMakeCache.txt
            echo "Running cmake"
                     cmake .
            echo "Running make"
                     make -j 4
          '';
        };
      }
    );
}
