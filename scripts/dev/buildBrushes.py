'''Metaprogram creating HEX pseudo-ops representing elliptical brushes.
The brush is described as a set of hlines.  It is important
therefore that the library have an efficient hline routine.'''

# this has the elliptical shapes (not found to be so useful)
#grids = [(4,3),(8,4),(12,5),(18,8),(24,10),(36,15),(48,20),(12,10),(24,20),(24,4),(48,8)]

# this has only the roughly circular ones
grids = [(4,3),(8,4),(12,5),(18,8),(24,10),(36,15),(48,20)]

asmStr = ''

class hlin:
    offset = 0
    run = 0
    def __str__(self):
        return str(self.offset) + "," + str(self.run)

def hc(x: int,bits: int) -> str:
    '''hex string representing `x` with padding to encompass requested bit count'''
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

brushes = []

for (xend,yend) in grids:
    brushes += [[]]
    a = (xend-1)/2
    b = (yend-1)/2
    for y in range(yend):
        line = hlin()
        running = False
        for x in range(xend):
            # do it this way to keep new brushes same as old brushes
            if (not running) and ellipse(x-a,y-b,a+1,b+1)==1:
                line.offset = x
                running = True
            if running and ellipse(x-a,y-b,a+1,b+1)==0:
                line.run = x - line.offset
                running = False
                break
        if running:
            line.run = xend - line.offset
        brushes[-1] += [line]

asmStr += 'brushTbl\n'
offset = 0
asmStr += '         HEX   '
for b in brushes:
    asmStr += hc(offset,8) + ','
    offset += 2*len(b) + 1
asmStr = asmStr[:-1]
asmStr += '\n'

asmStr += 'brushes\n'
for b in brushes:
    asmStr += '         HEX   ' + hc(len(b),8) + '\n'
    asmStr += '         HEX   '
    for l in b:
        asmStr += hc(l.offset,8)
    asmStr += '\n'
    asmStr += '         HEX   '
    for l in b:
        asmStr += hc(l.run,8)
    asmStr += '\n'

print(asmStr)