{ config, lib, pkgs, ... }:

with lib;

let
  
  cfg = config.local.services.gotosocial;
  name = "gotosocial";
  stateDir = "/var/lib/${name}";
  settingsFormat = pkgs.formats.yaml { };
  #toYAML = name: data: pkgs.writeText name (generators.toYAML {} data);
  #configFile = toYAML "gotosocial.yaml" cfg.settings;
  #configFile = settingsFormat.generate "gotosocial.yaml" cfg.settings;
  #configFile = "/home/wose/gotosocial/config.yaml";
  
  #configFile = pkgs.writeText "gotosocial.yaml" (
  #  generators.toYAML {} { inherit cfg.settings; }
  #);
in
{
  
  options.local.services.gotosocial = {
    enable = mkEnableOption "Golang fediverse server";
  
    configFile = mkOption {
      type = types.path;
      description = "Path to gotosocial config.yaml.";
    };
  
    settings = mkOption {
  #    type = types.submodule {
      type = settingsFormat.type;
  #    freeformType = settingsFormat.type;
  
      options = {
  #settings = {
        host = mkOption {
          type = types.str;
          default = "localhost";
          description = ''
            Hostname that this server will be reachable at. Defaults to localhost for local testing,
            but you should *definitely* change this when running for real, or your server won't work at all.
            DO NOT change this after your server has already run once, or you will break things!
          '';
        };
  
        account-domain = mkOption {
          type = types.str;
          default = "";
          description = ''
            Domain to use when federating profiles. This is useful when you want your server to be at
            eg., "gts.example.org", but you want the domain on accounts to be "example.org" because it looks better
            or is just shorter/easier to remember.
            To make this setting work properly, you need to redirect requests at "example.org/.well-known/webfinger"
            to "gts.example.org/.well-known/webfinger" so that GtS can handle them properly.
            You should also redirect requests at "example.org/.well-known/nodeinfo" in the same way.
            An empty string (ie., not set) means that the same value as 'host' will be used.
            DO NOT change this after your server has already run once, or you will break things!
          '';
        };
  
        protocol = mkOption {
          type = types.enum [ "http" "https" ];
          default = "https";
          description = ''
            Protocol to use for the server. Only change to http for local testing!
            This should be the protocol part of the URI that your server is actually reachable on. So even if you're
            running GoToSocial behind a reverse proxy that handles SSL certificates for you, instead of using built-in
            letsencrypt, it should still be https.
          '';
        };
  
        bind-address = mkOption {
          type = types.str;
          default = "0.0.0.0";
          description = ''
            Address to bind the GoToSocial server to.
            This can be an IPv4 address or an IPv6 address (surrounded in square brackets), or a hostname.
            Default value will bind to all interfaces.
            You probably won't need to change this unless you're setting GoToSocial up in some fancy way or
            you have specific networking requirements.
          '';
        };
  
        port = mkOption {
          type = types.port;
          default = 8080;
          description = ''
            Listen port for the GoToSocial webserver + API. If you're running behind a reverse proxy and/or in a  docker,
            container, just set this to whatever you like (or leave the default), and make sure it's forwarded properly.
            If you are running with built-in letsencrypt enabled, and running GoToSocial directly on a host machine, you will
            probably want to set this to 443 (standard https port), unless you have other services already using that port.
            This *MUST NOT* be the same as the letsencrypt port specified below, unless letsencrypt is turned off.
          '';
        };
  
        trusted-proxies = mkOption {
          type = types.listOf types.str;
          default = [ "127.0.0.1/32" ];
          description = ''
            CIDRs or IP addresses of proxies that should be trusted when determining real client IP from behind a reverse proxy.
            If you're running inside a Docker container behind Traefik or Nginx, for example, add the subnet of your docker network,
            or the gateway of the docker network, and/or the address of the reverse proxy (if it's not running on the host network).
          '';
        };
  
        db-type = mkOption {
          type = types.enum [ "postgres" "sqlite" ];
          default = "postgres";
          description = "Database type.";
        };
  
        db-address = mkOption {
          type = types.str;
          default = "";
          description = ''
            For Postgres, this should be the address or socket at which the database can be reached.
  
            For Sqlite, this should be the path to your sqlite database file. Eg., /opt/gotosocial/sqlite.db.
            If the file doesn't exist at the specified path, it will be created.
            If just a filename is provided (no directory) then the database will be created in the same directory
            as the GoToSocial binary.
            If address is set to :memory: then an in-memory database will be used (no file).
            WARNING: :memory: should NOT BE USED except for testing purposes.
          '';
        };
  
        db-port = mkOption {
          type = types.port;
          default = 5432;
          description = "Port for database connection.";
        };
  
        db-user = mkOption {
          type = types.str;
          default = "";
          description = "Username for the database connection.";
        };
  
        db-password = mkOption {
          type = types.str;
          default = "";
          description = "Password to use for the database connection.";
        };
  
        db-database = mkOption {
          type = types.str;
          default = "gotosocial";
          description = "Name of the database to use within the provided database type.";
        };
  
        db-tls-mode = mkOption {
          type = types.enum [ "disable" "enable" "required" ];
          default = "disable";
          description = ''
            Disable, enable, or require SSL/TLS connection to the database.
            If "disable" then no TLS connection will be attempted.
            If "enable" then TLS will be tried, but the database certificate won't be checked (for self-signed    certs).
            If "require" then TLS will be required to make a connection, and a valid certificate must be presented.
          '';
        };
  
        db-tls-ca-cert = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = ''
            Path to a CA certificate on the host machine for db certificate validation.
            If this is left empty, just the host certificates will be used.
            If filled in, the certificate will be loaded and added to host certificates.
          '';
        };
  
        web-template-base-dir = mkOption {
          type = types.path;
          default = "./web/template/";
          description = "Directory from which gotosocial will attempt to load html templates (.tmpl files).";
        };
  
        web-asset-base-dir = mkOption {
          type = types.path;
          default = "./web/assets/";
          description = "Directory from which gotosocial will attempt to serve static web assets (images, scripts).";
        };
  
        accounts-registration-open = mkOption {
          type = types.bool;
          default = false;
          description = "Do we want people to be able to just submit sign up requests, or do we want invite only?";
        };
  
        accounts-approval-required = mkOption {
          type = types.bool;
          default = true;
          description = "Do sign up requests require approval from an admin/moderator before an account can sign in/use the server?";
        };
  
        accounts-reason-required = mkOption {
          type = types.bool;
          default = false;
          description = "Are sign up requests required to submit a reason for the request (eg., an explanation of why they want to join the instance)?";
        };
  
        media-image-max-size = mkOption {
          type = types.ints.u32;
          default = 2097152;
          description = "Maximum allowed image upload size in bytes.";
        };
  
        media-video-max-size = mkOption {
          type = types.ints/u32;
          default = 10485760;
          description = "Maximum allowed video upload size in bytes.";
        };
  
        media-description-min-chars = mkOption {
          type = types.ints.u32;
          default = 0;
          description = "Minimum amount of characters required as an image or video description.";
        };
  
        media-description-max-chars = mkOption {
          type = types.ints.u32;
          default = 500;
          description = "Maximum amount of characters permitted in an image or video description.";
        };
  
        media-remote-cache-days = mkOption {
          type = types.ints.u16;
          default = 30;
          description = ''
            Number of days to cache media from remote instances before they are removed from the cache.
            A job will run every day at midnight to clean up any remote media older than the given amount of days.
  
            When remote media is removed from the cache, it is deleted from storage but the database entries for the media
            are kept so that it can be fetched again if requested by a user.
  
            If this is set to 0, then media from remote instances will be cached indefinitely.
          '';
        };
  
        storage-backend = mkOption {
          type = types.str;
          default = "local";
          description = "Type of storage backend to use.";
        };
  
        storage-local-base-path = mkOption {
          type = types.path;
          default = "/gotosocial/storage";
          description = ''
            Directory to use as a base path for storing files.
            Make sure whatever user/group gotosocial is running as has permission to access
            this directory, and create new subdirectories and files within it.
          '';
        };
  
        statuses-max-chars = mkOption {
          type = types.ints.u16;
          default = 5000;
          description = ''
            Maximum amount of characters permitted for a new status.
            Note that going way higher than the default might break federation.
          '';
        };
  
        statuses-cw-max-chars = mkOption {
          type = types.ints.u16;
          default = 100;
          description = ''
            Maximum amount of characters allowed in the CW/subject header of a status.
            Note that going way higher than the default might break federation.
          '';
        };
  
        statuses-poll-max-options = mkOption {
          type = types.ints.u8;
          default = 6;
          description = ''
            Maximum amount of options to permit when creating a new poll.
            Note that going way higher than the default might break federation.
          '';
        };
  
        statuses-poll-option-max-chars = mkOption {
          type = types.ints.u8;
          default = 50;
          description = ''
            Maximum amount of characters to permit per poll option when creating a new poll.
            Note that going way higher than the default might break federation.
          '';
        };
  
        statuses-media-max-files = mkOption {
          type = types.ints.u8;
          default = 6;
          description = ''
            Maximum amount of media files that can be attached to a new status.
            Note that going way higher than the default might break federation.
          '';
        };
  
        letsencrypt-enabled = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether or not letsencrypt should be enabled for the server.
            If false, the rest of the settings here will be ignored.
            If you serve GoToSocial behind a reverse proxy like nginx or traefik, leave this turned off.
            If you don't, then turn it on so that you can use https.
          '';
        };
  
        letsencrypt-port = mkOption {
          type = types.port;
          default = 80;
          description = ''
            Port to listen for letsencrypt certificate challenges on.
            If letsencrypt is enabled, this port must be reachable or you won't be able to obtain certs.
            If letsencrypt is disabled, this port will not be used.
            This *must not* be the same as the webserver/API port specified.
          '';
        };
  
        letsencrypt-cert-dir = mkOption {
          type = types.path;
          default = "/gotosocial/storage/certs";
          description = ''
            Directory in which to store LetsEncrypt certificates.
            It is a good move to make this a sub-path within your storage directory, as it makes
            backup easier, but you might wish to move them elsewhere if they're also accessed by other services.
            In any case, make sure GoToSocial has permissions to write to / read from this directory.
          '';
        };
  
        letsencrypt-email-address = mkOption {
          type = types.str;
          default = "";
          description = ''
            Email address to use when registering LetsEncrypt certs.
            Most likely, this will be the email address of the instance administrator.
            LetsEncrypt will send notifications about expiring certificates etc to this address.
          '';
        };
  
        oidc-enabled = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Enable authentication with external OIDC provider. If set to true, then
            the other OIDC options must be set as well. If this is set to false, then the standard
            internal oauth flow will be used, where users sign in to GtS with username/password.
          '';
        };
  
        oidc-idp-name = mkOption {
          type = types.str;
          default = "";
          description = ''
            Name of the oidc idp (identity provider). This will be shown to users when
            they log in.
          '';
        };
  
        oidc-skip-verification = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Skip the normal verification flow of tokens returned from the OIDC provider, ie.,
            don't check the expiry or signature. This should only be used in debugging or testing,
            never ever in a production environment as it's extremely unsafe!
          '';
        };
  
        oidc-issuer = mkOption {
          type = types.str;
          default = "";
          description = ''
            The OIDC issuer URI. This is where GtS will redirect users to for login.
            Typically this will look like a standard web URL.
          '';
        };
  
        oidc-client-id = mkOption {
          type = types.str;
          default = "";
          description = "The ID for this client as registered with the OIDC provider.";
        };
  
        oidc-client-secret = mkOption {
          type = types.str;
          default = "";
          description = "The secret for this client as registered with the OIDC provider.";
        };
  
        oidc-scopes = mkOption {
          type = types.listOf types.str;
          default = [ "openid" "email" "profile" "groups" ];
          description = ''
            Scopes to request from the OIDC provider. The returned values will be used to
            populate users created in GtS as a result of the authentication flow. 'openid' and 'email' are  required.
            'profile' is used to extract a username for the newly created user.
            'groups' is optional and can be used to determine if a user is an admin (if they're in the group 'admin' or 'admins').
          '';
        };
  
        smtp-host = mkOption {
          type = types.str;
          default = "";
          description = ''
            The hostname of the smtp server you want to use.
            If this is not set, smtp will not be used to send emails, and you can ignore the other settings.
          '';
        };
  
        smtp-port = mkOption {
          type = types.port;
          default = 0;
          description = "Port to use to connect to the smtp server.";
        };
  
        smtp-username = mkOption {
          type = types.str;
          default = "";
          description = "Username to use when authenticating with the smtp server.";
        };
  
        smtp-password = mkOption {
          type = types.str;
          default = "";
          description = "Password to use when authenticating with the smtp server.";
        };
  
        smtp-from = mkOption {
          type = types.str;
          default = "";
          description = "'From' address for sent emails.";
        };
  
        syslog-enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable the syslog logging hook. Logs will be mirrored to the configured destination.";
        };
  
        syslog-protocol = mkOption {
          type = types.str;
          default = "udp";
          description = "Protocol to use when directing logs to syslog. Leave empty to connect to local syslog.";
        };
  
        syslog-address = mkOption {
          type = types.str;
          default = "localhost:514";
          description = "Address:port to send syslog logs to. Leave empty to connect to local syslog.";
        };
      };
      };
    };
  #};
  

  config = mkIf cfg.enable {
    
    local.services.gotosocial.configFile = mkDefault (settingsFormat.generate "gotosocial.yaml" cfg.settings);
    
    users = {
      users.gotosocial = {
        isSystemUser = true;
        group = name;
        home = stateDir;
      };
    
      groups.gotosocial = { };
    };
    
    systemd.services.gotosocial = {
      description = "GoToSocial fediverse server";
      wantedBy = [ "multi-user.target" ];
    
      serviceConfig = {
        Restart = "on-failure";
        User = name;
        StateDirectory = name;
    
        ExecStart = "${pkgs.gotosocial}/bin/gotosocial  --config-path ${cfg.configFile} server start";
    
        WorkingDirectory = stateDir;
      };
    };
    
  };
}
