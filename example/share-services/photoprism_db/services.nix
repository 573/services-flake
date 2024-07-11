{ inputs }:
{
  services.mysql.phopridb = {
    enable = true;
    initialDatabases = [{ name = "photoprism"; }];
    ensureUsers = [
      {
        name = "photoprism";
        ensurePermissions = { "photoprism.*" = "ALL PRIVILEGES"; };
      }
    ];
  };
  services.photoprism."phopri" = {
    enable = true;
  };
}
