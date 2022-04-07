{ pkgs ? import <nixpkgs> { } }:

{
  gotosocial = pkgs.callPackage ./gotosocial { };
  misskey = pkgs.callPackage ./misskey { };
}
