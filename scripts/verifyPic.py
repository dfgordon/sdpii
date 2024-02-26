import sys
import json
import pathlib
import decode

# 0 = color [code(4),mask1(8),mask2(8)] (20)
# 1 = mode [code(4),flags(8)] (12)
# 2 = setCurs [code(4),x(10),y(8)] (22)
# 3 = plot [code(4),x(10),y(8)] (22)
# 4 = lineTo [code(4),x(10),y(8)] (22)
# 5 = hline [code(4),x1(10),x2(10),y(8)] (32)
# 6 = trap [code,x0,x1,x2,x3,y0,y1] (60)
# 7 = stroke [code(4),x(10),y(8),brush(4)] (26)

cmdCount = 0
histogram = [0]*9

def boundx(x):
    if x<0 or x>559:
        print('cmd',cmdCount,"x",x,"out of bounds")

def boundy(y):
    if y<0 or y>191:
        print('cmd',cmdCount,"y",y,"out of bounds")

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

d = decode.Decoder(bytes)
cmd = d.next()
while cmd[1]!=[0]:
    histogram[cmd[1][0]] += 1
    if cmd[0]=='mode':
        m = cmd[1][1]
        if m!=0 and m!=128:
            print('cmd',cmdCount,'unexpected mode',m)
    if cmd[0]=='curs' or cmd[0]=='plot' or cmd[0]=='lineto':
        [x0,y0] = cmd[1][1:3]
        boundx(x0)
        boundy(y0)
    if cmd[0]=='hline':
        [x0,x1,y0] = cmd[1][1:7]
        boundx(x0)
        boundx(x1)
        boundy(y0)
        if x0>x1:
            print('cmd',cmdCount,'x0>x1')
    if cmd[0]=='trap':
        [x0,x1,x2,x3,y0,y1] = cmd[1][1:7]
        boundx(x0)
        boundx(x1)
        boundx(x2)
        boundx(x3)
        boundy(y0)
        boundy(y1)
        if x0>x1:
            print('cmd',cmdCount,'x0>x1')
        if x2>x3:
            print('cmd',cmdCount,'x2>x3')
        if y0>y1:
            print('cmd',cmdCount,'y0>y1')
    if cmd[0]=='stroke':
        [x0,y0,brush] = cmd[1][1:4]
        boundx(x0)
        boundy(y0)
        if brush<0 or brush>6:
            print('cmd',cmdCount,'unexpected brush',brush)
    cmd = d.next()
    cmdCount += 1

print(cmdCount,'commands')
print('histogram',histogram)