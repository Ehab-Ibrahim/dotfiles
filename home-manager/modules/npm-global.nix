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

  # Package names without version: "@scope/pkg@1.2" -> "@scope/pkg"
  npmPackageNames = map (p: head (builtins.match "(@?[^@]+)(@.*)?" p)) npmPackages;

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
    # Ensure Node.js 24 and nushell (which runs manage_npm.nu) are installed
    home.packages = [pkgs.nodejs_24 pkgs.nushell];

    # Set npm global prefix
    home.file.".npmrc".text =
      ''
        prefix=${config.home.homeDirectory}/.npm/global
      ''
      # Trust install scripts of every declared package (version suffix stripped)
      + optionalString (npmPackages != []) ''
        allow-scripts=${concatStringsSep "," npmPackageNames}
      '';

    # Add npm global bin to PATH
    home.sessionPath = [
      "${config.home.homeDirectory}/.npm/global/bin"
    ];

    # After linkGeneration so ~/.npmrc exists; npm 11 `ls -g` fails without prefix/lib
    home.activation.manageNpmPackages = lib.hm.dag.entryAfter ["linkGeneration"] ''
      run mkdir -p "${config.home.homeDirectory}/.npm/global/lib"
      export PATH="${pkgs.nodejs_24}/bin/:$PATH"
      ${manageNpmScriptFile} ${lib.escapeShellArg npmPackagesStr}
    '';
  };
}
