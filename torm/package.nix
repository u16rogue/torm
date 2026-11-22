{ lib, stdenv, rustPlatform, cargo, rustc, ... }: stdenv.mkDerivation (self: {
    pname = "torm";
    version = "0.1.0";

    # everything the build reads, anything else doesn't exist for it
    src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [
            ./.cargo/config.toml
            ./Cargo.lock
            ./Cargo.toml
            ./do
            ./src
        ];
    };

    # the crates in Cargo.lock, vendored by their checksums. git dependencies need an `outputHashes` entry
    cargoDeps = rustPlatform.importCargoLock {
        lockFile = ./Cargo.lock;
    };

    nativeBuildInputs = [
        # points cargo at cargoDeps, the build has no network
        rustPlatform.cargoSetupHook
        cargo
        rustc
    ];

    buildInputs = [
    ];

    preBuild = ''
    '';

    buildPhase = ''
        runHook preBuild
        bash ./do build-release --frozen
        runHook postBuild
    '';

    installPhase = ''
        runHook preInstall
        install -Dm755 -t "$out/bin" ".build/release/${self.meta.mainProgram}"
        runHook postInstall
    '';

    meta = {
        description = "";
        mainProgram = "torm";
        platforms = lib.platforms.linux;
    };
})
