## Manages global npm packages, installing wanted and removing unlisted ones.
def main [
    wanted_pkgs_str: string # A space-separated string of desired npm packages
] {
  # Get currently installed packages from JSON output for reliable parsing.
  let installed = (
    npm ls -g --depth 0 --json
    | from json
    | get --optional dependencies
    | default {}
    | items {|pkg, info| { pkg: $pkg, ver: $info.version } }
  )

  # Parse wanted packages string into a table.
  # Supports: <pkg>, <pkg>@<ver>, @<scope/pkg>, @<scope/pkg>@<ver>
  let wanted = (
    $wanted_pkgs_str
    | str trim
    | split row " "
    | each {|entry|
        let scoped = ($entry | str starts-with "@")
        let parts = ($entry | split row "@" | compact -e)
        { pkg: (if $scoped { $"@($parts.0)" } else { $parts.0 }), ver: ($parts | get --optional 1) }
      }
  )

  # Find packages to install (not installed, or installed with a version mismatch).
  let not_installed = $wanted | where $it.pkg not-in $installed.pkg
  let ver_mismatch = (
    $wanted
    | where $it.pkg in $installed.pkg
    | where $it.ver != null
    | where $it.ver != ($installed | where pkg == $it.pkg | get 0.ver)
  )
  let install_list = (
    $not_installed
    | append $ver_mismatch
    | each { if $in.ver != null { $"($in.pkg)@($in.ver)" } else { $in.pkg } }
  )

  if not ($install_list | is-empty) {
    print $"Installing npm packages: ($install_list)"
    npm install -g ...$install_list
  }

  # Find packages to remove (in installed but not in wanted).
  # npm uninstall does not accept name@version, only the package name.
  let remove_list = (
    $installed
    | where $it.pkg not-in $wanted.pkg
    | get pkg
  )

  if not ($remove_list | is-empty) {
    print $"Removing npm packages: ($remove_list)"
    npm uninstall -g ...$remove_list
  }
}
