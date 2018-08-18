## Issue description

### What I expected to happen:

### What happened:

## Technical details

<!--
If possible, please run `nix-shell -p nix-info --run "nix-info -m"` on the mail
server and paste the results in a fenced code block:
https://about.gitlab.com/handbook/product/technical-writing/markdown-guide/#code-blocks

Otherwise, please specify the NixOS version (e.g. 18.03 or unstable) that the
mail server is running on.
-->

### SNM Version

<!--
For example, `v2.1.3` or the output of `git log -1` if you're using a git submodule.
-->

### Relevant part of the config to reproduce:
<!--
If applicable, please paste your `mailserver` config here and redact any
sensitive details such as `hashedPassword`.
-->

### Relevant `journald` log:

<!--
For example, if you're having a problem with Dovecot, first identity the Dovecot
service name by examining the output of `systemctl list-unit-files`.  Notice
that it is `dovecot2.service`, so paste here relevant lines from the output of
`journalctl -u dovecot2 --since="today" | less`.

If you don't know what particular unit is causing the problem, you can search
for details in the output of `journalctl --since="today" | less`.
-->
