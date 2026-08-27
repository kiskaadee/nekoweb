{
  description = "NekoWeb - Homelab Web Reader & Scraper Platform for HakuNeko";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "nekoweb-dev-shell";

          buildInputs = with pkgs; [
            # Python runtime & modern UV package manager
            python312
            uv

            # Node.js & package managers for Frontend & Daemon
            nodejs_22
            pnpm
            nodePackages.npm

            # Native build tools & DB libraries
            postgresql
            pkg-config
            openssl
            libffi

            # Docker & Compose utilities
            docker
            docker-compose

            # Headless testing utilities
            xvfb-run
          ];

          shellHook = ''
            echo "🚀 Entering NekoWeb DevShell (NixOS)"
            echo "  • Python: $(python3 --version)"
            echo "  • UV:     $(uv --version)"
            echo "  • Node:   $(node --version)"
            echo "  • pnpm:   $(pnpm --version)"

            # Ensure local virtualenv PATH is available
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
              pkgs.stdenv.cc.cc
              pkgs.openssl
              pkgs.postgresql
            ]}:$LD_LIBRARY_PATH"

            export UV_PYTHON_PREFERENCE="only-system"
          '';
        };
      }
    );
}
