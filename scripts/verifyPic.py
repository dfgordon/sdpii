import sys
import json
import pathlib

# picture codes
# 0 = color [code,mask1,mask2] (3)
# 1 = mode [code,flags] (2)
# 2 = draw [code,aux1,aux2] (3)
# 3 = plot [code,xl,xh,y] (4)
# 4 = hline [code,x1l,x1h,y,x2l,x2h] (6)
# 5 = line [code,x2l,x2h,y2,x1l,x1h,y1] (7, note reversed)
# 6 = trap [code,x0l,x0h,y0,x1l,x1h,x2l,x2h,y1,x3l,x3h] (11)
# 7 = stroke [code,xl,xh,y,brush] (5)

# new picture codes
# 0 = color [code,mask1,mask2] (3)
# 1 = mode [code,flags] (2)
# 2 = draw [code,aux1,aux2] (3)
# 3 = plot [{0-3=code,4-5=xh},xl,y] (3)
# 4 = hline [{0-3=code,4-5=x1h,6-7=x2h},x1l,x2l,y] (4)
# 5 = line [{0-3=code,4-5=x2h,6-7=x1h},x2l,x1l,y2,y1] (5, note reversed)
# 6 = trap [{0-3=code,4-5=x0h,6-7=x1h},x0l,x1l,{4-5=x2h,6-7=x3h},x2l,x3l,y0,y1] (8)
# 7 = stroke [{0-3=code,4-5=xh},xl,y,brush] (4)

cmdLen = [3,2,3,4,6,7,11,5]

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

ptr = 0
cmdCount = 0
while ptr<len(bytes):
    if bytes[ptr]==6:
        x0 = bytes[ptr+1] + bytes[ptr+2]*256
        y0 = bytes[ptr+3]
        x1 = bytes[ptr+4] + bytes[ptr+5]*256
        x2 = bytes[ptr+6] + bytes[ptr+7]*256
        y1 = bytes[ptr+8]
        x3 = bytes[ptr+9] + bytes[ptr+10]*256
        if x0>=x1 or x2>=x3 or y0>=y1:
            print("bad trap",cmdCount,"params",x0,x1,y0,x2,x3,y1)
    if bytes[ptr]>7:
        if bytes[ptr]==255 and ptr==len(bytes)-1:
            print("found terminator")
            break
        else:
            print("cmd",cmdCount,"bad code",bytes[ptr])
        exit(1)
    ptr += cmdLen[bytes[ptr]]
    cmdCount += 1

if ptr!=len(bytes)-1:
    print("prematurely terminated")

print("found",cmdCount,"cmds")