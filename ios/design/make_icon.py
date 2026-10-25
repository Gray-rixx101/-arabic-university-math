# يرسم أيقونة التطبيق بأسلوب البكسل آرت (شبكة 32×32) ويحفظها بحجم 1024.
# الاستخدام: python3 make_icon.py AppIcon.png
from PIL import Image
import math, sys
N=32; S=32
img=Image.new('RGB',(N,N)); px=img.load()
def hx(h): h=h.lstrip('#'); return tuple(int(h[i:i+2],16) for i in (0,2,4))
def lerp(a,b,t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))
top=hx('#2b1f63'); bot=hx('#0b0a12')
# clean pixel bands
for y in range(N):
    t=min(1,round((y/(N-1))*6)/6)
    for x in range(N): px[x,y]=lerp(top,bot,t)
# pixel glow rings behind the plant
cx,cy=15.5,12
for y in range(N):
    for x in range(N):
        d=math.hypot(x-cx,(y-cy)*1.05)
        if d<6.5: px[x,y]=lerp(px[x,y],hx('#5b46b8'),0.35)
        elif d<9.5: px[x,y]=lerp(px[x,y],hx('#4a389a'),0.22)
        elif d<12.5: px[x,y]=lerp(px[x,y],hx('#3a2c7c'),0.12)
def P(x,y,c):
    if 0<=x<N and 0<=y<N: px[x,y]=hx(c) if isinstance(c,str) else c
# stars
def star(x,y,core,arm):
    P(x,y,core)
    for dx,dy in [(1,0),(-1,0),(0,1),(0,-1)]: P(x+dx,y+dy,arm)
star(26,4,'#fef3c7','#a78bfa'); star(5,7,'#ede9fe','#7c6cf0')
for x,y,c in [(10,3,'#c4b5fd'),(22,8,'#ddd6fe'),(28,11,'#8b7cf6'),(3,13,'#8b7cf6'),(19,2,'#ffffff')]: P(x,y,c)
# heatmap soil: 7 cols x 3 rows
lv=['#1d3a2a','#25603a','#2f8f4e','#3fbf63','#86efac']
grid=[[1,3,2,4,3,2,3],[3,4,4,2,4,3,1],[2,3,4,4,3,4,2]]
for r,row in enumerate(grid):
    for c,l in enumerate(row):
        x0=2+c*4; y0=20+r*4
        for dx in range(3):
            for dy in range(3): P(x0+dx,y0+dy,lv[l])
        P(x0,y0,lv[min(4,l+1)]) if l<4 else P(x0,y0,'#dcfce7')
        P(x0+2,y0+2,lv[max(0,l-1)])
# leaf shape helper
LEAF='#84cc16'; LHI='#d9f99d'; LMID='#a3e635'; LDK='#3f7d12'; RIB='#65a30d'
def leaf(cx,cy,a,b,ang):
    ca,sa=math.cos(ang),math.sin(ang); pts=set()
    for y in range(N):
        for x in range(N):
            dx,dy=x-cx,y-cy
            u=dx*ca+dy*sa; v=-dx*sa+dy*ca
            # pointed leaf: width tapers toward the tip
            w=b*(1-(abs(u)/a)**2)**0.6 if abs(u)<a else -1
            if w>0 and abs(v)<=w: pts.add((x,y))
    for (x,y) in pts:
        if (x,y-1) not in pts: P(x,y,LHI)
        elif (x,y+1) not in pts: P(x,y,LDK)
        else: P(x,y,LMID)
    # midrib
    for t in range(-int(a)+1,int(a)):
        x=round(cx+t*ca); y=round(cy+t*sa)
        if (x,y) in pts and (x,y-1) in pts and (x,y+1) in pts: P(x,y,RIB)
    return pts
# stem (x=15 light, x=16 shade) from soil up
for y in range(8,20): P(15,y,'#4ade80'); P(16,y,'#15803d')
leaf(21.2,10.2,5.6,2.4,math.radians(-28))
leaf(10.2,13.6,4.6,2.0,math.radians(208))
# petioles
P(17,13,'#4ade80'); P(14,15,'#4ade80')
# top bud
for (x,y,c) in [(15,7,LMID),(16,7,LDK),(15,6,LHI),(16,6,LMID),(15,5,LHI),(14,7,LHI),(17,8,LMID)]: P(x,y,c)
# soil top shadow under stem base
P(15,20,'#14532d'); P(16,20,'#14532d')
img.resize((N*S,N*S),Image.NEAREST).save(sys.argv[1])
