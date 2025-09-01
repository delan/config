{
  inputs = {
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.92.0.tar.gz";
      inputs.nixpkgs.follows = "unstable";
    };
    lix-module-workstations = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs.nixpkgs.follows = "unstable-workstations";
      inputs.lix.follows = "lix-workstations";
    };
    lix-workstations = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      flake = false;
    };
    # Fix qemu crash on macOS guests (NixOS/nixpkgs#338598).
    # See also: <https://gitlab.com/qemu-project/qemu/-/commit/a8e63ff289d137197ad7a701a587cc432872d798>
    # Last version deployed before flakes was 68e7dce0a6532e876980764167ad158174402c6f.
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    hm.url = "github:nix-community/home-manager/master";
    hm.inputs.nixpkgs.follows = "unstable";
    unstable-workstations.url = "github:NixOS/nixpkgs/nixos-unstable";
    hm-workstations.url = "github:nix-community/home-manager/master";
    hm-workstations.inputs.nixpkgs.follows = "unstable-workstations";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "unstable";
    git-diffie.url = "github:the6p4c/git-diffie";
    git-diffie.inputs.nixpkgs.follows = "unstable";
  };

  outputs = inputs@{ self, lix-module, unstable, hm, lix-module-workstations, unstable-workstations, hm-workstations, nixos-hardware, sops-nix, git-diffie, ... }:
  let
    pkgsUnstable = import unstable {
      system = "x86_64-linux";
      config = { allowUnfree = true; };
    };
    pkgsUnstableWorkstations = import unstable-workstations {
      system = "x86_64-linux";
      config = { allowUnfree = true; };
    };
    git-diffie-module = { pkgs, ... }: {
      nixpkgs.overlays = [ git-diffie.overlays.default ];
      environment.systemPackages = [ pkgs.git-diffie ];
    };
  in {
    # NOTE: deployified machines use <https://git.isincredibly.gay/srxl/gemstone-labs.nix/src/commit/21e905f71929a54b5f5e25ce9dbe2e5cf0bc4fc9/deploy>
    # servers
    nixosConfigurations.venus = unstable.lib.nixosSystem {
      # deployified
      system = "x86_64-linux";
      modules = [
        venus/configuration.nix
        lix-module.nixosModules.default
        sops-nix.nixosModules.sops
        git-diffie-module
      ];
    };
    nixosConfigurations.colo = unstable.lib.nixosSystem {
      # deployified
      system = "x86_64-linux";
      modules = [
        colo/configuration.nix
        lix-module.nixosModules.default
        sops-nix.nixosModules.sops
        git-diffie-module
      ];
    };
    nixosConfigurations.tol = unstable.lib.nixosSystem {
      # deployified
      system = "x86_64-linux";
      modules = [
        tol/configuration.nix
        lix-module.nixosModules.default
        sops-nix.nixosModules.sops
        git-diffie-module
      ];
    };

    # workstations
    nixosConfigurations.frappetop = unstable-workstations.lib.nixosSystem {
      # deployified
      system = "x86_64-linux";
      modules = [
        frappetop/configuration.nix
        lix-module-workstations.nixosModules.default
        sops-nix.nixosModules.sops
        git-diffie-module
        # nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme-gen2
        hm-workstations.nixosModules.home-manager
        {
          home-manager.users.delan = import ./home.nix;

          # use same nixpkgs as system, which has allowUnfree
          home-manager.useGlobalPkgs = true;

          # TODO do we need this? affects path to hm-session-vars.sh!
          # https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
          # https://nix-community.github.io/home-manager/index.html#sec-flakes-nixos-module
          # home-manager.useUserPackages = true;
        }
      ];
    };
    nixosConfigurations.jupiter = unstable-workstations.lib.nixosSystem {
      # deployified
      system = "x86_64-linux";
      modules = [
        jupiter/configuration.nix
        lix-module-workstations.nixosModules.default
        sops-nix.nixosModules.sops
        git-diffie-module
        hm-workstations.nixosModules.home-manager
        {
          home-manager.users.delan = import ./home.nix;

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
