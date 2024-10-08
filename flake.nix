{
  description = "Nes Development Enviroment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      rom-name = "cart.nes";

        rom = pkgs.stdenv.mkDerivation {
            pname = rom-name;
            version = "1.0.0";

            src = ./src;
            
            buildInputs = [
                pkgs.cc65
            ];

            buildPhase = ''
                ca65 ./cart.s -o ./cart.o -t nes
                ld65 ./cart.o -o ./${rom-name} -t nes
            '';

            installPhase = ''
              mkdir -p $out/bin
              cp ${rom-name} $out/bin/
            '';
      };
    in
    {
      devShells.${system} =  {

          default = pkgs.mkShell 
              { 
                buildInputs = [
                    pkgs.cc65
                    pkgs.wineWowPackages.full
                    pkgs.fceux
                ];
                shellHook = "";
            };
        };

      packages.${system} = 
        {

          default = rom;

          emulator =   pkgs.writeShellScriptBin "run emulator" ''
                            ${pkgs.fceux}/bin/fceux ${rom}/bin/${rom-name}
              '';
      };
    };
}

