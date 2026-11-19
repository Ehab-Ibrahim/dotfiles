{...}: {
  imports = [../modules/npm-global.nix];
  # Copilot/Gemini CLI
  home.npmGlobal.packages = [
    "@anthropic-ai/claude-code"
    "@opencode/cli"
  ];
}
