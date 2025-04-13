{ config, lib, pkgs, ... }: with lib;
{
  services.akkoma = recursiveUpdate {
    enable = true;
    # https://docs.akkoma.dev/stable/configuration/cheatsheet/
    # https://nixos.org/manual/nixos/stable/#module-services-akkoma
    # https://information.websiteleague.org/books/akkoma-setup-guide
    # https://git.isincredibly.gay/srxl/posting.isincredibly.gay/src/commit/a739448d8c467a1fd0ce1c2ae4627c8f49688079/configuration/akkoma.nix
    config = {
      ":pleroma" = with (pkgs.formats.elixirConf { }).lib; {
        ":instance" = {
          name = "shuppy";
          description = "ao!!";
          email = "akkoma@shuppy.org";
          registration_open = false;
          upload_dir = "/ocean/active/services/akkoma/uploads";
        };

        # federation
        ":mrf".policies = map mkRaw [
          "Pleroma.Web.ActivityPub.MRF.SimplePolicy"
        ];
        ":mrf_simple" = {
          # TODO define federation policy
          allow = mkMap {
            "fedi.shuppy.org" = "self (just to enable allowlist federation)";
          };
        };

        "Pleroma.Web.Endpoint" = {
          url.host = "fedi.shuppy.org";
          http = {
            ip = "0.0.0.0";
            port = config.internal.ids.akkoma.port;
          };
        };
        "Pleroma.Web.WebFinger".domain = "shuppy.org";
      };
    };
  } (
    let
      secret = filename: {
        _secret = "/ocean/active/secrets/akkoma/${filename}";
      };
    in {
      # the akkoma module generates six mandatory secrets in /var/lib/secrets/akkoma. we want the
      # secrets to be stored in /ocean/active/secrets/akkoma, but there seems to be no easy way to
      # install a symlink /var/lib/secrets/akkoma -> /ocean/active/secrets/akkoma. instead we
      # specify the path ourselves, then turn off the automatic generating. if a new mandatory
      # secret is added, we will need to check the module source and provide it ourselves.
      initSecrets = false;
      config.":pleroma"."Pleroma.Web.Endpoint".secret_key_base = secret "key-base";
      config.":pleroma"."Pleroma.Web.Endpoint".signing_salt = secret "signing-salt";
      config.":pleroma"."Pleroma.Web.Endpoint".live_view.signing_salt = secret "liveview-salt";
      config.":web_push_encryption".":vapid_details".private_key = secret "vapid-private";
      config.":web_push_encryption".":vapid_details".public_key = secret "vapid-public";
      config.":joken".":default_signer" = secret "jwt-signer";
    }
  );

  # https://nixos.org/manual/nixos/stable/#module-services-pleroma
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    dataDir = "/ocean/active/services/postgres";
  };

  # at least as large as the upload limit (default 15M)
  services.nginx.clientMaxBodySize = mkDefault "16M";

  networking.firewall.allowedTCPPorts = [ 20130 ];
  networking.firewall.allowedUDPPorts = [ 20130 ];

  users.users.akkoma.uid = config.internal.ids.akkoma.id;
  users.groups.akkoma.gid = config.internal.ids.akkoma.id;
}
