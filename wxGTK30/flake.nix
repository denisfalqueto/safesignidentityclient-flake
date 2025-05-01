{
  description = "WxWidgets 3.0";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
    };
    lib = pkgs.lib;
    stdenv = pkgs.stdenv;
    fetchFromGitHub = pkgs.fetchFromGitHub;
  in rec {
    formatter.${system} = pkgs.alejandra;

    packages.${system} = {
      wxGTK30 = stdenv.mkDerivation rec {
        pname = "wxwidgets";
        version = "3.0.5.1";

        src = fetchFromGitHub {
          owner = "wxWidgets";
          repo = "wxWidgets";
          rev = "v${version}";
          hash = "sha256-I91douzXDAfDgm4Pplf17iepv4vIRhXZDRFl9keJJq0=";
          fetchSubmodules = true;
        };

        nativeBuildInputs = [pkgs.pkg-config];

        buildInputs =
          [
            pkgs.gst_all_1.gst-plugins-base
            pkgs.gst_all_1.gstreamer
          ]
          ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
            pkgs.gtk3
            pkgs.xorg.libSM
            pkgs.xorg.libXinerama
            pkgs.xorg.libXtst
            pkgs.xorg.libXxf86vm
            pkgs.xorg.xorgproto
            pkgs.curl
            pkgs.libGLU
          ]
          ++ lib.optional (!stdenv.hostPlatform.isDarwin) pkgs.webkitgtk_4_0
          ++ lib.optionals stdenv.hostPlatform.isDarwin [
            pkgs.libpng
          ];

        configureFlags =
          [
            "--disable-precomp-headers"
            # This is the default option, but be explicit
            "--disable-monolithic"
            "--enable-mediactrl"
            "--enable-unicode"
            "--enable-webrequest"
            "--enable-privatefonts"
            "--with-opengl"
          ]
          ++ lib.optionals stdenv.hostPlatform.isDarwin [
            "--with-osx_cocoa"
            "--with-libiconv"
          ];

        SEARCH_LIB = lib.optionalString (!stdenv.hostPlatform.isDarwin) "${pkgs.libGLU.out}/lib ${pkgs.libGL.out}/lib ";

        preConfigure = ''
          export CPPFLAGS="-fabi-version=16"
          substituteInPlace configure --replace \
            'SEARCH_INCLUDE=' 'DUMMY_SEARCH_INCLUDE='
          substituteInPlace configure --replace \
            'SEARCH_LIB=' 'DUMMY_SEARCH_LIB='
          substituteInPlace configure --replace \
            /usr /no-such-path
        '';

        postInstall = "
          pushd $out/include
          ln -s wx-*/* .
          popd
        ";

        enableParallelBuilding = true;

        meta = with lib; {
          homepage = "https://www.wxwidgets.org/";
          description = "Cross-Platform C++ GUI Library";
          longDescription = ''
            wxWidgets gives you a single, easy-to-use API for writing GUI applications
            on multiple platforms that still utilize the native platform's controls
            and utilities. Link with the appropriate library for your platform and
            compiler, and your application will adopt the look and feel appropriate to
            that platform. On top of great GUI functionality, wxWidgets gives you:
            online help, network programming, streams, clipboard and drag and drop,
            multithreading, image loading and saving in a variety of popular formats,
            database support, HTML viewing and printing, and much more.
          '';
          license = licenses.wxWindows;
          maintainers = with maintainers; [tfmoraes];
          platforms = platforms.unix;
        };
      };

      default = packages.${system}.wxGTK30;
    };
  };
}
