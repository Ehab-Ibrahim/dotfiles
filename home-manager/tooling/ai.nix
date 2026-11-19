{
  inputs,
  pkgs,
  ...
}: let
  agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  # OpenCode 2.x ships as `opencode2`
  opencode = pkgs.runCommand "opencode" {} ''
    mkdir -p $out/bin
    ln -s ${agents.opencode2}/bin/opencode2 $out/bin/opencode
  '';
in {
  # Update: nix flake update llm-agents
  home.packages = [agents.claude-code opencode];

  # Binary cache for llm-agents
  nix.settings = {
    extra-substituters = ["https://cache.numtide.com"];
    extra-trusted-public-keys = ["niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="];
  };
}
