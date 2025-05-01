{
  description = "SafeSign Identity Client flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    wxGTK30.url = ./wxGTK30;
  };

  outputs = {
    nixpkgs,
    wxGTK30,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = {
        permittedInsecurePackages = [
          "openssl-1.1.1w"
        ];
        allowUnfree = true;
      };
    };
    lib = pkgs.lib;
    stdenv = pkgs.stdenv;
  in rec {
    formatter.${system} = pkgs.alejandra;

    packages.${system} = {
      safesignidentityclient = stdenv.mkDerivation (finalAttrs: rec {
        pname = "safesignidentityclient";
        version = "4.0.0.0";

        src = pkgs.fetchurl {
          url = "https://certificaat.kpn.com/files/drivers/SafeSign/SafeSign%20IC%20Standard%20Linux%20${version}-AET.000%20ub2204%20x86_64.deb";
          hash = "sha256-L8KeDl38PmLTauSfMiXHIc6ad2Lso3ZfsydCvBcibfg=";
        };

        unpackCmd = ''
          dpkg -x $curSrc source
        '';

        # Dependências de buildtime
        nativeBuildInputs = with pkgs; [
          unzip
          dpkg
          autoPatchelfHook
          wrapGAppsHook3
        ];

        # Dependências de runtime
        buildInputs = with pkgs; [
          gcc
          glib
          glibc
          hicolor-icon-theme
          pcsclite
          cairo
          pango
          gdk-pixbuf
          at-spi2-core
          gtk3
          wxGTK30.packages.${system}.default
          openssl
          gdbm
          ccid
          acsccid
          scmccid
        ];

        installPhase = ''
          runHook preInstall

          install -d $out/usr
          cp -R usr/{bin,share} $out/usr/

          install -d $out/usr/lib
          cp -R usr/lib/. $out/usr/lib/

          install -d $out/usr/share/licenses/${pname}
          install -m 644 usr/share/doc/${pname}/copyright $out/usr/share/licenses/${pname}/copyright

          runHook postInstall
        '';

        meta = {
          description = "Smart Card driver for a class of devices produced by SafeSign";
          homepage = "https://certificaat.kpn.com/installatie-en-gebruik/installatie/pas-usb-stick/linux/";
          platforms = ["${system}"];
          mainProgram = "safesignidentityclient";
          sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
        };
      });

      default = packages.${system}.safesignidentityclient;
    };
  };
}
