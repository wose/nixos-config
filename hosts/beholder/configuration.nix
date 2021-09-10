{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../users/wose.nix
    ../../users/linda.nix
  ];

  
  boot.kernelParams = [
    "net.ifnames=0"
    "ip=136.243.47.110::136.243.47.65:255.255.255.192:beholder:eth0:none"
  ];
  

  
  boot.loader.grub = {
    enable = true;
    version = 2;
    efiSupport = false;
    devices = [ "/dev/sda" ];
    mirroredBoots = [
      {
        path = "/boot-fallback";
        devices = [ "/dev/sdb" ];
      }
    ];
  };
  

  
  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 22;
      authorizedKeys = config.users.users.wose.openssh.authorizedKeys.keys;
      hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
    };
  };
  

  
  networking = {
    hostName = "beholder";
    domain = "zuendmasse.de";
  };
  
  networking = {
    usePredictableInterfaceNames = false;
  
    useDHCP = false;
    interfaces.eth0 = {
      ipv4.addresses = [
        {
          address = "136.243.47.110";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2a01:4f8:212:f45::1";
          prefixLength = 64;
        }
      ];
    };
  
    defaultGateway = "136.243.47.65";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
  };
  
  networking.nameservers = [
    "213.133.98.98"
    "213.133.99.99"
    "213.133.100.100"
    "2a01:4f8:0:a0a1::add:1010"
    "2a01:4f8:0:a102::add:9999"
    "2a01:4f8:0:a111::add:9898"
    "8.8.8.8"
  ];
  

  
  time.timeZone = "Europe/Berlin";
  
  i18n.defaultLocale = "en_US.UTF-8";
  

  environment.systemPackages = with pkgs; [
    emacs-nox
    fd
    pinentry-emacs
    ripgrep
  ];

  

  system.stateVersion = "21.05";
}