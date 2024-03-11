import sys
import json
import pathlib
import encode

# convert pre-release picture encoding to bit code

# old picture codes as byte stream
# 0 = color [code,mask1,mask2] (3)
# 1 = mode [code,flags] (2)
# 2 = draw [code,aux1,aux2] (3)
# 3 = plot [code,xl,xh,y] (4)
# 4 = hline [code,x1l,x1h,y,x2l,x2h] (6)
# 5 = line [code,x2l,x2h,y2,x1l,x1h,y1] (7, note reversed)
# 6 = trap [code,x0l,x0h,y0,x1l,x1h,x2l,x2h,y1,x3l,x3h] (11)
# 7 = stroke [code,xl,xh,y,brush] (5)

# new picture codes as bit stream
# 0 = end (3)
# 1 = color [code(3),mask1(8),mask2(8)] (19)
# 2 = xor [code(3),flag(1)] (4)
# 3 = setCurs [code(3),x(10),y(8)] (21)
# 4 = plot [code(3),x(10),y(8)] (21)
# 5 = lineTo [code(3),x(10),y(8)] (21)
# 6 = trap [code,x0,x1,x2,x3,y0,y1] (59)
# 7 = stroke [code(3),x(10),y(8),brush(3)] (24)

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

encoder = encode.Encoder()

ptr = 0
cmdCount = 0
while ptr<len(bytes):
    if bytes[ptr]==0:
        encoder.color(bytes[ptr+1],bytes[ptr+2])
        ptr += 3
    if bytes[ptr]==1:
        encoder.xor(1 if bytes[ptr+1]==128 else 0)
        ptr += 2
    if bytes[ptr]==2:
        raise ValueError("recursive draw not allowed")
    if bytes[ptr]==3:
        x = bytes[ptr+1]+256*bytes[ptr+2]
        encoder.plot(x,bytes[ptr+3])
        ptr += 4
    if bytes[ptr]==4:
        raise ValueError("hline not allowed")
    if bytes[ptr]==5:
        x1 = bytes[ptr+1]+256*bytes[ptr+2]
        x0 = bytes[ptr+4]+256*bytes[ptr+5]
        y0 = bytes[ptr+6]
        y1 = bytes[ptr+3]
        encoder.curs(x0,y0)
        encoder.lineto(x1,y1)
        ptr += 7
    if bytes[ptr]==6:
        x0 = bytes[ptr+1]+256*bytes[ptr+2]
        y0 = bytes[ptr+3]
        x1 = bytes[ptr+4]+256*bytes[ptr+5]
        x2 = bytes[ptr+6]+256*bytes[ptr+7]
        y1 = bytes[ptr+8]
        x3 = bytes[ptr+9]+256*bytes[ptr+10]
        encoder.trap(x0,x1,x2,x3,y0,y1)
        ptr += 11
    if bytes[ptr]==7:
        x = bytes[ptr+1]+256*bytes[ptr+2]
        encoder.stroke(x,bytes[ptr+3],bytes[ptr+4]-1)
        ptr += 5
    if bytes[ptr]==255:
        encoder.end()
        ptr += 1
        break
    if bytes[ptr]>7 and bytes[ptr]!=255:
        print("bad command code",bytes[ptr])
        exit(1)
    cmdCount += 1

if ptr!=len(bytes):
    print("prematurely terminated")

bytes_out = encoder.getAry()

print("found",cmdCount,"cmds")
print("new length",len(bytes_out))

old_fname = pathlib.Path(sys.argv[1]).name
with open(old_fname + ".bits","wb") as f:
    f.write(bytes_out)