#include "DriveInfo.h"
#include <i86.h>
#include <stdlib.h>
#include "diskio.h"

void txtout(char * txt)
{
	//return;
	union REGS reg;
	struct SREGS sreg;
	char chr;
	while((chr=*txt++)!=0)
	{
		if(chr==0x0a)
		{
			reg.h.ah = 0x0e;
			reg.h.al=0x0d;
			int86x(0x10, &reg, &reg, &sreg);
		}
		reg.h.ah = 0x0e;
		reg.h.al=chr;
		reg.x.bx=15;
		int86x(0x10, &reg, &reg, &sreg);
	}
}
void hexout (uint16 val)
{
	//return;
	union REGS reg;
	struct SREGS sreg;
	int x;
	char tmp;
	for(x=0 ;x<4 ;x++)
	{
		tmp = (char) (val>>12 & 0xf);
		if(tmp>9)
		{
			tmp=(tmp-9)+0x40;
		}
		else
		{
			tmp = tmp +0x30;
		}
		reg.x.bx=15;
		reg.h.ah = 0x0e;
		reg.h.al=tmp;
		int86x(0x10, &reg, &reg, &sreg);
		val = val <<4;
	}
}

void waitk()
{
   //	return;
	_asm
	{
		mov	ax,0
		int	16h
	}
}
DriveInfo::DriveInfo()
{
	sectptr = 0;
;
}
DriveInfo::~DriveInfo()
{
;
}
static uint8 DriveInfo::GetNumDrives()
{
	uint8 drives=0;
	// bios int 13 function 08
	union REGS reg;
	struct SREGS sreg;
	reg.x.ax = 0x0800;
	reg.x.dx = 0x80;
	int86x(0x13, &reg, &reg, &sreg);
	if(reg.x.cflag==0)
		drives=reg.h.dl;
	return drives;
}

void DriveInfo::CollectInfo(uint8 drvid)
{
	union REGS reg;
	struct SREGS sreg;
	uint16 ts;
	
	txtout("\n\nDriveInfo collect:");
	hexout((uint16)drvid);
	
	_asm
 	{
 		mov	ax,ds
 		mov	ts,ax
 	};
	segs=ts;
	DIid=drvid;	 // save our ID
	DIBiosExt=false;
   	//
	// --- check if this drive has extended support ---
	//
	reg.x.ax = 0x4100;
	reg.x.bx=0x55aa;
	reg.h.dl = DIid;
	int86x(0x13, &reg, &reg, &sreg);
	
	if(reg.x.cflag==0)
	{
		txtout(" Drv is Extended?");
	//
	// -- drive has bios extensuions --- 
	//
		if(reg.x.bx==0xaa55)
		{
			ExtBiosDrvTab ebdt;
			union REGS reg1	;
			struct SREGS sreg1	;
			void * tmptr = &ebdt;
			DIBiosExt=true;
		//
		//   --- get extended bios table ---
		//
			txtout(" Getting drvinf ");

			ebdt.EBDTBuffSz=26;
			reg1.x.si=(unsigned short) FP_OFF(&ebdt);
			sreg1.ds=FP_SEG(&ebdt);
			reg1.h.dl = DIid;
			reg1.x.ax = 0x4800;
			int86x(0x13, &reg1, &reg1, &sreg1);
			
			if(reg1.x.cflag==0)
			{
				DIExtSize1= ebdt.EBDTTotSect1;
	  			DIExtSize = ebdt.EBDTTotSect;
				DITotSect = ebdt.EBDTTotSect;
				DIFreeSect =ebdt.EBDTTotSect; 
				txtout(" Size:");
				hexout((uint16)(DIExtSize>>16));
				hexout((uint16)(DIExtSize));
			}
		}
	}
   	//
	//  -- get standard bios info ---
	//
   //	reg.x.ax = 0x0800;
   //	reg.h.dh=0;
   //	reg.h.dl = DIid;
   //	sreg.es=segs;
   //	sreg.ds=segs;
   //	int86x(0x13, &reg, &reg, &sreg);
  ///	if(reg.x.cflag==0)
  //	{
  //		DIHeads=reg.h.dh;
 //		DISectors= (reg.h.cl & 0x3f);
 //		DICylinders = (reg.x.cx	 >>6);
 //	}
	if(sectptr == 0)
	{
		sectptr = new MBR();
	}
	if(sectptr == 0)
	{
		txtout("Malloc failure");
		waitk();
		return;
	}
   	
   	
   	GetPartitionTables();
//	waitk();

}

void  DriveInfo::GetPartitionTables()
{
	union REGS reg;
	struct SREGS sreg;
	//
	//   --- read partition table from mbr ---
	//
	txtout("\n{GetPartitions -> ");
	partdepth=0;

	// read mbr 
	reg.x.ax=0x201;
	reg.x.bx= (uint16)sectptr;
	sreg.es = segs;
	reg.h.dh = 0;
	reg.h.dl = DIid;
	reg.x.cx = 1;
	int86x(0x13, &reg, &reg, &sreg);
	if(reg.x.cflag==0)
	{
		int x;
		PARTITION_TABLE_ENTRY tmp_pte[4];

		for(x=0;x<4;x++)
		{
		 	//make a copy of the partition tables, we re-use the sector buffer
									    
 			tmp_pte[x].bte_bootable = sectptr->pte[x].bte_bootable;
 			tmp_pte[x].bte_starthead = sectptr->pte[x].bte_starthead;
 		    tmp_pte[x].bte_startsector = sectptr->pte[x].bte_startsector;
 			tmp_pte[x].bte_system = sectptr->pte[x].bte_system;
 			tmp_pte[x].bte_endhead = sectptr->pte[x].bte_endhead;
			tmp_pte[x].bte_endsector = sectptr->pte[x].bte_endsector;
			tmp_pte[x].bte_relativesector = sectptr->pte[x].bte_relativesector;
			tmp_pte[x].bte_totalsector = sectptr->pte[x].bte_totalsector;
			

		}
		//
		// --- copy partition table entries into our class data
		//

		
		for(x=0;x<4;x++)
		{
			txtout("  numsec:");
			hexout((uint16)(tmp_pte[x].bte_totalsector >> 16));		   
			hexout((uint16)tmp_pte[x].bte_totalsector);		   
			
			
			
			if(tmp_pte[x].bte_totalsector !=0)
			{
				PARTITION_INFO * tpi = (PARTITION_INFO *) new(PARTITION_INFO);
		   		DIPartTab[x] = tpi;
				tpi->PIDrive = DIid;
		   		DIPartTab[x]->PIpte= tmp_pte[x];

		   		// check if bootable
		   		DIPartTab[x]->PIbootable = tmp_pte[x].bte_bootable;
		   		DIPartTab[x]->PIStartLBA = tmp_pte[x].bte_relativesector;
		   		DIPartTab[x]->PIEndLBA = DIPartTab[x]->PIStartLBA+tmp_pte[x].bte_totalsector;
		   
		   		// adjust free space for drive
		   		DIFreeSect -= DIPartTab[x]->PIpte.bte_totalsector;
		 		DIPartTab[x]->PIInExtended=0;
		 		txtout("\n   p");
				hexout((uint16)x);
	   		   
		   		txtout(" -- StartLBA:");
		   		hexout((uint16)(DIPartTab[x]->PIStartLBA>>16));
		   		hexout((uint16)(DIPartTab[x]->PIStartLBA));


		   		txtout("  EndLBA:");
		   		hexout((uint16)(DIPartTab[x]->PIEndLBA>>16));
		   		hexout((uint16)(DIPartTab[x]->PIEndLBA));

				txtout("  numsec:");
				hexout((uint16)(DIPartTab[x]->PIpte.bte_totalsector >> 16));		   
				hexout((uint16)DIPartTab[x]->PIpte.bte_totalsector);		   


		   		if(DIPartTab[x]->PIpte.bte_endsector !=0)
		   		{
 		   			CheckPartition(DIPartTab[x]);
				}
			}
			else
			{
				DIPartTab[x] = 0;	
			}
		}
		for(x=0;x<4;x++)
		{
		   	if(DIPartTab[x])
			{
			   	DIPartTab[x]->PIActive = 1;
				break;
			}   	
		}
	}
	
	//delete sectptr;

}
void  DriveInfo::CheckPartition( PARTITION_INFO * ppi)
{
	txtout(" CheckPartition[");
	partdepth++;
	if(ppi->PIpte.bte_endsector !=0)
	{
		uint16 rslt;
		if(sectptr == 0)
		{
			txtout("Sector bufer failure..");
			waitk();
			return;
		}
		hexout((uint16)sectptr);
	   	if(DIBiosExt)
		{
			txtout("--extread--");	
			rslt = ReadExtended(ppi->PIStartLBA, DIid, MK_FP(segs,sectptr));
			hexout(rslt);
			txtout("..");
		}
		else  // std bios disk read
		{
			txtout("---stdread---");
			rslt = ReadStd( ppi->PIpte.bte_starthead,(uint8)(ppi->PIpte.bte_startsector & 0x3f), 
					(ppi->PIpte.bte_startsector >>6), DIid, 
					MK_FP(segs,sectptr)); 
		}
		if(rslt==0)	  // a good read ...
		{
			// check if valid partition  
			if( (sectptr->ptsig != 0x0AA55) || (partdepth >1 ))

			{
				txtout(" Non-valid partition ");
			}
			else if( (ppi->PIpte.bte_system == EXTEND) ||(ppi->PIpte.bte_system == BEXTEND))
			{
				int x;
				PARTITION_TABLE_ENTRY tmp_pte[4];
				
				// it is an extended partition 
				txtout("...extended...");
		   		//partoffset = = ppi->PIStartLBA
				
				ppi->PIExtended = PTE_EXTENDED;
		
				for(x=0;x<4;x++)
				{
		 			//make a copy of the partition tables, we re-use the sector buffer
		 			tmp_pte[x].bte_bootable = sectptr->pte[x].bte_bootable;
		 			tmp_pte[x].bte_starthead = sectptr->pte[x].bte_starthead;
		 			tmp_pte[x].bte_startsector = sectptr->pte[x].bte_startsector;
		 			tmp_pte[x].bte_system = sectptr->pte[x].bte_system;
		 			tmp_pte[x].bte_endhead = sectptr->pte[x].bte_endhead;
		 			tmp_pte[x].bte_endsector = sectptr->pte[x].bte_endsector;
		 			tmp_pte[x].bte_relativesector = sectptr->pte[x].bte_relativesector;
		 			tmp_pte[x].bte_totalsector = sectptr->pte[x].bte_totalsector;

				}
		
				for(x=0;x<4;x++)
				{
					if(tmp_pte[x].bte_endsector!=0)
		   			{
		   				PARTITION_INFO * tpi = (PARTITION_INFO *) new(PARTITION_INFO);
		   				ppi->PIEParts[x]=tpi;

		   				tpi->PIpte= tmp_pte[x];
						tpi->PIDrive = DIid;
		   			
		   				// check if bootable
		   				tpi->PIbootable = tmp_pte[x].bte_bootable;
		   				tpi->PIStartLBA = tmp_pte[x].bte_relativesector+ppi->PIStartLBA ;
		   				tpi->PIEndLBA = tpi->PIStartLBA + tmp_pte[x].bte_totalsector;
		 	
						tpi->PIInExtended=1;
						tpi->PIActive=0;
		 				txtout("\n      Rp");
						hexout((uint16)x);
	   		   
		   				txtout(" -- StartLBA:");
		   				hexout((uint16)(tpi->PIStartLBA>>16));
		   				hexout((uint16)(tpi->PIStartLBA));

		   				txtout("  EndLBA:");
		   				hexout((uint16)(tpi->PIEndLBA>>16));
		   				hexout((uint16)(tpi->PIEndLBA));

						txtout("  numsec:");
						hexout((uint16)(tpi->PIpte.bte_totalsector >> 16));		   
						hexout((uint16)tpi->PIpte.bte_totalsector);		   
						
						
						if(tpi->PIpte.bte_totalsector !=0) 						
						{
		   					txtout(" PD");
							hexout((uint16)partdepth);
		   					txtout("\n{{{recurs...");
		   					CheckPartition(tpi);
		   					txtout("}}}}");
						}
					}
					else
					{
		   				ppi->PIEParts[x]=0;
					}
				}
			}
		}
	}
	partdepth--;
	txtout("]...\n");

}
int DriveInfo::DeletePartition(PARTITION_INFO * pis)
{
	// find the entry...
	int	x;
	for(x=0;x<4;x++)
	{
		if(pis == DIPartTab[x])
		{
			DIFreeSect+=DIPartTab[x]->PIpte.bte_totalsector;

			DIPartTab[x]->PIpte.bte_bootable = 0;
			DIPartTab[x]->PIpte.bte_starthead = 0;
			DIPartTab[x]->PIpte.bte_startsector = 0;
			DIPartTab[x]->PIpte.bte_system = 0;
			DIPartTab[x]->PIpte.bte_endhead = 0;
			DIPartTab[x]->PIpte.bte_endsector = 0;
			DIPartTab[x]->PIpte.bte_relativesector = 0;
			DIPartTab[x]->PIpte.bte_totalsector = 0;
   			CommitPTable();
			DIPartTab[x]=0;
			break;
		}
	}		
	return 0;
}
int DriveInfo::CreatePartition(uint32 blocks,uint16 type, int verify)
{
	int rslt =-1;
	PARTITION_INFO* ppti;
	uint32 plba;
	uint32 cyl;
	uint32 tmps;

	if((ppti = PTFindFree()) !=0)	 // look for a free entry
	{
		if(blocks >= DIFreeSect)
		{
			rslt =-2;
		}	
	    else // we have space
		{
			if((plba = getStartLBA(blocks))!=0)	//and room within partitions
			{
				txtout("Create Partition:");
   				hexout((uint16)(plba>>16));
   				hexout((uint16)(plba));
		   	
			   	// update the partition tables...
				ppti->PIStartLBA = plba;
				ppti->PIpte.bte_relativesector = plba;
				ppti->PIpte.bte_totalsector = blocks;
				ppti->PIpte.bte_system = type;

				cyl = plba/(DIHeads * DISectors);
				tmps = (plba%(DIHeads * DISectors));
				ppti->PIpte.bte_starthead = tmps/DISectors;
				ppti->PIpte.bte_startsector = (cyl <<6) + (tmps%DISectors)+1;

				ppti->PIEndLBA = plba+blocks;
				cyl = (plba+blocks)/(DIHeads * DISectors);
				tmps = ((plba+blocks)%(DIHeads * DISectors));
				ppti->PIpte.bte_endhead = tmps/DISectors;
				ppti->PIpte.bte_endsector = (cyl <<6) + (tmps%DISectors)+1;

				// If verify is selected, do a disk verify..
				if(verify)
				{
					if( VerifyPartition(ppti)!=0)
					{

						return 1;
					}
				}		
				//  commit to disk...
				CommitPTable();
			}																	 
		}
	}
	return 0;	
}

int DriveInfo::CommitPTable()
{
	union REGS reg;
	struct SREGS sreg;
				
	reg.x.ax=0x201;
	reg.x.bx= (uint16)sectptr;
	sreg.es = segs;
	reg.h.dh = 0;
	reg.h.dl = DIid;
	reg.x.cx = 1;
	int86x(0x13, &reg, &reg, &sreg);
	if(reg.x.cflag==0)
	{
		int	x;
		for(x=0;x<4;x++)
		{
			// copy the partition tables, we re-use the sector buffer
			if(DIPartTab[x]!=0)
			{
				sectptr->pte[x].bte_bootable = DIPartTab[x]->PIpte.bte_bootable;
				sectptr->pte[x].bte_starthead = DIPartTab[x]->PIpte.bte_starthead ;
				sectptr->pte[x].bte_startsector = DIPartTab[x]->PIpte.bte_startsector;
				sectptr->pte[x].bte_system = DIPartTab[x]->PIpte.bte_system;
				sectptr->pte[x].bte_endhead = DIPartTab[x]->PIpte.bte_endhead;
				sectptr->pte[x].bte_endsector = DIPartTab[x]->PIpte.bte_endsector;
				sectptr->pte[x].bte_relativesector = DIPartTab[x]->PIpte.bte_relativesector;
				sectptr->pte[x].bte_totalsector = DIPartTab[x]->PIpte.bte_totalsector;
			}
		}
		reg.x.ax=0x301;
		reg.x.bx= (uint16)sectptr;
		sreg.es = segs;
		reg.h.dh = 0;
		reg.h.dl = DIid;
		reg.x.cx = 1;
		int86x(0x13, &reg, &reg, &sreg);
	}
	return 0;
}
uint16 DriveInfo::VerifyPartition(PARTITION_INFO* ppti )
{
	uint32 lba = ppti->PIStartLBA;
	while(lba<ppti->PIEndLBA)
	{
		if(VerifyExtended( lba, DIid)!=0)
			return 1;
		lba++;
	}
	return 0;
}

PARTITION_INFO* DriveInfo::PTFindFree()
{
	int idx;
	for(idx=0;idx<4;idx++)
	{
		if(DIPartTab[idx]==0)
		{
			DIPartTab[idx] = (PARTITION_INFO *) new(PARTITION_INFO);
			return (DIPartTab[idx]);
		}
	}
	return 0;
}
uint32 DriveInfo::getStartLBA(uint32 blocks)
{
   	PARTITION_INFO  * PartTab[5];
	PARTITION_INFO  * tmpPart;
 	uint32 plba = 0;
 	int idx;
	int tabidx = 0;
	int sorting = 0;
	// get lst of all used partitions
	for(idx=0;idx<4;idx++)	
	{
		if(DIPartTab[idx]->PIpte.bte_totalsector!=0)
		{
			PartTab[tabidx] =	DIPartTab[idx] ;
			tabidx++;
		}
	}
	PartTab[tabidx]=0;
	// sort list by startLBA
	tabidx = 0;
	do
	{
		if(PartTab[tabidx]==0)
			break; // nothing more to do
		if(PartTab[tabidx+1]==0)
			break;
		if(PartTab[tabidx]->PIStartLBA > PartTab[tabidx+1]->PIStartLBA)
		{
			tmpPart = PartTab[tabidx];
			PartTab[tabidx] = PartTab[tabidx+1];
			PartTab[tabidx+1] = tmpPart;
			sorting = 1;	
		}
		if((tabidx++ >4) && (sorting !=0))
		{
			tabidx=0;
		}
	}
	while(sorting);		
	// now look for space to fit request
	for(idx=0;idx<4;idx++)
	{
		if(blocks < (PartTab[idx]->PIStartLBA-128))
		{
			// we have space below the other partitions
			plba =  128;
			break;
		}
		if(PartTab[idx+1] == 0	)
		{
			if(( DITotSect- PartTab[idx]->PIEndLBA)	> blocks )
				plba = PartTab[idx]->PIEndLBA +1; 
			break;
		}
		if(( (PartTab[idx+1]->PIStartLBA - PartTab[idx]->PIEndLBA)-2) > blocks)
		{
			plba = PartTab[idx]->PIEndLBA+1;
			break;
		}
	}	
   	return plba;
}
