'''Encode picture elements as bitstream.
Parallels ASM code.'''

class Encoder:
    def __init__(self):
        self.buf = bytearray()
        self.lookBehind = bytearray.fromhex("00")
        self.bitPtr = 8
    def stBits(self,numBits,val):
        '''store something 8 bits or less'''
        accum = bytearray([val])
        for b in range(numBits):
            self.lookBehind[0] = ((1 & accum[0]) << 7) + (self.lookBehind[0] >> 1)
            accum[0] >>= 1
            self.bitPtr -= 1
            if self.bitPtr==0:
                self.buf.append(self.lookBehind[0])
                self.bitPtr = 8
    def storeX(self,x):
        self.stBits(8,x%256)
        self.stBits(2,int(x/256))
    def end(self):
        self.stBits(3,0b000)
        if self.bitPtr%8!=0:
            for b in range(self.bitPtr):
                self.lookBehind[0] >>= 1
            self.buf.append(self.lookBehind[0])
    def color(self,c1,c2):
        self.stBits(3,1)
        self.stBits(8,c1)
        self.stBits(8,c2)
    def xor(self,x):
        self.stBits(3,2)
        self.stBits(1,x)
    def curs(self,x,y):
        self.stBits(3,3)
        self.storeX(x)
        self.stBits(8,y)
    def plot(self,x,y):
        self.stBits(3,4)
        self.storeX(x)
        self.stBits(8,y)
    def lineto(self,x,y):
        self.stBits(3,5)
        self.storeX(x)
        self.stBits(8,y)
    def trap(self,x0,x1,x2,x3,y0,y1):
        self.stBits(3,6)
        self.storeX(x0)
        self.storeX(x1)
        self.storeX(x2)
        self.storeX(x3)
        self.stBits(8,y0)
        self.stBits(8,y1)
    def stroke(self,x,y,brush):
        self.stBits(3,7)
        self.storeX(x)
        self.stBits(8,y)
        self.stBits(3,brush)
    def getHex(self):
        '''See how it was encoded'''
        print(self.buf.hex(' '))
    def getAry(self) -> bytearray:
        return self.buf
    
