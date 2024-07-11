{
  description = "pgweb frontend for the northwind db in ../northwind flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "../../..";

    photoprism_db.url = "../../..?dir=example/share-services/photoprism_db";
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.process-compose-flake.flakeModule
      ];
      perSystem = { self', pkgs, lib, ... }: {
        process-compose."default" = { config, ... }: {
          imports = [
            inputs.services-flake.processComposeModules.default
            # Importing this brings whatever processes/services the
            # ../northwind/services.nix module exposes, which in our case is a
            # postgresql process loaded with northwind sample database.
            inputs.photoprism_db.processComposeModules.default
          ];

          # Add a pgweb process, that knows how to connect to our northwind db
          settings.processes.pgweb = {
            command = pkgs.pgweb;
            depends_on."photoprism".condition = "process_healthy";
            #environment.PGWEB_DATABASE_URL = config.services.postgres.northwind.connectionURI { dbName = "sample"; };
          };
        };
      };
    };
}

