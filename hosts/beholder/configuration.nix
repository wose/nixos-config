{ config, pkgs, mailserver, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/nginx.nix
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

  
  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
  };
  
  services.nginx.virtualHosts."erlija.de" = {
    serverAliases = [ "www.erlija.de" "erlija.de" ];
    enableACME = true;
    forceSSL = true;
    root = "/var/www/erlija.de";
  };
  
  services.nginx.virtualHosts."zuendmasse.de" = {
    serverAliases = [ "zuendmasse.de" "www.zuendmasse.de" ];
    enableACME = true;
    forceSSL = true;
  
    locations."/" = {
      root = "/var/www/zuendmasse.de";
    };
  
    listen = [
      { addr = "[::]";    port = 80; ssl = false; }
      { addr = "0.0.0.0"; port = 80; ssl = false; }
      { addr = "[::]";    port = 443; ssl = true; }
      { addr = "0.0.0.0"; port = 443; ssl = true; }
      { addr = "[::]";    port = 8448; ssl = true; }
      { addr = "0.0.0.0"; port = 8448; ssl = true; }
    ];
  
    locations."/_matrix" = {
      proxyPass = "http://localhost:8008";
    };
  
    locations."= /.well-known/matrix/server".extraConfig =
      let
        server = { "m.server" = "zuendmase.de:8448"; };
      in ''
        add_header Content-Type application/json;
        return 200 '${builtins.toJSON server}';
      '';
  
    locations."= /.well-known/matrix/client".extraConfig =
      let
        client = {
          "m.homeserver" = { "base_url" = "https://zuendmasse.de:8448"; };
          "m.identity_server" = { "base_url" = "https://vector.im"; };
        };
      in ''
        add_header Content-Type application/json;
        add_header Access-Control-Allow-Origin *;
        return 200 '${builtins.toJSON client}';
      '';
  
  };
  
  mailserver = {
    enable = true;
    localDnsResolver = false;
  
    enableImap = true;
    enablePop3 = false;
    enableImapSsl = true;
    enablePop3Ssl = false;
  
    fqdn = "beholder.zuendmasse.de";
    domains = [ "braunglasmafia.de" "erlija.de" ];
  
    loginAccounts = {
      "wose@erlija.de" = {
        hashedPasswordFile = "/home/wose/.hashed_passwd_erlija.de";
        aliases = [
          "postmaster@erlija.de"
          "abuse@erlija.de"
          "webmaster@erlija,de"
          "borsti@braunglasmafia.de"
          "postmaster@braunglasmafia.de"
          "abuse@braunglasmafia.de"
        ];
      };
  
      "linda@erlija.de" = {
        hashedPasswordFile = "/home/linda/.hashed_passwd_erlija.de";
        aliases = [
          "blog@erlija.de"
        ];
      };
    };
  
    certificateScheme = 3;
  };
  
  networking.firewall.allowedTCPPorts = [ 8448 1965];
  
  services.matrix-synapse = {
    enable = true;
    database_type = "sqlite3";
    server_name = "zuendmasse.de";
  
    listeners = [
      {
        port = 8008;
        bind_address = "::1";
        type = "http";
        tls = false;
        x_forwarded = true;
        resources = [
          {
            names = [ "client" "federation" ];
            compress = false;
          }
        ];
      }
    ];
  
    extraConfig = ''
      max_upload_size: "512M"
    '';
  
    allow_guest_access = false;
    enable_registration = false;
  };
  
  services.fail2ban.enable = true;
  
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud22;
    hostName = "cloud.zuendmasse.de";
    https = true;
  
    caching = {
      apcu = true;
      memcached = true;
      redis = false;
    };
  
    config = {
      adminuser = "admin";
      adminpassFile = "/etc/secrets/nextcloud-pass";
      dbtype = "pgsql";
      dbname = "nextcloud";
      dbuser = "nextcloud";
      dbpassFile = "/etc/secrets/psql-pass";
      dbhost = "/run/postgresql";
      dbtableprefix = "oc_";
    };
  
    autoUpdateApps = {
      enable = true;
      startAt = "04:00:00";
    };
  
    maxUploadSize = "2048M";
  };
  
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [
      { name = "nextcloud";
        ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
      }
    ];
  };
  
  systemd.services."nextcloud-setup" = {
    requires = ["postgresql.service"];
    after = ["postgresql.service"];
  };
  
  services.nginx.virtualHosts."cloud.zuendmasse.de" = {
    enableACME = true;
    forceSSL = true;
    extraConfig = ''
      add_header Strict-Transport-Security "max-age=31536000" always;
    '';
  };
  
  services.molly-brown = {
    hostName = "zuendmasse.de";
    enable = true;
    certPath = "/var/lib/acme/zuendmasse.de/cert.pem";
    keyPath = "/var/lib/acme/zuendmasse.de/key.pem";
    docBase = "/var/gemini/zuendmasse.de";
  };
  
  systemd.services.molly-brown.serviceConfig.SupplementaryGroups = [ config.security.acme.certs."zuendmasse.de".group ];
  
  #networking.firewall.allowedTCPPorts = [ 1965 ];
  

  system.stateVersion = "21.05";
}
