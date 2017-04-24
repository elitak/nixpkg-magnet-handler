{ stdenv
, bash # must be 4.4 or greater to use ${var@Q} feature!
, writeScript
, writeText
, openssh

# Give the host part of the ssh command here, e.g., user@torrentbox
, remoteHost
# Dictionary of bash regex patterns to paths where to backup the torrents (unused for magnet links)
# Make sure to escape the escape characters in the pattern, e.g., "\\[privatenet\\ torrent\\]" = "/home/user/privatenet"
, storePatterns ? {}
}:
with stdenv.lib;
let
  # NB the escaping in here is tricky: we use ${var@Q}, expanded locally, to
  # prepare $cmd so that paths are not misinterpreted on the remote side. The
  # use of "$tor" for the pattern matching is not an omission.
  handlerScript = writeScript "push-torrent-to-remote-host.sh" ''
    #! ${bash}/bin/bash
    # to debug this, add set -x and run xdg-open <file or magnet uri>^
    set -eu
    shopt -s nocasematch

    url="$1"

    ssh() { ${openssh}/bin/ssh "$@"; }

    # Handle torrent file
    if [[ "$url" =~ \.torrent$ ]]; then
      tor="$(basename "$url")"
      cmd=" cat > /tmp/''${tor@Q}; "
      cmd+="transmission-remote -a /tmp/''${tor@Q}; "
      ${ if (storePatterns != {}) then ''
          ${concatStringsSep "\nel" (mapAttrsToList (pattern: path: ''if [[ "$tor" =~ ${pattern} ]]; then cmd+="mkdir -p ${path} && mv /tmp/''${tor@Q} ${path}; "'') storePatterns)}
          else cmd+="rm /tmp/''${tor@Q}; "; fi
        ''
      else
        ''cmd+="rm /tmp/''${tor@Q}; "''
      }

      ssh ${remoteHost} "$cmd" <"$url"
      rm "$url"
    fi

    # Handle magnet URI
    if [[ "$url" =~ ^magnet: ]]; then
        ssh ${remoteHost} transmission-remote -a "''${url@Q}"
    fi
  '';
in
# NB weird string substitution rules. see https://specifications.freedesktop.org/desktop-entry-spec/latest/ar01s06.html for details.
#    It's simplest just to pass the whole parameter to a script that can figure it out on it's own.
writeText "fetch-magnet-on-downloader.desktop" ''
  [Desktop Entry]
  MimeType=application/x-bittorrent;x-scheme-handler/magnet;
  Exec=${handlerScript} %u
''
