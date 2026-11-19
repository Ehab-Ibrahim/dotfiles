{...}: {
  # Enable home-manager
  programs.home-manager.enable = true;
  news.display = "silent";

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
