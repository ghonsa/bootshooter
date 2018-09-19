#include <stdio.h>
#include <i86.h>
#include "GMouse.h"

int main()  
{
	GMouse * mousy = new GMouse();
	if(mousy==0)
	{
		printf("GMouse create failed\n");
		return -1;
	}
	if(mousy->Init()!=0)
	{
		printf("GMouse init failed\n");
		return -1;
	}
	mousy->Enable();
	while(getchar() !='x');
	mousy->Disable();
	return 0;
}