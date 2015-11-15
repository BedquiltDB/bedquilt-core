# Quick-Start Guide

Let's take a fresh Ubuntu machine, install Docker, install the BedquiltDB docker image
and write a small program to check that BedquiltDB works.

We'll presume we have an admin account on a fresh installation of Ubuntu 14.04:

```bash
$ uname -a
Linux bedquiltplayground 3.16.0-23-generic #31-Ubuntu SMP Tue Oct 21 17:56:17 UTC 2014 x86_64 x86_64 x86_64 GNU/Linux
```

## Install Docker and the BedquiltDB Example Image

First we need to install Docker and some essential tools:

```bash
$ sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
$ echo 'deb https://apt.dockerproject.org/repo ubuntu-trusty main' | sudo tee /etc/apt/sources.list.d/docker.list
$ sudo apt-get update
$ sudo apt-get install linux-image-extra-$(uname -r)
$ sudo apt-get install docker-engine
```

We should test that the docker daemon is working correctly:

```bash
$ sudo docker run hello-world
```

If all looks well, we can build the [BedquiltDB Example image](https://github.com/BedquiltDB/docker-bedquiltdb-example):

```bash
$ git clone https://github.com/BedquiltDB/docker-bedquiltdb-example
$ cd docker-bedquiltdb-example
$ sudo docker build -t "bedquiltdb_example" .
```

Then start a docker container from the bedquiltdb_example image:

```bash
$ sudo docker run -d --name bedquiltdb bedquiltdb_example
```

Now that the BedquiltDB container is runnig, we need to take note of its IP address:

```bash
$ sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' bedquiltdb
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
