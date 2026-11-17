{config, ...}: let
  name = "Ehab Ibrahim";
  email = "e.m.ibrahim@outlook.com";
  workEmail = "ehab.ibrahim@magics.tech";
  signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICue7k+YhwVJinX1QZQH6gtUfX2VJ98Ho/ptS6YMrtG";
in {
  programs.git = {
    enable = true;
    settings = {
      user.name = name;
      user.email = email;
      merge.conflictstyle = "zdiff3";
      pull.ff = true;
      pull.rebase = true;
      # Configure signing commits with SSH
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
      user.signingKey = "key::${signingKey}";
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
        email = ${workEmail}
  '';
  home.file."projects/ehab/.gitconfig".text = ''
    [user]
        email = ${email}
  '';

  xdg.configFile."git/allowed_signers".text = ''
    ${email} ${signingKey}
  '';
}
