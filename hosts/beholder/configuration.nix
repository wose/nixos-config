{ config, lib, pkgs, mailserver, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/nginx.nix
    ../../modules/misskey.nix
    ../../users/wose.nix
    ../../users/linda.nix
  ];

  
  boot.kernelParams = [
    "net.ifnames=0"
    "ip=136.243.47.110::136.243.47.65:255.255.255.192:beholder:eth0:none"
  ];
  

  
  boot.loader.grub = {
    enable = true;
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
    borgbackup
    emacs-nox
    fd
    pinentry-emacs
    ripgrep
  ];

  
  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "nextcloud"
      "misskey"
    ];
    ensureUsers = [
      { name = "nextcloud";
        ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
      }
      { name = "misskey";
        ensurePermissions."DATABASE misskey" = "ALL PRIVILEGES";
      }
    ];
  };
  
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
  
  services.nginx.virtualHosts."erlija.de" = {
    serverAliases = [ "www.erlija.de" "erlija.de" ];
    enableACME = true;
    forceSSL = true;
    root = "/var/www/erlija.de";
  };
  
  services.nginx.virtualHosts."wittch.de" = {
    serverAliases = [ "www.wittch.de" "wittch.de" ];
    enableACME = true;
    forceSSL = true;
    root = "/var/www/wittch.de";
  };
  
  services.nginx.virtualHosts."zuendmasse.de" = {
    serverAliases = [ "zuendmasse.de" "www.zuendmasse.de" ];
    enableACME = true;
    forceSSL = true;
  
    locations."/" = {
      root = "/var/www/zuendmasse.de";
      extraConfig = ''
        rewrite ^/blog/2018/02/23/lets-write-an-embedded-hal-driver.*$ /lets-write-an-embedded-hal-driver.html permanent;
        rewrite ^/blog/2018/01/21/gdb-\+-svd.*$ /gdb-svd.html permanent;
        rewrite ^/blog/2018/01/19/pdf-multi-view.*$ /multi-view-pdf.html permanent;
        rewrite ^/blog/2017/11/03/datenspuren.*$ /datenspuren.html permanent;
        rewrite ^/blog/2017/08/26/embedded-rust.*$ /embedded-rust.html permanent;
        rewrite ^/blog/2017/08/22/reset.*$ /reset.html permanent;
        rewrite ^/blog/$ / permanent;
        rewrite ^/blog$ / permanent;
        rewrite ^/assets/.*/(.+)$ /images/$1 permanent;
        rewrite ^/about.*$ /pages/about.html permanent;
      '';
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
        server = { "m.server" = "zuendmasse.de:8448"; };
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
    domains = [ "braunglasmafia.de" "erlija.de" "wittch.de" ];
  
    loginAccounts = {
      "wose@erlija.de" = {
        hashedPasswordFile = "/home/wose/.hashed_passwd_erlija.de";
        aliases = [
          "postmaster@erlija.de"
          "abuse@erlija.de"
          "webmaster@erlija.de"
          "borsti@braunglasmafia.de"
          "postmaster@braunglasmafia.de"
          "abuse@braunglasmafia.de"
        ];
      };
  
      "wose@wittch.de" = {
        hashedPasswordFile = "/home/wose/.hashed_passwd_wittch.de";
        aliases = [
          "postmaster@wittch.de"
          "abuse@wittch.de"
          "webmaster@wittch.de"
        ];
      };
  
      "linda@erlija.de" = {
        hashedPasswordFile = "/home/linda/.hashed_passwd_erlija.de";
        aliases = [
          "blog@erlija.de"
        ];
      };
    };
  
    certificateScheme = "acme-nginx";
  };
  
  networking.firewall.allowedTCPPorts = [ 8448 1965 6697 ];
  networking.firewall.allowedUDPPorts = [ 2456 2457 2458 ];
  
  services.matrix-synapse = {
    enable = true;
    extraConfigFiles = [
      /etc/secrets/matrix-registration-config
    ];
  #  registration_shared_secret = builtins.readFile /etc/secrets/matrix-registration;
  
    settings = {
      listeners = [
        {
          port = 8008;
          bind_addresses = [ "::1" ];
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
  
      database.name = "sqlite3";
      server_name = "zuendmasse.de";
      allow_guest_access = false;
      enable_registration = false;
      max_upload_size = "512M";
    };
  };
  
  services.gitea = {
      enable = true;
      package = pkgs.forgejo;
      appName = "forgejo";
      settings = {
        service.DISABLE_REGISTRATION = true;
        server = {
          HTTP_PORT = 3200;
          HTTP_ADDR = "127.0.0.1";
          DOMAIN = "git.zuendmasse.de";
          ROOT_URL = "https://git.zuendmasse.de";
          LANDING_PAGE = "/explore/repos";
        };
      };
    };
  
  services.nginx.virtualHosts."git.zuendmasse.de" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:3200";
    };
  };
  
  services.fail2ban.enable = true;
  
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud27;
    hostName = "cloud.zuendmasse.de";
    https = true;
    enableBrokenCiphersForSSE = false;
  
    caching = {
      apcu = true;
      memcached = true;
      redis = false;
    };
  
    config = {
      defaultPhoneRegion = "DE";
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
  
  systemd.services."nextcloud-setup" = {
    requires = ["postgresql.service"];
    after = ["postgresql.service"];
  };
  
  services.nginx.virtualHosts."cloud.zuendmasse.de" = {
    enableACME = true;
    forceSSL = true;
    extraConfig = ''
      add_header Strict-Transport-Security "max-age=31536000" always;
      client_body_buffer_size 512k;
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
  
  services.misskey = {
    enable = true;
    settings = {
      url = "https://social.zuendmasse.de/";
      port = 11231;
      id = "aid";
      db = {
        host = "/run/postgresql";
        port = config.services.postgresql.port;
        user = "misskey";
        db = "misskey";
      };
      redis = {
        host = "localhost";
        port = config.services.redis.servers.misskey.port;
      };
    };
  };
  
  services.redis.servers.misskey = {
    enable = true;
    bind = "127.0.0.1";
    port = 16434;
  };
  
  services.nginx.virtualHosts."social.zuendmasse.de" = {
    enableACME = true;
    forceSSL = true;
    locations = {
      "/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.misskey.settings.port}/";
        proxyWebsockets = true;
      };
    };
  };
  

  system.stateVersion = "21.05";
}
