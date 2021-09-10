{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    gnupg
    gnutls
    htop
    pass
    vim
    vimPlugins.vim-nix
    wget
    zsh
  ];
}
