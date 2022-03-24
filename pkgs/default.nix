{ pkgs ? import <nixpkgs> { } }:

{
  gotosocial = pkgs.callPackage ./gotosocial { };
}
