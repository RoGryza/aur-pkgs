#!/bin/bash

set -e

echo "Fetching latest release..."
hub api repos/dhall-lang/dhall-haskell/releases/latest > latest.json
DHALL_VER=$(cat latest.json | jq '.tag_name' -r)

pushd "dhall-bin"

CURRENT_DHALL=$(cat "PKGBUILD" | grep '^pkgver=' | grep -oEi '[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+')
if [ "$DHALL_VER" = "$CURRENT_DHALL" ]; then
  echo "dhall-bin is up-to-date."
else
  echo "Updating dhall-bin from $CURRENT_DHALL to $DHALL_VER"
  sed -i 's/^pkgver=.*/pkgver='$DHALL_VER'/' PKGBUILD
  sed -i 's/^pkgrel=.*/pkgrel=1/' PKGBUILD

  updpkgsums
  makepkg --printsrcinfo > .SRCINFO

  git add PKGBUILD .SRCINFO
  git commit -m "Update to $DHALL_VER"
fi

popd

for NAME in dhall-bash dhall-lsp-server; do
  pushd "$NAME-bin"

  PKG_VER=$(cat ../latest.json | jq '.assets[] | .name | match("'$NAME'-(.*)-x86_64-linux") | .captures[0].string' -r)
  CURRENT_PKG=$(cat PKGBUILD | grep '^pkgver=' | grep -oEi '[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+')

  if [ "$PKG_VER" = "$CURRENT_PKG" ]; then
    echo "$NAME is up-to-date."
  else
    echo "Updating $NAME from $CURRENT_PKG to $PKG_VER"
    sed -i 's/^pkgver=.*/pkgver='$PKG_VER'/' PKGBUILD
    sed -i 's/^_dhall_ver=.*/_dhall_ver='$DHALL_VER'/' PKGBUILD
    sed -i 's/^pkgrel=.*/pkgrel=1/' PKGBUILD

    updpkgsums
    makepkg --printsrcinfo > .SRCINFO

    git add PKGBUILD .SRCINFO
    git commit -m "Update to $PKG_VER"
  fi

  popd
done
