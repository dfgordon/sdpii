import sys
import pathlib
import json

if len(sys.argv)!=2:
    print("provide the path to a file image")
    exit(1)

with open(pathlib.Path(sys.argv[1])) as f:
    fimg = json.load(f)

le_eof = bytearray.fromhex(fimg['eof'])
eof = le_eof[0] + le_eof[1]*256 + le_eof[2]*256*256
print("processing",eof,"bytes")

bytes = bytearray()
for chunk in range(len(fimg['chunks'])):
    hex: str = fimg['chunks'][str(chunk)]
    dat = bytearray.fromhex(hex)
    bytes.extend(dat)
bytes = bytes[0:eof]

cols = bytes[0]
rows = bytes[1]
tileWords = int((eof-2)/2)
if cols!=1:
    raise ValueError("only works for 14 pixel wide tiles")

print('tile size is',cols,'by',rows)
print('tile words =',tileWords)

ptr = 2
for k in range(tileWords):
    # remember high bits have to be handled specially,
    # and A2 screen bits in reverse order
    rbits = (bytes[ptr+1] & 0x7f) >> 2
    lbits = (bytes[ptr] & 0x7f) >> 2
    lbits |= (bytes[ptr+1] & 3) << 5
    bytes[ptr] = lbits
    bytes[ptr+1] = rbits
    ptr += 2

with open(pathlib.Path(sys.argv[1] + ".nudge"),"wb") as f:
    f.write(bytes)


