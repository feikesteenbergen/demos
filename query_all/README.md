Introduction
============

This script allows you to query multiple defined PostgreSQL services and output the results as CSV.

Usage
=====
```text
Execute given query on multiple PostgreSQL databases

positional arguments:
  services              Run on these PostgreSQL services

optional arguments:
  -h, --help            show this help message and exit
  -c CONFIG, --config CONFIG
                        Read config from this file
  -f FILE, --file FILE  File containing the query
  -i INJECT, --inject INJECT
                        File containing the ids to inject
  -o OUTPUT, --output OUTPUT
                        File to write the output to
  --loglevel LOGLEVEL   Set the loglevel explicitly
```

Example
-------
The following will execute the query in `select1.sql` in parallel
on the services `rds_freetier` and `mydb` and return the output to the console.

```text
$ cat select1.sql
SELECT current_catalog,
       clock_timestamp();
$ python query_all.py --file=select1.sql rds_freetier mydb
wiki,2015-12-11 15:33:26.199386+01
myuser,2015-12-11 15:33:26.199386+01
```


Connection Service File
=======================
This script requires that you have a [`pg_service`](http://www.postgresql.org/docs/current/static/libpq-pgservice.html)
file setup. By default the file is stored here:

* Windows: `%APPDATA%\postgresql\.pg_service.conf`

     For more details see [superuser.com](http://superuser.com/a/729261)

* Linux: `~/.pg_service.conf`


Example contents of a service file
--------------------------------
```text
[mydb]
host=localhost
port=5432
username=johnny
password=DonTPutYourPasswordInPgService.confIfItIsNotSecured!
dbname=myuser

[order_production]
host=db.example.com
port=5432
ssl=verify-full
dbname=order

[rds_freetier]
example.random.eu-central-1.rds.amazonaws.com
port=5432
user=rdsadmin
sslmode=verify-full
sslrootcert=/home/myuser/.postgresql/rds-combined-ca-bundle.pem
dbname=wiki
```
