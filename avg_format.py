#!/usr/bin/python

import fileinput

native = float(0)
guest = float(0)

for line in fileinput.input():
    test = line.split('.')[2]
    if line.find("guest") >= 0:
        guest = float(line.split()[1])
    else:
        native = float(line.split()[1])
    if guest > 0 and native > 0:
        print "%s\t%f\t%f" % (test, native, guest)
        guest = 0
        native = 0
