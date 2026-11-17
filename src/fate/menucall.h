#ifndef FATE_MENU_CALL_H
#define FATE_MENU_CALL_H

#include "menurec.h"

extern int run_menu_loop(unsigned *, int, short, const char *, MenuRecord **);
#pragma aux run_menu_loop parm routine [eax] [edx] [ebx] [ecx] modify exact [eax edx ebx ecx];

/* Watcom register annotations preserve the original leaf call setup. */
extern short keep_menu_tile(int);
#pragma aux keep_menu_tile = "" parm [ebx] value [bx] modify exact [];
extern int keep_menu_running(int);
#pragma aux keep_menu_running = "" parm [edx] value [edx] modify exact [];

/* Keep the other register arguments established before sign-extending BX. */
extern short keep_menu_tile_after_arguments(short, unsigned *, int, const char *);
#pragma aux keep_menu_tile_after_arguments = "" parm [bx] [eax] [edx] [ecx] value [bx] modify exact [];

#endif
