{ config, lib, pkgs, ... }: with lib;
{
  services.akkoma = recursiveUpdate {
    enable = true;
    # https://docs.akkoma.dev/stable/configuration/cheatsheet/
    # https://nixos.org/manual/nixos/stable/#module-services-akkoma
    # https://information.websiteleague.org/books/akkoma-setup-guide
    # https://git.isincredibly.gay/srxl/posting.isincredibly.gay/src/commit/a739448d8c467a1fd0ce1c2ae4627c8f49688079/configuration/akkoma.nix
    config = let
      upload_dir = "/ocean/active/services/akkoma/uploads";
    in {
      ":pleroma" = with (pkgs.formats.elixirConf { }).lib; {
        ":instance" = {
          name = "shuppy";
          description = "ao!!";
          email = "akkoma@shuppy.org";
          registration_open = false;
          inherit upload_dir;
          federating = true;
        };

        # federation
        ":mrf".transparency = false;
        # FIXME transparency_obfuscate_domains is busted
        # ** (FunctionClauseError) no function clause matching in Pleroma.Web.ActivityPub.MRF.subdomains_regex/1
        # (pleroma 3.15.2) lib/pleroma/web/activity_pub/mrf.ex:181: Pleroma.Web.ActivityPub.MRF.subdomains_regex(true)
        # ":mrf".transparency_obfuscate_domains = true;
        ":mrf".policies = map mkRaw [
          "Pleroma.Web.ActivityPub.MRF.SimplePolicy"
        ];
        ":mrf_simple" = {
          reject = let
            csv = pkgs.fetchFromGitHub {
              owner = "gardenfence";
              repo = "blocklist";
              rev = "00c5388b61c71c2b69e6a38e5e1bb466895c9dab";
              hash = "sha256-3upDhvQ20Q2+JpcMECxoNfiy/8CfNT3OhNQ0kJkAt/o=";
            };
            json = pkgs.runCommand "gardenfence-fediblocksync.json" {} ''
              ${pkgs.csvkit}/bin/csvjson ${csv}/gardenfence-fediblocksync.csv > $out
            '';
            blocks = builtins.fromJSON (readFile json);
            blocks' = map ({ domain, private_comment, ... }: mkTuple [ domain private_comment ]) blocks;
          in blocks';
        };

        # require login for instance and federated timelines.
        # otherwise anyone can snoop on the union of our timelines.
        ":restrict_unauthenticated" = {
          timelines.local = true;
          timelines.federated = true;
        };

        "Pleroma.Web.Endpoint" = {
          url.host = "fedi.shuppy.org";
          http = {
            ip = "100.95.253.127";
            port = config.internal.ids.akkoma.port;
          };
          # hardening: send cookies over https only
          secure_cookie_flag = true;
        };
        "Pleroma.Web.WebFinger".domain = "shuppy.org";

        # hardening: enable hsts, csp, etc
        ":http_security" = {
          enable = true;
          sts = true;
          referrer_policy = "same-origin";
        };

        # https://docs.akkoma.dev/stable/configuration/cheatsheet/#upload-filters
        "Pleroma.Upload".filters =
          map (pkgs.formats.elixirConf { }).lib.mkRaw [
            # calculate blurhash
            # https://akkoma.dev/AkkomaGang/akkoma/src/commit/6a6d4254d52d4617ff0a0eaa38e28bbf3551acfd/lib/pleroma/upload/filter/analyze_metadata.ex
            "Pleroma.Upload.Filter.AnalyzeMetadata"

            # ReadDescription must happen before StripMetadata
            "Pleroma.Upload.Filter.Exiftool.ReadDescription"
            "Pleroma.Upload.Filter.Exiftool.StripMetadata"

            # Dedupe should be at the end
            "Pleroma.Upload.Filter.Dedupe"
          ];

        "Pleroma.Uploaders.Local".uploads = upload_dir;

        # for security <https://docs.akkoma.dev/stable/configuration/hardening/#pleromaupload-uploader-base_url>
        # it seems the subdirectory must be /media/, anything else is a 404. i think if we want to
        # change the subdirectory, we need to configure a rewrite in nginx accordingly.
        "Pleroma.Upload".base_url = "https://fedi-media.shuppy.org/media";

        # https://nixos.org/manual/nixos/stable/#modules-services-akkoma-media-proxy
        # https://docs.akkoma.dev/stable/configuration/howto_mediaproxy/
        ":media_proxy" = {
          enabled = true;
          proxy_opts.redirect_on_failure = true;
          base_url = "https://fedi-media-proxy.shuppy.org";
        };
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
    settings = {
      # https://pgtune.leopard.in.ua/?dbVersion=17&osType=linux&dbType=web&cpuNum=&totalMemory=1&totalMemoryUnit=GB&connectionNum=20&hdType=hdd
      # DB Version: 17
      # OS Type: linux
      # DB Type: web
      # Total Memory (RAM): 1 GB
      # Connections num: 20
      # Data Storage: hdd
      max_connections = 20;
      shared_buffers = "256MB";
      effective_cache_size = "768MB";
      maintenance_work_mem = "64MB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "7864kB";
      default_statistics_target = 100;
      random_page_cost = 4;
      effective_io_concurrency = 2 * 6;  # 6 top-level vdevs in ocean
      work_mem = "655kB";
      huge_pages = "off";
      min_wal_size = "1GB";
      max_wal_size = "4GB";
    };
  };

  # at least as large as the upload limit (default 15M)
  services.nginx.clientMaxBodySize = mkDefault "16M";

  networking.firewall.allowedTCPPorts = [ 20130 ];
  networking.firewall.allowedUDPPorts = [ 20130 ];

  users.users.akkoma.uid = config.internal.ids.akkoma.id;
  users.groups.akkoma.gid = config.internal.ids.akkoma.id;

  systemd.services.akkoma.wants = [ "tailscaled.service" ];
  systemd.services.akkoma.after = [ "tailscaled.service" ];
}
