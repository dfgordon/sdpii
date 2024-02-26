'''see if the bit code inverts correctly'''
import encode
import decode

e = encode.Encoder()
e.plot(0,0)
e.plot(500,100)
e.color(15,240)
e.mode(128)
e.lineto(50,90)
e.mode(0)
e.color(15,15)
e.trap(10,100,20,110,50,90)
e.stroke(280,80,6)
e.curs(559,191)
e.lineto(0,0)
e.end()

d = decode.Decoder(e.getAry())
cmd = d.next()
while cmd[1]!=[0]:
    print(cmd)
    cmd = d.next()
