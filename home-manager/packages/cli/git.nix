{
  secrets,
  config,
  ...
}: {
  programs.git = {
    enable = true;
    settings = {
      user.name = secrets.name;
      user.email = secrets.outlook;
      merge.conflictstyle = "zdiff3";
      pull.ff = true;
      pull.rebase = true;
      # Configure signing commits with SSH
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
      user.signingKey = "key::${secrets.git_signing_key}";
      commit.gpgsign = true;
    };
    includes = [
      {
        path = "~/projects/magics/.gitconfig";
        condition = "gitdir:~/projects/magics/";
      }
      {
        path = "~/projects/ehab/.gitconfig";
        condition = "gitdir:~/projects/ehab/";
      }
    ];
  };

  home.file."projects/magics/.gitconfig".text = ''
    [user]
        email = ${secrets.magics_mail}
  '';
  home.file."projects/ehab/.gitconfig".text = ''
    [user]
        email = ${secrets.outlook}
  '';

  xdg.configFile."git/allowed_signers".text = ''
    ${secrets.outlook} ${secrets.git_signing_key}
  '';
}
