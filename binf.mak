
TARGET = Bootsh.com


all: $(TARGET)
OBJS = Binf.obj \
		  DispUtl.obj \
		  vgutl.obj \
		  vcontex.obj \
		  DrvInf.obj \
		  Zapper.obj \
		  utils.obj \
		  Partiton.obj \
		  PartUtl.obj \
		  WriteS.obj \
		  VerfS.obj \
		  ReadS.obj \
		  diskbuff.obj

Binf.obj: Binf.asm pte.inc DispUtl.inc ; ml /c  /Fl Binf.asm
  
DispUtl.obj: DispUtl.asm pte.inc DispUtl.inc ; ml /c /Fl DispUtl.asm

vgutl.obj: vgutl.asm vcontex.inc vgutl.inc ; ml /c /Fl vgutl.asm

vcontex.obj: vcontex.asm vcontex.inc vgutl.inc ; ml /c /Fl vcontex.asm
   
DrvInf.obj: DrvInf.asm pte.inc DispUtl.inc ; ml /c /Fl DrvInf.asm

Zapper.obj: Zapper.asm pte.inc diskbuff.inc ; ml /c /Fl Zapper.asm

utils.obj: utils.asm pte.inc diskbuff.inc ; ml /c /Fl utils.asm

Partiton.obj: Partiton.asm pte.inc diskbuff.inc PartUtl.inc ; ml /c /Fl Partiton.asm

PartUtl.obj: PartUtl.asm pte.inc diskbuff.inc ; ml /c /Fl PartUtl.asm

WriteS.obj: WriteS.asm pte.inc ; ml /c /Fl WriteS.asm

verfS.obj: verfS.asm pte.inc ; ml /c /Fl verfS.asm

ReadS.obj: ReadS.asm pte.inc ; ml /c /Fl ReadS.asm

diskbuff.obj: diskbuff.asm pte.inc ; ml /c /Fl diskbuff.asm
       

$(TARGET):$(OBJS)
        link /TINY /MAP binf disputl vgutl\
        vcontex drvinf Zapper utils\
        Partiton PartUtl Writes verfs\
        ReadS diskbuff,bootsh,bootsh,,,


   