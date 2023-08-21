{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    home-manager.url = "github:nix-community/home-manager/release-22.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nixos-hardware, ... }: {
    # servers
    nixosConfigurations.venus = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ venus/configuration.nix ];
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
