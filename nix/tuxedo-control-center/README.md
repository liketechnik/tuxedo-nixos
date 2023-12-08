# Updating

1. Clone the [tuxedo-control-center repository](https://github.com/tuxedocomputers/tuxedo-control-center)
    and check out the tag of the version you want to update to.
2. Clone and checkout the commit of `node-ble` in the dependencies (`grep node-ble package-lock.json`).
    Since it is a git dependency and its lockfile hasn't been regenerated in the
    tuxedo fork, nix cannot correctly download the npm dependencies.
    Therefore regenerating the lock file is necessary.
3. Clone and checkout the branch of `node-dbus-next` in the dependencies of `node-ble`
    (`grep node-dbus-next package.json`) (Note: currently the lock file
    in the repo does not contain an entry for node-dbus-next.
    As soon as it does, these instruction should refer to the commit
    from the lock file, instead of just a branch.)
4. Let npm fixup the lockfile format of `node-dbus-next`:
    `npm install --frozen --package-lock --legacy-peer-deps --ignore-scripts`
    Commit the changes to package-lock.json and tag the commit
    with `git tag tcc-<version of tcc you're updating to>`.
    Then push the tag: `git push --tag`.
5. Update the package.json of `node-ble` to refer
    to the tagged version of `node-dbus-next`
    you just pushed. Now fixup `node-ble`'s lockfile too:
    `npm install --frozen --package-lock --legacy-peer-deps --ignore-scripts`.
    Commit the changes with the same tag as above
    and push that tag.
6. Repeat the procedure for `tuxedo-control-center`
    with the now tagged version of `node-ble`,
    but don't commit the changes.
    Instead copy the package.json and the package-lock.json
    files into this directory.
7. Now simply adjust the version and the hashes in default.nix
    and verify that tcc still builds and works correctly.
8. Please also verify the that the kernel module version check in ../module.nix
    verifies the correct version requirement.
