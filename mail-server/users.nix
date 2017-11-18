#  nixos-mailserver: a simple mail server
#  Copyright (C) 2016-2017  Robin Raymond
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program. If not, see <http://www.gnu.org/licenses/>

{ config, pkgs, lib, ... }:

with config.mailserver;

let
  vmail_user = {
    name = vmailUserName;
    isNormalUser = false;
    uid = vmailUID;
    home = mailDirectory;
    createHome = true;
    group = vmailGroupName;
  };

  # accountsToUser :: String -> UserRecord
  accountsToUser = account: {
    name = lib.head (lib.splitString "@" account.name);
    domain = lib.head (lib.tail (lib.splitString "@" account.name));
    inherit (account) hashedPassword;
  };

  virtualMailUsersActivationScript = pkgs.writeScript "activate-virtual-mail-users" ''
    #!${pkgs.stdenv.shell}

    set -euo pipefail

    # Create mailDirectory if it doesn't exist.
    if (! test -d "${mailDirectory}"); then
      mkdir -p "${mailDirectory}"
      chown ${vmailUserName}:${vmailGroupName}
      chmod 700 "${mailDirectory}"
    fi

    # Create a passwd and shadow file under mailDirectory/domain for each domain
    # in cfg.domains.
    ${lib.concatMapStringsSep "\n"
      (domain: let domainDir = "${mailDirectory}/${domain}"; in ''
        # Create per-domain directory if it doesn't exist.
        if (! test -d "${domainDir}"); then
          mkdir -p "${domainDir}"
        fi

        chown -R ${vmailUserName}:${vmailGroupName} "${domainDir}"

        # Remove per-domain passwd file if it already exists, then (re)create it
        # with the proper permissions.
        if (test -f "${domainDir}/passwd"); then
          rm "${domainDir}/passwd"
        fi

        touch "${domainDir}/passwd"
        chown ${vmailUserName}:${vmailGroupName} "${domainDir}/passwd"
        chmod 700 "${domainDir}/passwd"

        # Remove per-domain shadow file if it already exists, then (re)create it
        # with the proper permissions.
        if (test -f "${domainDir}/shadow"); then
          rm "${domainDir}/shadow"
        fi

        touch "${domainDir}/shadow"
        chown ${vmailUserName}:${vmailGroupName} "${domainDir}/shadow"
        chmod 700 ${domainDir}/shadow
      '') (domains)}

      # Add virtual users in cfg.loginAccounts to per-domain password and shadow
      # files.
      ${lib.concatMapStringsSep "\n"
      ({ name, domain, hashedPassword, ... }:
        let
          domainDir = "${mailDirectory}/${domain}";

          vmailGID = vmailUID;
        in ''
          echo "${name}@${domain}::${toString vmailUID}:${toString vmailGID}::${domainDir}/${name}" >> \
            "${domainDir}/passwd"
          # The next line is single-quoted to prevent expansion of special
          # characters in the hashed password.
          echo '${name}@${domain}:${hashedPassword}' >> "${domainDir}/shadow"
        '') (map accountsToUser (lib.attrValues loginAccounts))}
  '';
in {
  config = lib.mkIf enable {
    # set the vmail gid to a specific value
    users.groups = {
      "${vmailGroupName}" = { gid = vmailUID; };
    };

    # define all names
    users.users = {
      "${vmail_user.name}" = lib.mkForce vmail_user;
    };

    systemd.services.activate-virtual-mail-users = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      before = [ "dovecot2.service" ];
      serviceConfig = {
        ExecStart = virtualMailUsersActivationScript;
      };
      enable = true;
    };
  };
}
