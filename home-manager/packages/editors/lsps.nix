{
  config,
  pkgs,
  ...
}: let
  # clangd releases are now hosted under https://github.com/clangd/clangd/releases
  version = "21.1.0";
  clangdUrl = "https://github.com/clangd/clangd/releases/download/${version}/clangd-linux-${version}.zip";

  clangdStandalone = pkgs.stdenv.mkDerivation {
    pname = "clangd-standalone";
    inherit version;

    src = pkgs.fetchurl {
      url = clangdUrl;
      sha256 = "sha256-2aLo3V37to2JLCtR86c1tSYUj++JFB/+pu5/+GN/0aY=";
    };
    nativeBuildInputs = [pkgs.unzip pkgs.autoPatchelfHook];

    installPhase = ''
      mkdir -p $out
      unzip -q $src -d $out
      # Typically extracts to $out/clangd_${version}/bin, so fix layout if needed
      if [ -d "$out/clangd_${version}" ]; then
        mv $out/clangd_${version}/* $out/
        rm -rf $out/clangd_${version}
      fi
    '';

    dontStrip = false;
  };
in {
  home.packages = with pkgs; [
    alejandra
    basedpyright
    clangdStandalone
    nil
    ruff
    tombi
    tree-sitter
    verible
    verilator
  ];

  # Install svlangserver
  home.npmGlobal.packages = ["@imc-trading/svlangserver"];
}
