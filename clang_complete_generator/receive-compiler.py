#/usr/bin/env python3
import subprocess
from collections import deque
import os
import signal
import sys

tail_proc = None
output_path = None
results_written = False

def tailf(filename):
    #returns lines from a file, starting from the beginning
    command = "tail -f " + filename
    print(command)
    global tail_proc
    tail_proc = subprocess.Popen(command.split(), stdout=subprocess.PIPE, universal_newlines=True)
    for line in tail_proc.stdout:
        yield line

includes = set()
defines = set()
headers = set()
arch = set()

def check_prefix(word, dq, prefix):
    if word.startswith(prefix):
        if word == prefix:
            word = prefix + dq.popleft()
        return word[len(prefix):]
    return None

def process_line(line):
    d = deque(line.split(' '))
    pwd = d.popleft()
    while len(d) > 0:
        word = d.popleft()
        res = check_prefix(word, d, '-I')
        if not res:
            res = check_prefix(word, d, '-isystem')
        if res:
            if res.startswith('/'):
                includes.add(res)
            else:
                includes.add(os.path.abspath(os.path.join(pwd, res)))
            continue

        res = check_prefix(word, d, '-D')
        if res:
            defines.add(res)
            continue

        res = check_prefix(word, d, '-include')
        if res:
            if res.startswith('/'):
                includes.add(res)
            else:
                headers.add(os.path.abspath(os.path.join(pwd, res)))
            continue

        res = check_prefix(word, d, '-m')
        if res:
            arch.add(word)
            continue

def write_results():
    global results_written
    global output_path
    if results_written:
        return
    else:
        results_written = True
    print('writing results')
    with open(output_path, 'w') as out:
        for tup in (
                ('-m {0}\n', arch),
                ('-I {0}\n', includes),
                ('-D {0}\n', defines),
                ('-include {0}\n', headers)
                ):
            for item in tup[1]:
                out.write(tup[0].format(item))

def receive_signal(sig_num, frame):
    global tail_proc
    tail_proc.terminate()
    write_results()

if len(sys.argv) != 3:
    print('USAGE: {0} <pipe_path> <output_path>')
    exit(-1)

pipe_path = sys.argv[1]
output_path = sys.argv[2]

for sig in [signal.SIGTERM, signal.SIGINT]:
    signal.signal(sig, receive_signal)

for line in tailf(pipe_path):
    line = line.rstrip('\n')
    if line == '__EOF__':
        break
    print('RECORDING: ' + line)
    process_line(line)

write_results()
tail_proc.terminate()
