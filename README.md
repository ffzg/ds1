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










## remove sss from /etc/nsswitch.conf
