{ config, autoStart ? true }:
{
  homeassistant = {
    inherit autoStart;
    image = "ghcr.io/home-assistant/home-assistant:2025.3.4";  
    environment = {
      TZ = "Australia/Perth";
    };
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "/ocean/active/services/homeassistant:/config"
    ];
    extraOptions = [
      "--device=/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_a49962d47e45ed11a3dac68f0a86e0b4-if00-port0:/dev/ttyUSB0"  # zigbee controller
      "--network=host"  # network_mode: host
      # "--privileged"  # privileged: true (FIXME: do we really need this?)
    ];
  };
  sonarr = {
    inherit autoStart;
    image = "ghcr.io/hotio/sonarr:release-4.0.14.2939";
    ports = ["${toString config.internal.ids.sonarr.port}:8989"];
    networks = ["arr"];
    environment = {
      TZ = "Australia/Perth";
      PUID = "${toString config.internal.ids.sonarr.id}";
      PGID = "${toString config.internal.ids.sonarr.id}";
    };
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "/ocean/active/services/sonarr:/config"
      "/ocean/active:/ocean/active"
    ];
  };
  radarr = {
    inherit autoStart;
    image = "ghcr.io/hotio/radarr:release-5.20.2.9777";
    ports = ["${toString config.internal.ids.radarr.port}:7878"];
    networks = ["arr"];
    environment = {
      TZ = "Australia/Perth";
      PUID = "${toString config.internal.ids.radarr.id}";
      PGID = "${toString config.internal.ids.radarr.id}";
    };
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "/ocean/active/services/radarr:/config"
      "/ocean/active:/ocean/active"
    ];
  };
  recyclarr = {
    inherit autoStart;
    image = "ghcr.io/recyclarr/recyclarr:7.4.1";
    user = "${toString config.internal.ids.recyclarr.id}:${toString config.internal.ids.recyclarr.id}";
    networks = ["arr"];
    environment = {
      TZ = "Australia/Perth";
    };
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "/ocean/active/services/recyclarr:/config"
    ];
  };
  prowlarr = {
    inherit autoStart;
    image = "ghcr.io/hotio/prowlarr:release-1.32.2.4987";
    ports = ["${toString config.internal.ids.prowlarr.port}:9696"];
    networks = ["arr"];
    environment = {
      TZ = "Australia/Perth";
      PUID = "${toString config.internal.ids.prowlarr.id}";
      PGID = "${toString config.internal.ids.prowlarr.id}";
    };
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "/ocean/active/services/prowlarr:/config"
    ];
  };
  bazarr = {
    inherit autoStart;
    image = "ghcr.io/hotio/bazarr:release-1.5.1";
    ports = ["${toString config.internal.ids.bazarr.port}:6767"];
    networks = ["arr"];
    environment = {
      TZ = "Australia/Perth";
      PUID = "${toString config.internal.ids.bazarr.id}";
      PGID = "${toString config.internal.ids.bazarr.id}";
    };
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "/ocean/active/services/bazarr:/config"
      "/ocean/active:/ocean/active"
    ];
  };
  flaresolverr = {
    inherit autoStart;
    image = "ghcr.io/flaresolverr/flaresolverr:v3.3.21";
    ports = ["${toString config.internal.ids.flaresolverr.port}:8191"];
    networks = ["arr"];
    environment = {
      TZ = "Australia/Perth";
      LOG_LEVEL = "info";
    };
  };
  decluttarr = {
    inherit autoStart;
    image = "ghcr.io/manimatter/decluttarr:v1.50.2";
    networks = ["arr"];
    environment = {
      TZ = "Australia/Perth";
      PUID = "${toString config.internal.ids.decluttarr.id}";
      PGID = "${toString config.internal.ids.decluttarr.id}";
      REMOVE_TIMER = "10";
      REMOVE_FAILED = "True";
      REMOVE_FAILED_IMPORTS = "True";
      REMOVE_METADATA_MISSING = "True";
      REMOVE_MISSING_FILES = "True";
      REMOVE_ORPHANS = "True";
      REMOVE_SLOW = "True";
      REMOVE_STALLED = "True";
      REMOVE_UNMONITORED = "True";
      RUN_PERIODIC_RESCANS = ''
      {
        "SONARR": {"MISSING": true, "CUTOFF_UNMET": true, "MAX_CONCURRENT_SCANS": 3, "MIN_DAYS_BEFORE_RESCAN": 7},
        "RADARR": {"MISSING": true, "CUTOFF_UNMET": true, "MAX_CONCURRENT_SCANS": 3, "MIN_DAYS_BEFORE_RESCAN": 7}
      }
      '';

      # Feature Settings
      PERMITTED_ATTEMPTS = "3";
      NO_STALLED_REMOVAL_QBIT_TAG = "Don't Kill";
      MIN_DOWNLOAD_SPEED = "100";
      FAILED_IMPORT_MESSAGE_PATTERNS = ''
      [
      "Not a Custom Format upgrade for existing",
      "Not an upgrade for existing"
      ]
      '';

      RADARR_URL = "http://radarr:7878/radarr";
      # RADARR_KEY = "";

      SONARR_URL = "http://sonarr:8989/sonarr";
      # SONARR_KEY = "";

      QBITTORRENT_URL = "http://172.19.42.2:${toString config.internal.ids.qbittorrent.port}";
    };
    environmentFiles = [config.sops.secrets.radarr-api-key.path config.sops.secrets.sonarr-api-key.path];
  };
  broker = {
    inherit autoStart;
    # for paperless-ngx
    image = "docker.io/library/redis:7.4.2";
    networks = ["paperless"];
    volumes = [
      "/ocean/active/services/paperless/redisdata:/data"
    ];
  };
  paperlessdb = {
    inherit autoStart;
    image = "docker.io/library/postgres:16.8";
    networks = ["paperless"];
    user = "${toString config.internal.ids.paperless.id}:${toString config.internal.ids.paperless.id}";
    volumes = [
      "/ocean/active/services/paperless/pgdata:/var/lib/postgresql/data"
    ];
    environment = {
      POSTGRES_DB = "paperless";
      POSTGRES_USER = "paperless";
      POSTGRES_PASSWORD = "paperless";
    };
  };
  paperless = {
    inherit autoStart;
    # <https://github.com/paperless-ngx/paperless-ngx/blob/main/docker/compose/docker-compose.sqlite.yml>
    image = "ghcr.io/paperless-ngx/paperless-ngx:2.14.7";
    dependsOn = [ "broker" "paperlessdb" ];
    networks = ["paperless"];
    ports = ["${toString config.internal.ids.paperless.port}:8000"];
    volumes = [
      "/ocean/active/services/paperless/data:/usr/src/paperless/data"
      "/ocean/active/services/paperless/media:/usr/src/paperless/media"
      "/ocean/active/services/paperless/export:/usr/src/paperless/export"
      "/ocean/active/services/paperless/inbox:/usr/src/paperless/consume"
    ];
    environment = {
      PAPERLESS_REDIS = "redis://broker:6379";
      USERMAP_UID = "${toString config.internal.ids.paperless.id}";
      USERMAP_GID = "${toString config.internal.ids.paperless.id}";
      PAPERLESS_TIME_ZONE = "Australia/Perth";
      PAPERLESS_OCR_LANGUAGE = "eng";
      PAPERLESS_URL = "https://venus.daz.cat";
      USE_X_FORWARD_HOST = "true";
      USE_X_FORWARD_PORT = "true";
      PAPERLESS_PROXY_SSL_HEADER = ''["HTTP_X_FORWARDED_PROTO", "https"]'';
      PAPERLESS_FORCE_SCRIPT_NAME = "/paperless";
      PAPERLESS_DBHOST = "paperlessdb";
    };
  };
  synclounge = {
    inherit autoStart;
    image = "synclounge/synclounge:5.2.35";
    ports = ["${toString config.internal.ids.synclounge.port}:8088"];
    user = "${toString config.internal.ids.synclounge.id}:${toString config.internal.ids.synclounge.id}";
    environment = {
      TZ = "Australia/Perth";
    };
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "/ocean/active/services/bazarr:/config"
      "/ocean/active:/ocean/active"
    ];
  };
  gtnh = {
    inherit autoStart;
    image = "itzg/minecraft-server:java21-alpine";
    ports = ["25565:25565"];
    environment = {
      SETUP_ONLY = "false";

      TYPE = "CUSTOM";
      CUSTOM_SERVER = "/data/lwjgl3ify-forgePatches.jar";
      VERSION = "1.7.10";
      MOTD = "GTNH Shouse";
      DIFFICULTY = "2";
      LEVEL_TYPE = "RTG";
      SEED = "";
      JVM_OPTS = "-Dfml.readTimeout=180 @java9args.txt";

      INIT_MEMORY = "6G";
      MAX_MEMORY = "8G";
      ENABLE_AUTOPAUSE = "true";
      AUTOPAUSE_TIMEOUT_EST = "300";
      AUTOPAUSE_TIMEOUT_INIT = "60";
      VIEW_DISTANCE = "14";

      UID = "${toString config.internal.ids.minecraft.id}";
      GID = "${toString config.internal.ids.minecraft.id}";
      TZ = "Australia/Perth";
      EULA = "true";
      ONLINE_MODE = "true";
      ALLOW_FLIGHT = "true";
      ENFORCE_WHITELIST = "true";
      MAX_PLAYERS = "5";
      OVERRIDE_SERVER_PROPERTIES = "true";
      MAX_TICK_TIME = "-1";
      CREATE_CONSOLE_IN_PIPE = "true";
    };
    volumes = [
      "/ocean/active/services/gtnh:/data"
    ];
  };
  monifactory = {
    inherit autoStart;
    image = "itzg/minecraft-server:java21-alpine";
    ports = ["25566:25565"];
    environment = {
      EULA = "true";
      TYPE = "FORGE";
      VERSION = "1.20.1";
      FORGE_VERSION = "47.3.10";
      GENERIC_PACK = "https://github.com/ThePansmith/Monifactory/releases/download/0.9.10/Monifactory-Beta.0.9.10-server.zip";
      UID = "${toString config.internal.ids.minecraft.id}";
      GID = "${toString config.internal.ids.minecraft.id}";
      TZ = "Australia/Perth";
      MEMORY = "8G";
      USE_AIKAR_FLAGS = "true";
      WHITELIST = "ariashark,shuppyy";
      EXISTING_WHITELIST_FILE = "MERGE";
      OPS = "ariashark,shuppyy";
      EXISTING_OPS_FILE = "MERGE";
      MAX_PLAYERS = "5";
      ALLOW_FLIGHT = "true";
      DIFFICULTY = "peaceful";
      MOTD = "sharkuppy (ao!)";
    };
    volumes = [
      "/ocean/active/services/monifactory:/data"
    ];
  };
}
