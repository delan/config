# f=...
# chmod +x "$f"
# nix-shell -p stdenv --run 'patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" '"$f"
# patchelf --print-needed "$f" | xargs -tn 1 nix-locate -1w --top-level > p
# < p sed 's/[.]out$//' | sort -u | fgrep -ve foo -e bar -e baz > q
# < q xargs -tI {} nix-shell -p {} --run :
# printf \%s "$(< q xargs -tI {} echo 'with pkgs; lib.makeLibraryPath [ {} ]' | nix repl '<nixpkgs>' | sed 's/\x1B\[[0-9;]*m//g' | fgrep \" | tr -d \")" | tr \\n : | xargs -tI {} patchelf --set-rpath {} "$f"

{ stdenv, fetchzip, autoPatchelfHook, pkgs }:
stdenv.mkDerivation rec {
  name = "adc902fc0fa11bbe";

  src = fetchzip {
    # url = "https://bucket.daz.cat/adc902fc0fa11bbe.zip";
    # sha256 = "0mabv9rysfpqck7fw8ismbj9k3lf5r115xsaxc465936pk6myvq9";
    url = "https://bucket.daz.cat/b56ac4201f39e0d4.zip";
    sha256 = "0gy03445i9hz1yrqyg4dv18cm9j8hbf0jhh6cbldcb1w4bghn4dw";
    stripRoot = false;
  };

  # patches = [ ... ];

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = with pkgs; [
    glibc alsaLib libpulseaudio libGLU
  ] ++ (with xlibs; [
    libXcursor libXinerama libXrandr libXrender libX11 libXi
  ]);

  installPhase = ''
    mkdir -p $out/bin
    install -Dm 644 ./ariasflyingthing.pck $out
    install -Dm 755 ./ariasflyingthing.x86_64 $out
    ln -s $out/ariasflyingthing.x86_64 $out/bin
  '';
}
