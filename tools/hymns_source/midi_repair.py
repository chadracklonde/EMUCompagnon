import struct,sys,io,mido
def repair(src,dst):
    b=open(src,'rb').read()
    fmt,n,div=struct.unpack('>HHH',b[8:14])
    pos=14;good=[];bad=[]
    while pos<len(b):
        ln=struct.unpack('>I',b[pos+4:pos+8])[0]
        chunk=b[pos:pos+8+ln]
        test=b'MThd'+struct.pack('>IHHH',6,1,1,div)+chunk
        try:
            mido.MidiFile(file=io.BytesIO(test)); good.append(chunk)
        except Exception as e:
            bad.append((len(good)+len(bad),str(e)))
        pos+=8+ln
    open(dst,'wb').write(b'MThd'+struct.pack('>IHHH',6,1,len(good),div)+b''.join(good))
    return len(good),bad
if __name__=='__main__':
    print(repair(sys.argv[1],sys.argv[2]))
