# Quick-Start Guide

Let's take a fresh Ubuntu machine, install Docker, install the BedquiltDB docker image
and write a small program to check that BedquiltDB works.

We'll presume we have an admin account on a fresh installation of Ubuntu 16.04:

```bash
$ uname -a
Linux ub 4.4.0-36-generic #55-Ubuntu SMP Thu Aug 11 18:01:55 UTC 2016 x86_64 x86_64 x86_64 GNU/Linux
```

## Install Docker and the BedquiltDB Example Image


First, [install docker](https://docs.docker.com/engine/installation/), it's ok, we'll wait right here...

Now that docker is installed, we should test that the docker daemon is working correctly:

```bash
$ sudo docker run hello-world
```

Now, pull the `bedquiltdb` image:

```bash
$ sudo docker pull bedquiltdb/bedquiltdb
```

And run that image as a container called `bq`:

```bash
docker run -d -P --name bq bedquiltdb/bedquiltdb
```

Now that the BedquiltDB container is running, we need to take note of the port which postgres is bound to:

```bash
$ sudo docker ps --format '{{.Names}} - {{.Ports}}'
```

There should be a line of output like:

```
bq - 0.0.0.0:32768->5432/tcp
```

Which shows that localhost:32768 is the port we need to connect to. In your case, this port number will be different, take note of this port number.

We can use this port to connect to the database. There is already a user called `docker` set up
in the container (with a password `docker`), and a default database also called `docker`, so we can start using BedquiltDB right away.


## Write a python program

We're going to write a small python program which will connect to the BedquiltDB server and do
some simple read and write operations.

### Install the pybedquilt driver

We need to install the [pybedquilt](https://pypi.python.org/pypi/pybedquilt) driver:

```
$ sudo apt-get install python-pip libpq-dev build-essential python-dev
$ sudo pip install psycopg2 pybedquilt
```

### Program

Let's write a simple python program, use your favourite editor to create a file `counts.py`, and
put the following program text in it:

```python
from pybedquilt import BedquiltClient

db = BedquiltClient(
    host='localhost',
    port='<PORT_HERE>',
    dbname='docker',
    user='docker'
)

things = db['things']

current_count = things.count()
print ">> there are currently {} things in the collection".format(current_count)
```

Be sure to change `<PORT_HERE>` to the port number you noted down earlier.

Now run the program:

```bash
$ python counts.py
>> there are currently 0 things in the collection
```

If all is well, you should see some text indicating that there are 0 things in
the 'things' collection. Let's add an insert operation which will add one
thing to the collection every time we run the program:

```
from pybedquilt import BedquiltClient

db = BedquiltClient(
    host='localhost',
    port='<PORT_HERE>',
    dbname='docker',
    user='docker'
)

things = db['things']

current_count = things.count()
print ">> there are currently {} things in the collection".format(current_count)

new_id = things.insert({'color': 'green'})
print ">> just inserted document with id: {}".format(new_id)

new_count = things.count()
print ">> there are now {} things in the collection".format(new_count)
```

And that's pretty much it, you've now got an instance of PostgreSQL, with BedquiltDB, running inside a docker container, and a small python program which connects to that database to do some simple insert and read operations.


## What Next?

Check out the full documentation for the `bedquiltdb` docker image on [Docker Hub](https://hub.docker.com/r/bedquiltdb/bedquiltdb/), or move on to reading the rest of the [BedquiltDB Guide](index.md)

Or, read the [Spec](../spec.md), to get an overview of all the cool stuff BedquiltDB supports.
