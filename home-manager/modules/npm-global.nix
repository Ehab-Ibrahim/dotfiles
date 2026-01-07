{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  # User-defined npm packages (latest versions only)
  npmPackages = config.home.npmGlobal.packages or [];

  # Convert to space-separated string for shell
  npmPackagesStr = concatStringsSep " " npmPackages;

  # Read the script content and write it to a file in the Nix store
  # Read the nushell script content
  manageNpmScriptContent = builtins.readFile ./manage_npm.nu;

  # Create an executable script in the Nix store with a Nushell shebang
  manageNpmScriptFile = pkgs.writeScript "manage_npm" ''
    #!${pkgs.nushell}/bin/nu
    ${manageNpmScriptContent}
  '';
in {
  options.home.npmGlobal.packages = mkOption {
    type = types.listOf types.str;
    default = [];
    description = ''
      List of npm packages to install globally (latest versions only).
      Each entry is a string with the package name, e.g. "typescript" or "@scope/pkg".
    '';
  };

  config = {
    # Ensure Node.js 24 is installed
    home.packages = [pkgs.nodejs_24];

    # Set npm global prefix
    home.file.".npmrc".text = ''
      prefix=${config.home.homeDirectory}/.npm/global
    '';

    # Add npm global bin to PATH
    home.sessionPath = [
      "${config.home.homeDirectory}/.npm/global/bin"
    ];

    # Activation script
    home.activation.manageNpmPackages = ''
      export PATH="${pkgs.nodejs_24}/bin/:$PATH"
      ${manageNpmScriptFile} ${lib.escapeShellArg npmPackagesStr}
    '';
  };
}
