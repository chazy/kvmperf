#!/usr/bin/python

import fileinput
import re


substrings = ["enabling apic", "VNC",
              "cr0 =", "cr1 =", "cr2 =", "cr3 =", "cr4 =", "cr5 =", "cr6 =",
              "paging enabled", "pci-testdev", "no tsc control"]

pattern = "(?:%s)" % "|".join(map(re.escape, substrings))

pattern = re.compile(pattern)


if __name__ == "__main__":
    samples = {}
    lines = fileinput.input()

    for line in [x for x in lines if not pattern.search(x)]:
        test = line.split()[0]
        cycles = line.split()[1]
        if not test in samples:
            samples[test] = []
        samples[test].append(cycles)
    for test in samples.keys():
        print "%s\t%s" % (test, "\t".join(samples[test]))
    print "\nAverage:"
    for test in samples.keys():
        vals = map(int, samples[test])
        print "%s\t%d" % (test, sum(vals)/len(vals))
