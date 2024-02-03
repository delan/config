{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    release2311.url = "github:nixos/nixpkgs/release-23.11";
    zfs_2_1_13.url = "github:nixos/nixpkgs/2447a25f908c17964f224c839b5a5f6814265b6b";
    # error: attribute 'version' missing
    # zfs_2_1_12.url = "github:nixos/nixpkgs/18a5ef260d7b3d429bc300a067dffd93e3fb9c04";
    zfs_2_1_12.url = "github:delan/nixpkgs/zfs_2_1_12";
    zfs_2_1_9.url = "github:delan/nixpkgs/zfs_2_1_9";
    nixos2305.url = "github:nixos/nixpkgs/nixos-23.05";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = inputs@{ self, nixpkgs, unstable, release2311, zfs_2_1_13, zfs_2_1_12, zfs_2_1_9, nixos2305, home-manager, nixos-hardware, ... }:
  let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config = { allowUnfree = true; };
    };
    unstablePkgs = import unstable {
      system = "x86_64-linux";
      config = { allowUnfree = true; };
    };
    release2311Pkgs = import release2311 {
      system = "x86_64-linux";
      config = { allowUnfree = true; };
    };
    pkgs_zfs_2_1_13 = import zfs_2_1_13 {
      system = "x86_64-linux";
      config = { allowUnfree = true; };
    };
    pkgs_zfs_2_1_12 = import zfs_2_1_12 {
      system = "x86_64-linux";
      config = { allowUnfree = true; };
    };
    pkgs_zfs_2_1_9 = import zfs_2_1_9 {
      system = "x86_64-linux";
      config = { allowUnfree = true; };
    };
    pkgsNixos2305 = import nixos2305 {
      system = "x86_64-linux";
      config = { allowUnfree = true; };
    };
  in {
    # servers
    nixosConfigurations.venus = nixos2305.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        venus/configuration.nix
        {
          # openzfs/zfs#15526 + openzfs/zfs#15533 + openzfs/zfs#15646

          # 2.2.2 (linux 6.1.65, 6.1.69)
          # boot.kernelPackages = release2311Pkgs.linuxPackages;
          # boot.zfs.package = release2311Pkgs.zfs;
          # boot.zfs.modulePackage = release2311Pkgs.linuxPackages.zfs;

          # 2.1.14 (linux 6.1.69)
          # boot.kernelPackages = pkgs.linuxPackages;
          # boot.zfs.package = pkgs.zfs_2_1;
          # boot.zfs.modulePackage = pkgs.linuxPackages.zfs_2_1;

          # 2.1.13 (linux 6.1.64)
          # boot.kernelPackages = pkgs_zfs_2_1_13.linuxPackages;
          # boot.zfs.package = pkgs_zfs_2_1_13.zfs_2_1;
          # boot.zfs.modulePackage = pkgs_zfs_2_1_13.linuxPackages.zfs_2_1;

          # 2.1.12 (linux 6.1.69)
          # boot.kernelPackages = pkgs_zfs_2_1_12.linuxPackages;
          # boot.zfs.package = pkgs_zfs_2_1_12.zfs_2_1;
          # boot.zfs.modulePackage = pkgs_zfs_2_1_12.linuxPackages.zfs;
          # TODO oops # boot.zfs.modulePackage = pkgs_zfs_2_1_12.linuxPackages.zfs_2_1;

          # 2.1.9 (linux 6.1.69)
          # boot.kernelPackages = pkgs_zfs_2_1_9.linuxPackages;
          # boot.zfs.package = pkgs_zfs_2_1_9.zfs_2_1;
          # boot.zfs.modulePackage = pkgs_zfs_2_1_9.linuxPackages.zfs_2_1;
        }
      ];
    };
    nixosConfigurations.colo = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ colo/configuration.nix ];
    };

    # workstations
    nixosConfigurations.uranus = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        uranus/configuration.nix
        home-manager.nixosModules.home-manager
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
    nixosConfigurations.saturn = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        saturn/configuration.nix
        nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme-gen2
        home-manager.nixosModules.home-manager
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
    nixosConfigurations.jupiter = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        jupiter/configuration.nix
        home-manager.nixosModules.home-manager
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
