{pkgs, ...}: {
  # SystemVerilog language servers, linting and formatting, used by the Helix
  # and Neovim configs; per-project settings go in .slang/server.json
  home.packages = with pkgs; [
    slang-server
    # slang's command-line tools (`slang`); nixpkgs' `slang` is the unrelated S-Lang
    sv-lang
    verible
  ];
}
