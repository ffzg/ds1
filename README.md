# Remove FreeIPA and create local users

We had one instance of FreeIPA which was used by single server which
stopped working because of expired certificates, so easiest solution
was to remote it and create local accounts

## export ldif from FreeIPA

```
[root@ds1 ~]# db2ldif -n userRoot -a /tmp/export.ldif
```

## using sss cache to get passwd

If your sss still has cache available, you can use it to dump
temporary passwd entries for later verification:

```
grep uidNumber: export.ldif  | cut -d: -f2 | xargs -i getent passwd {} > passwd.getnet
```

Have in mind that sss cache might not have all entries available, so this is
not best way to get full passwd file.

## convert ldif dump to passwd, group and shadow file

```
./ldif2files.pl export.ldif
```

This will produce shadow file in format:

```
login:{SSHA}PasswordHashFromLDAPuserPasswordFieldx==:18712:0:99999:7:::
```

To solve this issue see blog post on how to use {SSHA} passwords using pam_exec

https://rolandtapken.de/blog/2016-03/migrate-user-accounts-openldap-unix-system-user

so install script from

https://gist.github.com/Cybso/2016e4de9a2465cef920





## remove sss from /etc/nsswitch.conf

Make sure to enable normal authorized_keys in /etc/ssh/sshd_config instead of
AuthorizedKeysCommand /usr/bin/sss_ssh_authorizedkeys
