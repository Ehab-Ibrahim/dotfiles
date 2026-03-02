## Formats a package record back into an npm package string.
def pkg_to_str []: record -> string {
  let name = if $in.scoped { $"@($in.pkg)" } else { $in.pkg }
  if $in.ver != null { $"($name)@($in.ver)" } else { $name }
}

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
    | each {|line|
        # Notice the space before " @"
        if ($line | str contains " @") {
          $line | parse "{_} @{pkg}@{ver}" | first | insert scoped true
        } else {
          $line | parse "{_} {pkg}@{ver}" | first | insert scoped false
        }
      }
  )

  # Get wanted packages from argument, and parse to a table.
  # Supports: <pkg>, <pkg>@<ver>, @<pkg>, @<pkg>@<ver>
  let wanted = (
    $wanted_pkgs_str
    | str trim
    | split row " "
    | each {|entry|
        let scoped = ($entry | str starts-with "@")
        let parts = ($entry | split row "@" | compact -e)
        { scoped: $scoped, pkg: $parts.0, ver: ($parts | get --optional 1) }
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
  let install_list = (
    $not_installed
    | append $ver_mismatch
    | each { pkg_to_str }
  )

  if not ($install_list | is-empty) {
    print $"Installing npm packages: ($install_list)"
    npm install -g ...$install_list
  }

  # Find packages to remove (in installed but not in wanted).
  let remove_list = (
    $installed
    | where $it.pkg not-in $wanted.pkg
    | each { pkg_to_str }
  )

  if not ($remove_list | is-empty) {
    print $"Removing npm packages: ($remove_list)"
    npm uninstall -g ...$remove_list
  }
}
