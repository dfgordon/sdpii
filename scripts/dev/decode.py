'''Decode picture elements from bitstream.
Parallels ASM code.'''

class Decoder:
    def __init__(self,buf: bytearray):
        self.buf = buf.copy()
        self.buf.append(0)
        self.buf.append(0)
        self.lookAhead = bytearray(buf[0:1])
        self.bitPtr = 8
        self.bytPtr = 0
    def rdBits(self,numBits):
        '''read something 8 bits or less'''
        accum = bytearray.fromhex("00")
        for b in range(numBits):
            accum[0] = ((1 & self.lookAhead[0]) << 7) + (accum[0] >> 1)
            self.lookAhead[0] >>= 1
            self.bitPtr -= 1
            if self.bitPtr==0:
                self.bytPtr += 1
                self.lookAhead[0] = self.buf[self.bytPtr]
                self.bitPtr = 8
        for b in range(8-numBits):
            accum[0] >>= 1
        return accum[0]
    def getX(self):
        x = self.rdBits(8)
        x += self.rdBits(2)*256
        return x
    def next(self):
        cmd = self.rdBits(3)
        if cmd==1:
            return self.dcColor()
        elif cmd==2:
            return self.dcMode()
        elif cmd==3:
            return self.dcCurs()
        elif cmd==4:
            return self.dcPlot()
        elif cmd==5:
            return self.dcLineTo()
        elif cmd==6:
            return self.dcTrap()
        elif cmd==7:
            return self.dcStroke()
        elif cmd==0:
            return "end",[0]
        else:
            return "unexpected code",[0]
    def dcColor(self):
        c1 = self.rdBits(8)
        c2 = self.rdBits(8)
        return "color",[1,c1,c2]
    def dcMode(self):
        m = self.rdBits(1)
        return "mode",[2,m]
    def dcCurs(self):
        x = self.getX()
        y = self.rdBits(8)
        return "curs",[3,x,y]
    def dcPlot(self):
        x = self.getX()
        y = self.rdBits(8)
        return "plot",[4,x,y]
    def dcLineTo(self):
        x = self.getX()
        y = self.rdBits(8)
        return "lineto",[5,x,y]
    def dcTrap(self):
        x0 = self.getX()
        x1 = self.getX()
        x2 = self.getX()
        x3 = self.getX()
        y0 = self.rdBits(8)
        y1 = self.rdBits(8)
        return "trap",[6,x0,x1,x2,x3,y0,y1]
    def dcStroke(self):
        x = self.getX()
        y = self.rdBits(8)
        brush = self.rdBits(3)
        return "stroke",[7,x,y,brush]
    
