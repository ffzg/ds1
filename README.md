# Remove FreeIPA and create local users

We had one instance of FreeIPA which was used by single server which
stopped working because of expired certificates, so easiest solution
was to remote it and create local accounts

## export ldif from FreeIPA


[root@ds1 ~]# db2ldif -n userRoot -a /tmp/export.ldif
