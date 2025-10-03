{
  stdenv,
  fetchFromGitHub,
  apacheHttpd,
}: stdenv.mkDerivation rec {
  pname = "mod_ip";
  version = "1.0+2025.03.03";
  src = fetchFromGitHub {
    owner = "falling-sky";
    repo = "mod_ip";
    rev = "03c17be48cf61145ca98416d6af7505594a2183c";
    hash = "sha256-HOprMJr+WxBL86+glc5D6raw62oAWYM5s+GdCrd6LGc=";
  };
  nativeBuildInputs = [
    apacheHttpd
  ];
  # <https://stackoverflow.com/a/27571222>
  installPhase = ''
    cp -v .libs/mod_ip.so $out
  '';
}
