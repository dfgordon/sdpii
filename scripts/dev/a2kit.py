'''Simple example of a Python front-end.  The backend interface is mirrored exactly.'''

import subprocess

def verify(beg_vers: tuple, end_vers: tuple):
    '''Exit if a2kit version falls outside range beg_vers..end_vers'''
    vers = tuple(map(int, cmd(['-V']).decode('utf-8').split()[1].split('.')))
    if vers < beg_vers or vers >= end_vers:
        print("a2kit version outside range",beg_vers,"..",end_vers)
        exit(1)

def cmd(args, pipe_in=None):
    '''run a CLI command as a subprocess'''
    compl = subprocess.run(['a2kit']+args,input=pipe_in,capture_output=True,text=False)
    if compl.returncode>0:
        print(compl.stderr)
        exit(1)
    return compl.stdout
