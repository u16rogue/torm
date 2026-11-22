{
    # `ssm add` appends to the inputs, subprojects, overlays and nixConfig lists,
    # keep their `<name> = {` / `<name> = [` openers on their own line
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        nixpkgs-pin.url = "github:nixos/nixpkgs/d4f25a3e562008648d45bcf2d70bcc7422cad84e";
    };

    outputs = inputs@{ nixpkgs, ... }: let
        inherit (nixpkgs) lib;
        systems = [ "x86_64-linux" ];
        overlays = [
        ];
        perSystem = attr: lib.genAttrs systems (system: attr { pkgs = import nixpkgs { inherit system overlays; }; inherit system; });
        subprojects = [
            ./torm
        ];
        callEach = pkgs: file: lib.pipe subprojects [
            (lib.filter (path: builtins.pathExists (path + "/${file}")))
            (map (path: lib.nameValuePair (baseNameOf path) (pkgs.callPackage (path + "/${file}") {})))
            lib.listToAttrs
        ];
    in {
        description = "tui forms transpiler";
        packages = perSystem ({ pkgs, ... }: callEach pkgs "package.nix");
        devShells = perSystem ({ pkgs, ... }: let shells = callEach pkgs "shell.nix"; in shells // {
            default = pkgs.mkShellNoCC {
                inputsFrom = lib.attrValues shells;
                packages = with pkgs; [ git jujutsu nil bash-language-server shellcheck lua-language-server ];
                shellHook = /*bash*/ ''
                    export NIX_FRAGMENT="default"
                    export PATH="$PATH:$PWD/scripts/"
                    if [ -f "$PWD/.jj.toml" ]; then
                        export JJ_CONFIG="''${JJ_CONFIG:-''${XDG_CONFIG_HOME:-$HOME/.config}/jj/config.toml}:$PWD/.jj.toml"
                    fi
                '';
            };
        });
    };
}
