let nixos = import <nixpkgs/nixos> {
  system = "x86_64-linux";
  configuration = import ./configuration.nix;
};
in nixos.system
