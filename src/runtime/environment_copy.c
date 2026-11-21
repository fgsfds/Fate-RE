/* Copy the DOS environment strings into the Watcom environment vector.
 * The assembly entry establishes the original saved segment registers.
 */
extern char **environment_vector;
extern char *environment_flags;
extern long dos_environment_offset;
extern long malloc(long);
#pragma aux malloc parm [eax] modify exact [eax];
extern void free(long);
#pragma aux free parm [eax] modify exact [eax];
extern void memset(long,long,long);
#pragma aux memset parm [eax] [edx] [ebx] modify exact [eax];

extern void restore_registers(void);
#pragma aux restore_registers = "pop fs" "pop es" "pop edi" "pop esi" "pop edx" "pop ecx" "pop ebx" "ret" aborts modify exact [];
extern long saved_environment_selector(void);
#pragma aux saved_environment_selector = "db 8ch,0e0h" value [eax] modify exact [eax];
extern void select_environment_segment(long);
#pragma aux select_environment_segment = "mov es,ax" parm [eax] modify exact [];
extern void stop_environment_scan(void);
#pragma aux stop_environment_scan = "cmp dl,byte ptr es:[eax]" "db 74h,13h" modify exact [];
extern unsigned char read_scan_byte(void);
#pragma aux read_scan_byte = "mov dh,byte ptr es:[eax]" value [dh] modify exact [dh];
extern void stop_environment_copy(void);
#pragma aux stop_environment_copy = "cmp byte ptr es:[eax],0" "db 74h,1ah" modify exact [];
extern unsigned char read_environment_byte(void);
#pragma aux read_environment_byte = "mov dl,byte ptr es:[eax]" value [dl] modify exact [dl];

extern long put_eax(long);
#pragma aux put_eax = "" parm [eax] value [eax] modify exact [];
extern long get_eax(void);
#pragma aux get_eax = "" value [eax] modify exact [];
extern long put_ebx(long);
#pragma aux put_ebx = "" parm [ebx] value [ebx] modify exact [];
extern long get_ebx(void);
#pragma aux get_ebx = "" value [ebx] modify exact [];
extern long put_ecx(long);
#pragma aux put_ecx = "" parm [ecx] value [ecx] modify exact [];
extern long get_ecx(void);
#pragma aux get_ecx = "" value [ecx] modify exact [];
extern long put_edx(long);
#pragma aux put_edx = "" parm [edx] value [edx] modify exact [];
extern long get_edx(void);
#pragma aux get_edx = "" value [edx] modify exact [];
extern long put_esi(long);
#pragma aux put_esi = "" parm [esi] value [esi] modify exact [];
extern long get_esi(void);
#pragma aux get_esi = "" value [esi] modify exact [];
extern long put_edi(long);
#pragma aux put_edi = "" parm [edi] value [edi] modify exact [];
extern long get_edi(void);
#pragma aux get_edi = "" value [edi] modify exact [];
extern unsigned char put_dl(unsigned char);
#pragma aux put_dl = "" parm [dl] value [dl] modify exact [];
extern unsigned char get_dl(void);
#pragma aux get_dl = "" value [dl] modify exact [];
extern unsigned char get_dh(void);
#pragma aux get_dh = "" value [dh] modify exact [];

extern void env_restore_registers(void);
extern void select_allocation_size(void);
#pragma aux select_allocation_size = "sub eax,edi" "db 75h, 05h" /* marker-rel8 0,+1 */ modify exact [eax];
extern void leave_if_strings_allocation_failed(void);
#pragma aux leave_if_strings_allocation_failed = "test eax,eax" "je near env_restore_registers" modify exact [];
extern void release_strings_if_vector_failed(void);
#pragma aux release_strings_if_vector_failed = "test eax,eax" "db 74h,54h" modify exact [];
extern void reset_environment_copy_state(void);
#pragma aux reset_environment_copy_state = "xor esi,esi" "db 8ch,0e0h" "xor ecx,ecx" modify exact [eax ecx esi];
extern void terminate_env_vector(void);
#pragma aux terminate_env_vector = "db 0c7h,04h,11h,00h,00h,00h,00h" modify exact [];
extern void keep_flags_base_out_of_eax(void);
#pragma aux keep_flags_base_out_of_eax = "" modify exact [eax];
extern void leave_without_freeing(void);
#pragma aux leave_without_freeing = "db 0ebh,07h" aborts modify exact [];
extern void continue_environment(void);
#pragma aux continue_environment = "" aborts modify exact [];
void env_scan_strings(void);
#pragma aux env_scan_strings aborts modify exact [eax ebx ecx edx esi edi];
void env_scan_strings(void)
{
    put_ecx(0);
    put_dl(0);
    saved_environment_selector();
    put_edi(dos_environment_offset);
    select_environment_segment(get_eax());
    put_eax(get_edi());
check_string:
    stop_environment_scan();
scan_byte:
    read_scan_byte();
    put_ebx(get_eax() + 1);
    if (get_dl() == get_dh())
        goto count_string;
    put_eax(get_ebx());
    goto scan_byte;
count_string:
    put_ecx(get_ecx() + 1);
    put_eax(get_ebx());
    goto check_string;
}

void env_allocate_and_copy(void);
#pragma aux env_allocate_and_copy aborts modify exact [eax ebx ecx edx esi edi];
void env_allocate_and_copy(void)
{
    select_allocation_size();
    put_eax(1);
    malloc(get_eax());
    put_edx(get_eax());
    put_ebx(get_eax());
    leave_if_strings_allocation_failed();
    put_eax(get_ecx());
    put_eax(get_eax() << 2);
    put_eax(get_eax() + 4);
    malloc(put_eax(get_eax() + get_ecx()));
    release_strings_if_vector_failed();
    environment_vector = (char **)get_eax();
    reset_environment_copy_state();
    select_environment_segment(get_eax());
    put_eax(get_edi());
check_copy:
    stop_environment_copy();
    put_edx((long)environment_vector);
    *(char **)(get_ecx() + get_edx()) = (char *)get_ebx();
copy_byte:
    read_environment_byte();
    put_eax(get_eax() + 1);
    *(char *)get_ebx() = get_dl();
    put_ebx(get_ebx() + 1);
    if (get_dl())
        goto copy_byte;
    put_ecx(get_ecx() + 4);
    put_esi(get_esi() + 1);
    goto check_copy;
}

void env_finish_vector(void);
#pragma aux env_finish_vector aborts modify exact [eax ebx ecx edx esi edi];
void env_finish_vector(void)
{
    put_edx((long)environment_vector);
    terminate_env_vector();
    put_ecx(get_ecx() + 4);
    put_edx(get_edx() + get_ecx());
    put_ebx(get_esi());
    environment_flags = (char *)get_edx();
    keep_flags_base_out_of_eax();
    put_eax(get_edx());
    put_edx(0);
    memset(get_eax(),get_edx(),get_ebx());
    leave_without_freeing();
}

void env_free_strings(void);
#pragma aux env_free_strings aborts modify exact [eax];
void env_free_strings(void)
{
    free(put_eax(get_edx()));
    continue_environment();
}

void env_restore_registers(void);
#pragma aux env_restore_registers aborts modify exact [];
void env_restore_registers(void)
{
    restore_registers();
}
