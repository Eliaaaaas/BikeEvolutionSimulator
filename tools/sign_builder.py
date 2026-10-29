"""Canonical SignBuilder for editably baked Roblox signs (no external assets).

GUI canvas MUST use PixelsPerStud sizing: a fixed 800x600 canvas stretched onto a
wide board makes TextScaled captions physically tiny. Draw directly on both solid
matte faces; no invisible carrier pointing into another layer.
"""
import math
import xml.etree.ElementTree as E

class SignBuilder:
    serial = 0
    THEMES = {
        'Garage': ((16, 32, 58), (245, 195, 66)),
        'Training': ((12, 47, 52), (252, 152, 62)),
        'Race': ((57, 22, 31), (246, 201, 78)),
        'Eggs': ((39, 25, 62), (239, 120, 206)),
        'Worlds': ((17, 33, 59), (74, 225, 218)),
        'VIP': ((25, 28, 43), (248, 208, 86)),
        'Shop': ((18, 45, 45), (107, 228, 161)),
        'Island': ((19, 45, 55), (109, 222, 217)),
    }
    def __init__(self, item, part, prop, capsule, beam):
        self.item, self.part, self.prop = item, part, prop
        self.capsule, self.beam = capsule, beam

    @staticmethod
    def kind(title):
        for words, kind in [(('GARAGE','BIKE SHOP'),'Garage'),(('EGG','PET'),'Eggs'),(('RACE','START','ZIEL','FINISH'),'Race'),(('WORLD','PORTAL'),'Worlds'),(('TRAIN',),'Training'),(('VIP',),'VIP'),(('SHOP',),'Shop')]:
            if any(word in title for word in words): return kind
        return 'Island'

    def build(self, parent, title, pos, width, height=4, kind=None):
        kind = kind or self.kind(title)
        dark, accent = self.THEMES[kind]
        model, _ = self.item(parent, 'Model', 'Sign_'+kind)
        SignBuilder.serial += 1
        identity = f'SignV45_{SignBuilder.serial}'
        trim = min(1, height/3)
        self.capsule(model,'MatteBack',width+1.2*trim,height+.9*trim,.64,pos,(11,19,30) if width>=16 else accent)
        for side, face in [(1,2),(-1,5)]: # Roblox Back=+Z, Front=-Z; do not swap them.
            if width>=16:self.capsule(model,'AccentFrame',width+.5*trim,height+.5*trim,.12,(pos[0],pos[1],pos[2]+side*.34),accent)
            # Actual opaque face: the SurfaceGui cannot be hidden behind its own board.
            self.capsule(model,'MatteFaceRound',width,height,.16,(pos[0],pos[1],pos[2]+side*.4),dark)
            plate, props=self.part(model,'TextFace',(max(.2,width-height),height-.08,.04),(pos[0],pos[1],pos[2]+side*.47),dark,collide=False)
            plate.set('referent',identity+('_Front' if side==1 else '_Back'))
            self.prop(props,'float','Reflectance',0)
            gui,gp=self.item(plate,'SurfaceGui','SignCaption')
            self.prop(gp,'Ref','Adornee',plate.attrib['referent'])
            self.prop(gp,'token','Face',face)
            self.prop(gp,'token','SizingMode',1) # PixelsPerStud, not default FixedSize.
            self.prop(gp,'float','PixelsPerStud',96)
            self.prop(gp,'float','LightInfluence',0)
            self.prop(gp,'float','Brightness',1)
            self.prop(gp,'bool','AlwaysOnTop',False)
            self.prop(gp,'float','MaxDistance',180)
            self.prop(gp,'float','ZOffset',.01)
            label,lp=self.item(gui,'TextLabel','Caption')
            for k,v in [('Text',title)]:self.prop(lp,'string',k,v)
            for k,v in [('TextScaled',True),('TextWrapped',False),('ClipsDescendants',False),('RichText',False)]:self.prop(lp,'bool',k,v)
            for k,v in [('BackgroundTransparency',1),('TextStrokeTransparency',.45)]:self.prop(lp,'float',k,v)
            self.prop(lp,'int','ZIndex',2);self.prop(lp,'token','Font',20)
            for name,color in [('TextColor3',(1,1,1)),('TextStrokeColor3',(.02,.035,.055))]:
                c=E.SubElement(lp,'Color3',name=name)
                for axis,value in zip('RGB',color):E.SubElement(c,axis).text=str(value)
            has_icon = width >= 16
            for name,values in [('Size',(.72 if has_icon else .94,0,.86,0)),('Position',(.25 if has_icon else .03,0,.07,0))]:
                u=E.SubElement(lp,'UDim2',name=name)
                for axis,value in zip(('XS','XO','YS','YO'),values):E.SubElement(u,axis).text=str(value)
            # Only thin edge inlays emit light. Text/face/frame/icons remain matte.
            for vertical in ([1] if has_icon else []):
                self.part(model,'EdgeInlay',(max(.1,width-height),.035,.035),(pos[0],pos[1]+vertical*(height/2+.14*trim),pos[2]+side*.4),accent,288,False)
            if has_icon:self.icon(model,kind,(pos[0]-side*width*.38,pos[1],pos[2]+side*.63),min(height*.35,width*.075),accent,side)
        return model

    def icon(self,parent,kind,pos,r,color,side):
        x,y,z=pos
        # Icon is physically backed by a medallion touching the face, not floating neon fragments.
        self.part(parent,'IconBacking',(r*2.15,r*2.15,.18),(x,y,z-side*.08),(27,43,61),256,False,shape=0)
        def line(name,a,b,w=.13):
            self.beam(parent,name,(x+a[0]*r,y+a[1]*r,z),(x+b[0]*r,y+b[1]*r,z),w*r,color,256)
        def ring(name,cx,cy,radius):
            for n in range(10):
                a=n*math.tau/10;b=(n+1)*math.tau/10
                line(name,(cx+math.sin(a)*radius,cy+math.cos(a)*radius),(cx+math.sin(b)*radius,cy+math.cos(b)*radius),.095)
        if kind=='Garage':
            ring('BikeWheel',-.56,-.3,.4);ring('BikeWheel',.56,-.3,.4)
            for a,b in [((-.56,-.3),(-.12,.42)),((-.12,.42),(.56,-.3)),((-.56,-.3),(.25,-.3)),((.25,-.3),(-.12,.42)),((-.18,.45),(.12,.45)),((.56,-.3),(.39,.57)),((.39,.57),(.7,.57))]:line('BikeFrame',a,b,.1)
        elif kind=='Training' or kind=='Island':
            for a,b in [((.25,.86),(-.35,.05)),((-.35,.05),(.35,.05)),((.35,.05),(-.25,-.86))]:line('EnergyBolt',a,b,.21)
        elif kind=='Eggs':
            self.part(parent,'EggIcon',(r*1.05,r*1.55,.23),(x,y,z),color,256,False,shape=0)
            for dx in [-.22,.22]:self.part(parent,'EggInlay',(r*.16,r*.16,.05),(x+dx*r,y,z+side*.14),(255,230,247),256,False,shape=0)
        elif kind=='Race':
            line('FlagPole',(-.8,-.9),(-.8,.85),.12)
            for col in range(4):
                for row in range(3):
                    self.part(parent,'CheckeredFlag',(r*.36,r*.36,.16),(x+(-.53+col*.36)*r,y+(.1+row*.36)*r,z),(246,245,230) if (col+row)%2==0 else (36,43,56),256,False)
        elif kind=='Worlds':
            ring('PortalIcon',0,0,.8);ring('PortalIcon',0,0,.55)
        elif kind=='VIP':
            for a,b in [((-.75,-.5),(.75,-.5)),((-.75,-.5),(-.85,.5)),((-.85,.5),(-.3,.05)),((-.3,.05),(0,.85)),((0,.85),(.3,.05)),((.3,.05),(.85,.5)),((.85,.5),(.75,-.5))]:line('Crown',a,b,.16)
        else:
            ring('CoinRim',0,0,.8);line('CoinStamp',(0,-.5),(0,.5),.18)
