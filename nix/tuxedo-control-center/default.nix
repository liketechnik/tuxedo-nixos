{ lib, buildNpmPackage, fetchFromGitHub, git, udev, nodejs, electron_13 , makeWrapper, copyDesktopItems }:

buildNpmPackage rec {
  pname = "tuxedo-control-center";
  version = "2.0.11";

  src = fetchFromGitHub {
    owner = "tuxedocomputers";
    repo = "tuxedo-control-center";
    rev = "v${version}";
    sha256 = "sha256-TWO2MQuoIQZI/xhPUlsMPXxLmTyaQS5a1/Jz/oOqPsg=";
  };

  # These are installed in the right place via copyDesktopItems.
  desktopItems = [
    "src/dist-data/tuxedo-control-center.desktop"
    "src/dist-data/tuxedo-control-center-tray.desktop"
  ];

  # TCC supplies broken (for nix's packaging infra) lock files
  prePatch = ''
    cp ${./package-lock.json} package-lock.json
    cp ${./package.json} package.json
    # build-service calls bundle-service,
    # which is unnecessary (and incompatible) with nix
    # but: bundle-service creates directories that are depended on
    # in later steps of the build process
    sed -i -e 's|run-s bundle-service|mkdir -p ./dist/tuxedo-control-center/data/service|' package.json
  '';

  # TCC by default writes its config to /etc/tcc, which is
  # inconvenient. Change this to a more standard location.
  #
  # It also hardcodes binary paths.
  postPatch = ''
    substituteInPlace src/common/classes/TccPaths.ts \
      --replace "/etc/tcc" "/var/lib/tcc" \
      --replace "/opt/tuxedo-control-center/resources/dist/tuxedo-control-center/data/service/tccd" "$out/bin/tccd"

    for desktopFile in ${lib.concatStringsSep " " desktopItems}; do
      substituteInPlace $desktopFile \
        --replace "/usr/bin/tuxedo-control-center" "$out/bin/tuxedo-control-center"
    done
  '';

  postInstall = ''
    mkdir -p $out
    cp -R ./dist/tuxedo-control-center/* $out

    makeWrapper ${nodejs}/bin/node $out/data/service/tccd \
                --add-flags "$out/service-app/service-app/main.js" \
                --prefix NODE_PATH : $out/data/service \
                --prefix NODE_PATH : $out/lib/node_modules/tuxedo-control-center
    mkdir -p $out/bin
    ln -s $out/data/service/tccd $out/bin/tccd


    ln -s $out/lib/node_modules/tuxedo-control-center/node_modules $out/node_modules
    makeWrapper ${electron_13}/bin/electron $out/bin/tuxedo-control-center \
                --add-flags "$out/" \

    mkdir -p $out/share/polkit-1/actions/
    cp $out/data/dist-data/com.tuxedocomputers.tccd.policy $out/share/polkit-1/actions/com.tuxedocomputers.tccd.policy

    mkdir -p $out/etc/dbus-1/system.d/
    cp $out/data/dist-data/com.tuxedocomputers.tccd.conf $out/etc/dbus-1/system.d/com.tuxedocomputers.tccd.conf

    # Put our icons in the right spot
    mkdir -p $out/share/icons/hicolor/scalable/apps/
    cp $out/data/dist-data/tuxedo-control-center_256.svg \
       $out/share/icons/hicolor/scalable/apps/tuxedo-control-center.svg
  '';

  npmBuildScript = "build-prod";

  # the package-lock.json is manually updated to v2+
  npmFlags = [ "--legacy-peer-deps" ];
  makeCacheWritable = true;

  npmDepsHash = "sha256-45buXvV9g6ex85AWDiE1PqaTslkbrztH//hjNwgzqB4=";

  # Electron tries to download itself if this isn't set. We don't
  # like that in nix so let's prevent it.
  #
  # This means we have to provide our own electron binaries when
  # wrapping this program.
  ELECTRON_SKIP_BINARY_DOWNLOAD=1;

  # needed by the angular build
  NODE_OPTIONS = "--openssl-legacy-provider";

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    udev
  ];
}
