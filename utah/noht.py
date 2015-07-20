#!/usr/bin/python

import os
import re


def get_core_id(cpu):
    path = '/sys/devices/system/node/node0/%s/topology/core_id' % (cpu)
    if not os.path.exists(path):
        return -1

    with open(path, 'r') as f:
        coreid = f.readlines()[0].strip()
    return int(coreid)


corelist = []
p = re.compile('cpu\d+')
for d in os.listdir('/sys/devices/system/node/node0'):
    if p.match(d):
        core_id = get_core_id(d)
        if core_id == -1:
            continue

        if core_id in corelist:
            path = '/sys/devices/system/node/node0/%s/online' % (d)
            with open(path, 'w') as f:
                    f.write("0")
        else:
            corelist.append(core_id)

