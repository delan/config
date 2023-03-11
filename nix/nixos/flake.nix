{
  outputs = { self, nixpkgs }: {
    # servers
    nixosConfigurations.venus = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ venus/configuration.nix ];
    };

    # workstations
    nixosConfigurations.uranus = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ uranus/configuration.nix ];
    };
    nixosConfigurations.saturn = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ saturn/configuration.nix ];
    };
    nixosConfigurations.jupiter = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ jupiter/configuration.nix ];
    };
  };
}
