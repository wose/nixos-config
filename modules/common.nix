{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    gnupg
    gnutls
    htop
    pass
    pinentry
    vim
    vimPlugins.vim-nix
    wget
    zsh
  ];

  
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  

}
