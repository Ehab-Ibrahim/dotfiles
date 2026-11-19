{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    img2pdf
    poppler-utils
    tdf
  ];
}
