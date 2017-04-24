This script assumes than ssh-agent is running and has a key loaded such that login to `remoteHost` is non-interactive.

To install:

 1. pkgs.callPackage this file
 2. symlink it into place at ~/.local/share/applications/handle-torrents.desktop
 3. xdg-settings set default-url-scheme-handler magnet handle-torrents.desktop


### TODO

 - Spawn xmonad tray notify thing on each success
 - Better abstract or rewrite in haskell
