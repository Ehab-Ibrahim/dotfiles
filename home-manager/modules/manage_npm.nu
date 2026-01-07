## Manages global npm packages, installing wanted and removing unlisted ones.
def main [
    wanted_pkgs_str: string # A space-separated string of desired npm packages
] {
  # Get currently installed packages.
  let installed = (
    npm ls -g --depth 0
    | lines
    | skip 1
    | compact -e
    | parse "{_} @{pkg}@{ver}"
  )

  # Get wanted packages from argument, and parse to a table
  let wanted = (
    $wanted_pkgs_str
    | str trim
    | split row " "
    | each {
      split row "@"
      | compact -e
      | { pkg: $in.0, ver: $in.1? }
    }
  )

  # Find packages to install (in wanted but not in installed).
  let not_installed = $wanted | where $it.pkg not-in $installed.pkg
  let ver_mismatch = (
    $wanted
    # Filter packages that are already installed
    | where $it.pkg in $installed.pkg
    # Remove packages with no version specified
    | compact "ver"
    # Filter packages with version mismatch
    | where $it.ver != ($installed | where pkg == $it.pkg | get 0.ver)
  )
  let install_table = $not_installed | append $ver_mismatch
  let install_list = (
    $install_table
    | each {
      if $in.ver != null { $"@($in.pkg)@($in.ver)" } else { $"@($in.pkg)" }
    }
  )

  if not ($install_list | is-empty) {
    print $"Installing npm packages: ($install_list)"
    npm install -g ...$install_list
  }

  # Find packages to remove (in installed but not in wanted).
  let remove_table = $installed | where $it.pkg not-in $wanted.pkg
  let remove_list = $remove_table | each { $"@($in.pkg)" }

  if not ($remove_list | is-empty) {
    print $"Removing npm packages: ($remove_list)"
    npm uninstall -g ...$remove_list
  }
}
