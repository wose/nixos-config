{ pkgs, lib, ... }:

{
  
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  
  security.acme.defaults.email = lib.mkDefault "ca@zuendmasse.de";
  security.acme.acceptTerms = true;
  
  services.nginx = {
    enable = true;
  
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  
    sslCiphers = "TLSv1.2+HIGH+ECDHE@STRENGTH";
  };
  
}
