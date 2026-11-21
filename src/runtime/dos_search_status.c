extern int set_dos_errno(int);
#pragma aux set_dos_errno modify exact [eax];
/* This internal entry receives carry from DOS and EAX from its caller. */
extern unsigned read_dos_status(unsigned);
#pragma aux read_dos_status = "db 73h, 0eh" /* marker-rel8 +3 */ parm [eax] value [eax] modify exact [];
extern unsigned preserve_dos_error(unsigned);
#pragma aux preserve_dos_error = "push eax" parm [eax] value [eax] modify exact [];
extern unsigned restore_dos_error(void);
#pragma aux restore_dos_error = "pop eax" value [eax] modify exact [eax];
extern unsigned select_dos_result(unsigned);
#pragma aux select_dos_result = "db 0ebh, 02h" /* marker-rel8 0,+1 */ "sub eax,eax" parm [eax] value [eax] modify exact [eax];
extern unsigned dos_search_status(unsigned);
#pragma aux dos_search_status modify exact [eax];

unsigned dos_search_status(unsigned status)
{
    set_dos_errno(preserve_dos_error(read_dos_status(status) & 0xffff));
    return select_dos_result(restore_dos_error());
}
