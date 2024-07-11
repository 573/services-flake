{ pkgs, lib, name, config, ... }:
let
  inherit (lib) types;
  photoprismPackage = pkgs.photoprism.override { };
in
{
  options = {
    # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/web-apps/photoprism.nix
    description = ''
      Configure photoprism
    '';

    package = lib.mkOption {
      type = types.package;
      default = photoprismPackage;
      description = "The Photoprism package to use";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
      example = "0.0.0.0";
      description = ''
        Web interface address.
      '';
    };

    port = lib.mkOption {
      description = lib.mdDoc "Web interface port.";
      type = types.port;
      default = 2342;
      example = 11111;
    };

    environment = lib.mkOption {
      type = types.attrsOf types.str;
      default = {
      };
      example = ''
        {
	  PHOTOPRISM_DEBUG = "true";
	  PHOTOPRISM_EXPERIMENTAL = "true";
        }
      '';
      description = "Extra environment variables for Open-WebUI";
    };

    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Admin password file.
      '';
    };

    originalsPath = lib.mkOption {
      type = lib.types.path;
      default = null;
      example = "/data/photos";
      description = ''
        Storage path of your original media files (photos and videos).
      '';
    };

    importPath = lib.mkOption {
      type = lib.types.str;
      default = "import";
      description = ''
        Relative or absolute to the `originalsPath` from where the files should be imported.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        See [the getting-started guide](https://docs.photoprism.app/getting-started/config-options/) for available options.
      '';
      example = {
        PHOTOPRISM_DEFAULT_LOCALE = "de";
        PHOTOPRISM_ADMIN_USER = "root";
      };
    };
  };

  config = {
    outputs = {
      settings = {
        processes = {
          "${name}" =
            {
              environment = 
(
                lib.mapAttrs' (n: v: lib.nameValuePair "PHOTOPRISM_${n}" (toString v))
                {
                  #HOME = "${cfg.dataDir}";
                  SSL_CERT_DIR = "${pkgs.cacert}/etc/ssl/certs";

                  DARKTABLE_PRESETS = "false";

                  DATABASE_DRIVER =
                    if !config.mysql
                    then "sqlite"
                    else "mysql";
                  DATABASE_DSN =
                    if !config.mysql
                    then "${config.dataDir}/photoprism.sqlite"
                    else "photoprism@unix(/run/mysqld/mysqld.sock)/photoprism?charset=utf8mb4,utf8&parseTime=true";
                  DEBUG = "true";
                  DETECT_NSFW = "true";
                  EXPERIMENTAL = "true";
                  WORKERS = "8";
                  ORIGINALS_LIMIT = "1000000";
                  HTTP_HOST = "${config.host}";
                  HTTP_PORT = "${toString config.port}";
                  HTTP_MODE = "release";
                  JPEG_QUALITY = "92";
                  JPEG_SIZE = "7680";
                  PUBLIC = "false";
                  READONLY = "false";
                  TENSORFLOW_OFF = "true";
                  SIDECAR_JSON = "true";
                  SIDECAR_YAML = "true";
                  SIDECAR_PATH = "${config.dataDir}/sidecar";
                  SETTINGS_HIDDEN = "false";
                  SITE_CAPTION = "Browse Your Life";
                  SITE_TITLE = "PhotoPrism";
                  SITE_URL = "http://127.0.0.1:2342/";
                  STORAGE_PATH = "${config.dataDir}/storage";
                  ASSETS_PATH = "${config.package.assets}";
                  ORIGINALS_PATH = "${config.dataDir}/originals";
                  IMPORT_PATH = "${config.dataDir}/${lib.optionalString (config.importPath != null)}";
                  THUMB_FILTER = "linear";
                  THUMB_SIZE = "2048";
                  THUMB_SIZE_UNCACHED = "7680";
                  THUMB_UNCACHED = "true";
                  UPLOAD_NSFW = "true";
                }
                // (
                  if !config.keyFile
                  then {PHOTOPRISM_ADMIN_PASSWORD = "photoprism";}
                  else {}
                )
              )
	       // config.environment;

              command = pkgs.writeShellApplication {
                name = "photoprism-wrapper";
                text = ''
                  		  ${lib.optionalString (config.passwordFile != null) ''
                                      export PHOTOPRISM_ADMIN_PASSWORD=$(cat "$CREDENTIALS_DIRECTORY/PHOTOPRISM_ADMIN_PASSWORD")
                                    ''}
                                    exec ${lib.getExe config.package} start
                '';
              };
              readiness_probe = {
                http_get = {
                  host = config.host;
                  port = config.port;
                };
                initial_delay_seconds = 2;
                period_seconds = 10;
                timeout_seconds = 4;
                success_threshold = 1;
                failure_threshold = 5;
              };
              availability.restart = "on_failure";
            };
        };
      };
    };
  };
}
