{
  stdenv,
  fetchFromGitHub,
  libnetfilter_queue,
  libnfnetlink,
}: let
in stdenv.mkDerivation rec {
  pname = "mtu1280d";
  version = "0.0+pull9";
  src = fetchFromGitHub {
    owner = "falling-sky";
    repo = "mtu1280d";
    # Fix bug where sockfd() may return wrong file descriptor (#9)
    # <https://github.com/falling-sky/mtu1280d/pull/9>
    rev = "ab138f7e510022bcae83032d90aff11a3787e865";
    hash = "sha256-IuuoaCaJFMxfeZSG+vpSUI/YCilyYTW1SG1f7Ibddy4=";
  };
  nativeBuildInputs = [
    libnetfilter_queue
    libnfnetlink
  ];
  buildPhase = ''
    make mtu1280d
  '';
  installPhase = ''
    cp -v mtu1280d $out
  '';
}
