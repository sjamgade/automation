#!/usr/bin/env python
from __future__ import print_function

import re
import sys

from collections import OrderedDict
from datetime import datetime
from itertools import product


def store(rexs, data, state, line):
    elements = None
    if 'key' in rexs.keys():
        key = re.search(rexs['key'], line)
        value = re.search(rexs['value'], line)
        if key and value:
            elements = dict(key=key.groups()[0], value=value.groups()[0])
    elif 'all' in rexs.keys():
        found = re.search(rexs['all'], line)
        if found:
            elements = found.groupdict()
    if elements and len(elements) == 2:
        data.setdefault(elements['key'], {})
        data[elements['key']][state] = elements['value']
        return elements['key']
    return None


def parsedates(parser, values):
    parsed = map(parser, values)
    try:
        return (parsed[0] - parsed[1]).seconds
    except:
        return -1


def parsejobs(lgloc):
    lg = None
    with open(lgloc) as f:
        lg = f.read()
    if not lg:
        print('{} read failure'.format(lgloc))
        return
    lg = (l for l in lg.split('\n') if l)
    data = {'steps': OrderedDict(), 'proposal': OrderedDict()}

    def makeparser(fmt):
        return lambda x: datetime.strptime(x, fmt)

    vparsers = {}
    vparsers['steps'] = makeparser('%Y-%m-%d %H:%M:%S')
    vparsers['proposal'] = makeparser('%a %b %d %H:%M:%S %Z %Y')
    for line in lg:
        for tsk, ttype in product(('steps', 'proposal'), ('start', 'finish')):
            tskdata = data[tsk]
            key = store(rxs[tsk][ttype], tskdata, ttype, line)
            if key:
                if ttype == 'start':
                    duration = -1
                else:
                    times = [tskdata[key]['finish'], tskdata[key]['start']]
                    duration = parsedates(vparsers[tsk], times)
                tskdata[key]['duration'] = duration
                break
    return data

rxs = {}
rxs['steps'] = dict(
    start={'all': '(?<=step started at )(?P<value>.*): (?P<key>\w+)$'},
    finish={'all': '(?<=step finished at )(?P<value>.*): (?P<key>\w+)$'}
)
rxs['proposal'] = dict(
    start={'all': '(?<=Starting proposal )(?P<key>.*) at: (?P<value>.*)'},
    finish={'all': '(?<=Finished proposal )(?P<key>.*) at: (?P<value>.*)'}
)
if __name__ == '__main__':
    data = parsejobs(sys.argv[1])
    for key in data:
        for part, parttimes in data[key].items():
            printables = (key.upper(), part) + tuple(parttimes.values())
            col_sizes = [10, 20, 5, 15, 15][:len(printables)]
            fmt = ','.join(('%{}s'.format(i) for i in col_sizes))
            print(fmt % printables)
