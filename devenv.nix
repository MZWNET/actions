{pkgs, ...}: {
  packages = with pkgs; [
    act
    actionlint
  ];

  enterTest = ''
    act --version
    actionlint -version
  '';
}
