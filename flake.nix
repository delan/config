{
  inputs = {
    # Fix qemu crash on macOS guests (NixOS/nixpkgs#338598).
    # See also: <https://gitlab.com/qemu-project/qemu/-/commit/a8e63ff289d137197ad7a701a587cc432872d798>
    # Last version deployed before flakes was 68e7dce0a6532e876980764167ad158174402c6f.
    pre2505.url = "github:NixOS/nixpkgs/a84ebe20c6bc2ecbcfb000a50776219f48d134cc";
    pre2511.url = "github:NixOS/nixpkgs/d7600c775f877cd87b4f5a831c28aa94137377aa";
    nixos2511.url = "github:NixOS/nixpkgs/0c88e1f2bdb93d5999019e99cb0e61e1fe2af4c5";
    hm.url = "github:nix-community/home-manager/99a69bdf8a3c6bf038c4121e9c4b6e99706a187a";
    hm.inputs.nixpkgs.follows = "pre2511";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "pre2505";
    git-diffie.url = "github:the6p4c/git-diffie";
    git-diffie.inputs.nixpkgs.follows = "pre2505";
  };

  outputs = inputs@{ pre2505, pre2511, nixos2511, hm, nixos-hardware, sops-nix, git-diffie, ... }:
  let
    nixos2511pkgs = import nixos2511 {
      system = "x86_64-linux";
    };
    # can’t use the lix nixos module yet
    # <https://git.lix.systems/lix-project/nixos-module/issues/107>
    lix-overlay-module = {
      nixpkgs.overlays = [ (final: prev: {
        inherit (nixos2511pkgs.lixPackageSets.lix_2_95)
          nixpkgs-review
          nix-eval-jobs
          nix-fast-build
          colmena;
      }) ];
      nix.package = nixos2511pkgs.lixPackageSets.lix_2_95.lix;
    };
    git-diffie-module = { pkgs, ... }: {
      nixpkgs.overlays = [ git-diffie.overlays.default ];
      environment.systemPackages = [ pkgs.git-diffie ];
    };
  in {
    # NOTE: deployified machines use <https://git.isincredibly.gay/srxl/gemstone-labs.nix/src/commit/21e905f71929a54b5f5e25ce9dbe2e5cf0bc4fc9/deploy>
    # servers
    nixosConfigurations.venus = pre2511.lib.nixosSystem {
      # deployified
      system = "x86_64-linux";
      modules = [
        venus/configuration.nix
        lix-overlay-module
        sops-nix.nixosModules.sops
        git-diffie-module
      ];
    };
    nixosConfigurations.colo = nixos2511.lib.nixosSystem {
      # deployified
      system = "x86_64-linux";
      modules = [
        colo/configuration.nix
        lix-overlay-module
        sops-nix.nixosModules.sops
        git-diffie-module
      ];
    };
    nixosConfigurations.tol = pre2505.lib.nixosSystem {
      # deployified
      system = "x86_64-linux";
      modules = [
        tol/configuration.nix
        lix-overlay-module
        sops-nix.nixosModules.sops
        git-diffie-module
      ];
    };

    # workstations
    nixosConfigurations.frappetop = pre2511.lib.nixosSystem {
      # deployified
      system = "x86_64-linux";
      modules = [
        frappetop/configuration.nix
        lix-overlay-module
        sops-nix.nixosModules.sops
        git-diffie-module
        # nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme-gen2
        hm.nixosModules.home-manager
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
    nixosConfigurations.jupiter = nixos2511.lib.nixosSystem {
      # deployified
      system = "x86_64-linux";
      modules = [
        jupiter/configuration.nix
        lix-overlay-module
        sops-nix.nixosModules.sops
        git-diffie-module
        hm.nixosModules.home-manager
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
