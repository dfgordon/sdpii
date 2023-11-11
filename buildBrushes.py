'''Metaprogram creating HEX pseudo-ops representing elliptical brushes.'''

# this has the elliptical shapes (not found to be so useful)
#grids = [(4,3),(8,4),(12,5),(18,8),(24,10),(36,15),(48,20),(12,10),(24,20),(24,4),(48,8)]

# this has only the roughly circular ones
grids = [(4,3),(8,4),(12,5),(18,8),(24,10),(36,15),(48,20)]

asmStr = ''

def hc(x,bits):
    ans = hex(x)[2:]
    if len(ans)>int(bits/4):
        raise ValueError('cannot represent '+ans+' with '+str(bits)+' bits')
    while len(ans)<int(bits/4):
        ans = '0'+ans
    return ans

def ellipse(xp,yp,a,b):
    if xp**2/a**2+yp**2/b**2 <= 1.001:
        return 1
    return 0

offset = 0
asmStr += '* following are big endian' + '\n'
asmStr += 'brushTbl HEX   '
for b in grids:
    asmStr += hc(offset,16)
    offset += 2 + b[1]*(1+int((b[0]-1)/8))
asmStr += '\n'

for b in grids:
    xend = b[0]
    yend = b[1]
    if xend==grids[0][0] and yend==grids[0][1]:
        line = 'brushes  HEX   ' + hc(xend,8) + hc(yend,8)
    else:
        line = '         HEX   ' + hc(xend,8) + hc(yend,8)
    a = (xend-1)/2
    b = (yend-1)/2
    print(a,b)
    for y in range(yend):
        val = 0
        bits = 0
        for x in range(xend):
            val += 2**(7-bits)*ellipse(x-a,y-b,a+1,b+1)
            bits += 1
            if bits==8:
                line += hc(val,8)
                val = 0
                bits = 0
            if len(line)>58:
                asmStr += line + '\n'
                line = '         HEX   '
        if bits>0:
            line += hc(val,8)
    if line[-1]!=' ':
        asmStr += line + '\n'

print(asmStr)