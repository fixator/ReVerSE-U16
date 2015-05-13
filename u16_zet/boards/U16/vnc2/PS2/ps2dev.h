/*
 * 2015.05.09 Based ON: 
 * ps2dev.h - a library to interface with ps2 hosts. See comments in
 * ps2.cpp.
 * Written by Chris J. Kiick, January 2008.
 * modified by Gene E. Scogin, August 2008.
 * Release into public domain.
 */

#ifndef ps2dev_h
#define ps2dev_h

#include "hidtypes.h"

#define _led     2 //pin #2
#define _ps2clk  4 //pin #4
#define _ps2data 5 //pin #5

void PS2dev_init(void);
char PS2dev_host_req(void);
int  PS2dev_write(unsigned char data);
int  PS2dev_read (unsigned char * data);

void LED_ON (void);
void LED_OFF(void);


#endif 
/* ps2dev_h */

