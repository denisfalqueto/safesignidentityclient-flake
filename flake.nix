{
  description = "SafeSign Identity Client flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    wxGTK30 = {
      url = ./wxGTK30;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    wxGTK30,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
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
        runtimeDependencies = [
          "/usr/bin/tokenadmin"
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
      in rec {
        formatter = pkgs.alejandra;

        packages = {
          safesignidentityclient = stdenv.mkDerivation rec {
            inherit buildInputs;

            # Indica para o autoPatchelfHook que o executável principal pode abrir
            # shared objects em tempo de execução
            inherit runtimeDependencies;

            pname = "safesignidentityclient";
            version = "4.0.0.0";

            src = pkgs.fetchurl {
              url = "https://certificaat.kpn.com/files/drivers/SafeSign/SafeSign%20IC%20Standard%20Linux%20${version}-AET.000%20ub2204%20x86_64.deb";
              hash = "sha256-L8KeDl38PmLTauSfMiXHIc6ad2Lso3ZfsydCvBcibfg=";
            };

            # Dependências de buildtime
            nativeBuildInputs = with pkgs; [
              dpkg
              autoPatchelfHook
              wrapGAppsHook3
            ];

            installPhase = ''
              runHook preInstall

              install -d $out/usr
              cp -R usr/{bin,share,lib} $out/usr/

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
          };

          default = self.packages.${system}.safesignidentityclient;
        };

        defaultPackage = self.packages.${system}.safesignidentityclient;

        apps = {
          tokenadmin = {
            type = "app";
            program = "${self.defaultPackage}/usr/bin/tokenadmin";
          };
        };

        nixosModules = {
          config = {
            environment.systemPackages = [self.defaultPackage.${system}];
          };
        };
      }
    );
}
