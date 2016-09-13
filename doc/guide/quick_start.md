# Quick-Start Guide

Let's take a fresh Ubuntu machine, install Docker, install the BedquiltDB docker image
and write a small program to check that BedquiltDB works.

We'll presume we have an admin account on a fresh installation of Ubuntu 14.04:

```bash
$ uname -a
Linux bedquiltplayground 3.16.0-23-generic #31-Ubuntu SMP Tue Oct 21 17:56:17 UTC 2014 x86_64 x86_64 x86_64 GNU/Linux
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

Now that the BedquiltDB container is runnig, we need to take note of its IP address:

```bash
$ sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' bedquilt
```

We can use this IP address to connect to the database. There is already a user called `docker` set up
in the container (with a password `docker`), and a default database also called `docker`, so we can start
using BedquiltDB right away.


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
put the following programe text in it:

```python
from pybedquilt import BedquiltClient

db = BedquiltClient(
    host='<IP_ADDRESS_HERE>',
    dbname='postgres',
    user='docker',
    password='docker'
)

things = db['things']

current_count = things.count()
print ">> there are currently {} things in the collection".format(current_count)

```

Be sure to change `<IP_ADDRESS_HERE>` to the IP address of the database container.

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
    host='<IP_ADDRESS_HERE>',
    dbname='postgres',
    user='docker',
    password='docker'
)

things = db['things']

current_count = things.count()
print ">> there are currently {} things in the collection".format(current_count)

new_id = things.insert({'color': 'green'})
print ">> just inserted document with id: {}".format(new_id)

new_count = things.count()
print ">> there are now {} things in the collection".format(new_count)
```

And that's pretty much it.
