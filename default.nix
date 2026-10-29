# Builds the 88emu VST plugin (88emuPlayer) from this source tree.
#
#   nix-build                  # -> result/lib/vst3/88emuPlayer.vst3, result/lib/vst/88emuPlayer.so
#   nix build -f . (same)
#
# The submodules in source/3rdparty and source/cpu must be checked out
# (git submodule update --init --recursive); the tree is built as it is.
#
# Standalone invocation falls back to a pinned nixpkgs; a flake or overlay can
# instead `callPackage ./default.nix { pkgs = ...; }` to bring its own.
{
  pkgs ? import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/3497aa5c9457a9d88d71fa93a4a8368816fbeeba.tar.gz";
    sha256 = "sha256-dhhvQY67aboBk8b0/u0XB6vwHdgbROZT3fJAjyNh5Ww=";
  }) { },
}:

let
  inherit (pkgs) lib;
in
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "gearmulator-88emu";
  version = "2.2.28";

  # The working tree, minus VCS metadata and the in-tree build outputs
  # (temp/ is the conventional cmake build dir here, bin/ is TUS_BIN_DIR).
  src = lib.cleanSourceWith {
    name = "gearmulator-src";
    src = ./.;
    filter =
      path: type:
      let
        base = baseNameOf path;
        atRoot = dirOf path == toString ./.;
      in
      # default.nix itself does not influence the build, so leave it out of
      # the fixed source and spare a rebuild when only the packaging changes.
      base != ".git" && !(atRoot && (base == "temp" || base == "bin" || base == "build" || base == "default.nix" || lib.hasPrefix "result" base));
  };

  nativeBuildInputs = with pkgs; [
    cmake
    ninja
    pkg-config
  ];

  buildInputs = with pkgs; [
    alsa-lib
    curl
    fontconfig
    freetype
    libGL
    xorg.libX11
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXext
    xorg.libXinerama
    xorg.libXrandr
    xorg.libXrender
  ];

  cmakeFlags = [
    # Just the 88emu player: VST3, and VST2 against the bundled FST headers.
    (lib.cmakeBool "gearmulator_SYNTH_OSIRUS" false)
    (lib.cmakeBool "gearmulator_SYNTH_OSTIRUS" false)
    (lib.cmakeBool "gearmulator_SYNTH_VAVRA" false)
    (lib.cmakeBool "gearmulator_SYNTH_XENIA" false)
    (lib.cmakeBool "gearmulator_SYNTH_NODALRED2X" false)
    (lib.cmakeBool "gearmulator_SYNTH_JE8086" false)
    (lib.cmakeBool "gearmulator_SYNTH_88EMU" true)
    (lib.cmakeBool "gearmulator_BUILD_JUCEPLUGIN_CLAP" false)
    (lib.cmakeBool "gearmulator_BUILD_INSTALLER" false)
    (lib.cmakeBool "gearmulator_COMPONENT_DSPBRIDGE" false)
  ];

  # juceaide, the VST3 manifest helper and the plugin tests all run built
  # binaries, and JUCE wants somewhere to put per-user state.
  preConfigure = ''
    export HOME=$TMPDIR
  '';

  doCheck = true;
  # The PluginTest label hosts each built plugin format in the project's own
  # pluginTester and processes audio through it; the rest are the 88lib unit tests.
  checkPhase = ''
    runHook preCheck
    ctest --output-on-failure
    runHook postCheck
  '';

  # Install just the plugin components: the default install also runs the
  # bundled 3rdparty libraries' own install rules (RmlUi, lunasvg, ...),
  # which have no place in the product.
  installPhase = ''
    runHook preInstall
    cmake --install . --component 88emuPlayer-VST3
    cmake --install . --component 88emuPlayer-VST2
    runHook postInstall
  '';

  # The components put their license, readme and changelog at the prefix root.
  postInstall = ''
    mkdir -p $out/share/doc/${finalAttrs.pname}
    for f in "$out"/LICENSE.md "$out"/README.md "$out"/changelog*.txt; do
      if [ -e "$f" ]; then mv "$f" $out/share/doc/${finalAttrs.pname}/; fi
    done
  '';

  meta = {
    description = "88emu (Roland MT-32 / CM / MV-30 / Sound Canvas emulator) as a VST plugin";
    longDescription = ''
      The 88emu player from the Gearmulator project, built as VST3 and VST2
      audio plugins. The emulator runs original device firmware; ROM images
      are not included and must be placed in the plugin's ROM folder.
    '';
    homepage = "https://github.com/dsp56300/gearmulator";
    license = lib.licenses.gpl3Only;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
