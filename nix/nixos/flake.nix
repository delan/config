{
  inputs = {
    nixos2211.url = "github:nixos/nixpkgs/nixos-22.11";
    nixos2305.url = "github:nixos/nixpkgs/nixos-23.05";
    nixos2311.url = "github:nixos/nixpkgs/nixos-23.11";
    zfs_2_2_4.url = "github:nixos/nixpkgs/cec5812591bc6235f15b84bb55438661cb67f7d2";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    hm2211.url = "github:nix-community/home-manager/release-22.11";
    hm2211.inputs.nixpkgs.follows = "nixos2211";
    hm2305.url = "github:nix-community/home-manager/release-23.05";
    hm2305.inputs.nixpkgs.follows = "nixos2305";
    hm2311.url = "github:nix-community/home-manager/release-23.11";
    hm2311.inputs.nixpkgs.follows = "nixos2311";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = inputs@{ self, nixos2211, nixos2305, nixos2311, zfs_2_2_4, unstable, hm2211, hm2305, hm2311, nixos-hardware, ... }:
  let
    pkgs2311 = import nixos2311 {
      system = "x86_64-linux";
      config = { allowUnfree = true; };
    };
    pkgs_zfs_2_2_4 = import zfs_2_2_4 {
      system = "x86_64-linux";
      config = { allowUnfree = true; };
    };
    pkgsUnstable = import unstable {
      system = "x86_64-linux";
      config = { allowUnfree = true; };
    };
  in {
    # servers
    nixosConfigurations.venus = nixos2311.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        venus/configuration.nix
        {
          boot.kernelPackages = pkgs_zfs_2_2_4.linuxPackages;
          boot.zfs.package = pkgs_zfs_2_2_4.zfs;
          boot.zfs.modulePackage = pkgs_zfs_2_2_4.linuxPackages.zfs;
        }
      ];
    };
    nixosConfigurations.colo = nixos2211.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ colo/configuration.nix ];
    };

    # workstations
    nixosConfigurations.uranus = nixos2211.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        uranus/configuration.nix
        hm2211.nixosModules.home-manager
        {
          home-manager.users.delan = import ../nixpkgs/home.nix;

          # use same nixpkgs as system, which has allowUnfree
          home-manager.useGlobalPkgs = true;

          # TODO do we need this? affects path to hm-session-vars.sh!
          # https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
          # https://nix-community.github.io/home-manager/index.html#sec-flakes-nixos-module
          # home-manager.useUserPackages = true;
        }
      ];
    };
    nixosConfigurations.saturn = nixos2305.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        saturn/configuration.nix
        nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme-gen2
        hm2305.nixosModules.home-manager
        {
          home-manager.users.delan = import ../nixpkgs/home.nix;

          # use same nixpkgs as system, which has allowUnfree
          home-manager.useGlobalPkgs = true;

          # TODO do we need this? affects path to hm-session-vars.sh!
          # https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
          # https://nix-community.github.io/home-manager/index.html#sec-flakes-nixos-module
          # home-manager.useUserPackages = true;
        }
      ];
    };
    nixosConfigurations.jupiter = nixos2311.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        jupiter/configuration.nix
        hm2311.nixosModules.home-manager
        {
          home-manager.users.delan = import ../nixpkgs/home.nix;

          # use same nixpkgs as system, which has allowUnfree
          home-manager.useGlobalPkgs = true;

          # TODO do we need this? affects path to hm-session-vars.sh!
          # https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
          # https://nix-community.github.io/home-manager/index.html#sec-flakes-nixos-module
          # home-manager.useUserPackages = true;
        }
      ];
    };
  };
}
