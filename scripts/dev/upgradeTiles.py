import sys
import pathlib
import json
import a2kit

a2kit.verify((3,2,0),(4,0,0))

print("This converts v0.0.0 tiles to v0.1.0 tiles")

if len(sys.argv)!=2:
    print("provide the path to a disk image")
    exit(1)

print(a2kit.cmd(['dir','-d',sys.argv[1]]).decode('utf-8'))

fname = input("file to convert: ")

fimg = a2kit.cmd(['get','-d',sys.argv[1],'-f',fname,'-t','any']).decode('utf-8')
aux = json.loads(fimg)['aux']
load_addr = int(aux[0:2],16) + int(aux[2:4],16)*256

oldbytes = bytearray(a2kit.cmd(['unpack','-t','bin'],fimg.encode('utf-8')))
newbytes = bytearray(a2kit.cmd(['unpack','-t','bin'],fimg.encode('utf-8')))
eof = len(oldbytes)

print("processing",eof,"bytes")

cols = newbytes[0]
rows = newbytes[1]
auxEnd = cols*rows*8
mainEnd = cols*rows*16
tiles = int((eof - 2)/mainEnd)

print('tile size is',cols,'by',rows)
print('tile count =',tiles)

ptr = 2
for k in range(tiles):
    for i in range(cols):
        for j in range(rows*8):
            newbytes[ptr+auxEnd-i-j*cols-1] = oldbytes[ptr+i*2+j*cols*2]
            newbytes[ptr+mainEnd-i-j*cols-1] = oldbytes[ptr+i*2+1+j*cols*2]
    ptr += mainEnd

a2kit.cmd(['delete','-d',sys.argv[1],'-f',fname])
a2kit.cmd(['put','-d',sys.argv[1],'-f',fname,'-t','bin','-a',str(load_addr)],newbytes)

print(a2kit.cmd(['dir','-d',sys.argv[1]]).decode('utf-8'))
