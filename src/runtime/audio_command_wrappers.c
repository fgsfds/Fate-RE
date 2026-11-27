/* HMI driver command wrappers that call the mapped driver far entry. */
void driver_command_5(void);
#pragma aux driver_command_5 aborts;
void driver_command_0(void);
#pragma aux driver_command_0 aborts;
void read_driver_parameters(void);
#pragma aux read_driver_parameters aborts;
void driver_command_3(void);
#pragma aux driver_command_3 aborts;
void driver_secondary_command_1(void);
#pragma aux driver_secondary_command_1 aborts;
void driver_secondary_command_2(void);
#pragma aux driver_secondary_command_2 aborts;
void driver_secondary_command_3(void);
#pragma aux driver_secondary_command_3 aborts;
void driver_secondary_command_4(void);
#pragma aux driver_secondary_command_4 aborts;
void driver_configure_secondary(void);
#pragma aux driver_configure_secondary aborts;

extern void save_registers(void);
#pragma aux save_registers = "push ebp" "db 8bh, 0ech" "push esi" "push edi" "push ebx" \
    "push ecx" "push fs" "push gs" "push es" modify exact [eax ebx ecx edx esi edi];

extern void restore_registers(void);
#pragma aux restore_registers = "pop es" "pop gs" "pop fs" "pop ecx" "pop ebx" \
    "pop edi" "pop esi" "pop ebp" "ret" modify exact [];

/* The driver record is a stack far pointer; its entry is the first argument. */
extern void call_driver(void);
#pragma aux call_driver = "call far [ebp+8]" modify exact [];

extern void lfs_edi_10(void);
#pragma aux lfs_edi_10 = "lfs edi,[ebp+10h]" modify exact [edi];

extern void lfs_edi_1c(void);
#pragma aux lfs_edi_1c = "lfs edi,[ebp+1ch]" modify exact [edi];

extern void command_three(unsigned long);
#pragma aux command_three = "" parm [eax] modify exact [];

extern void cmd0(void);
#pragma aux cmd0 = "mov eax,0" modify exact [eax];
extern void cmd1(unsigned long);
#pragma aux cmd1 = "" parm [eax] modify exact [];
extern void cmd2(void);
#pragma aux cmd2 = "mov eax,2" modify exact [eax];
extern void cmd3(void);
#pragma aux cmd3 = "mov eax,3" modify exact [eax];
extern void cmd4(void);
#pragma aux cmd4 = "mov eax,4" modify exact [eax];
extern void cmd5(unsigned long);
#pragma aux cmd5 = "" parm [eax] modify exact [];

extern unsigned char current_al(void);
#pragma aux current_al = "" value [al] modify exact [];
extern unsigned char current_dl(void);
#pragma aux current_dl = "" value [dl] modify exact [];
extern unsigned char current_ch(void);
#pragma aux current_ch = "" value [ch] modify exact [];
extern unsigned char current_cl(void);
#pragma aux current_cl = "" value [cl] modify exact [];

extern void ld_ebx_10(void);
#pragma aux ld_ebx_10 = "mov ebx,[ebp+10h]" modify exact [ebx];
extern void ld_eax_14(void);
#pragma aux ld_eax_14 = "mov eax,[ebp+14h]" modify exact [eax];
extern void ch_al(unsigned char);
#pragma aux ch_al = "db 8ah, 0e8h" parm [al] modify exact [ecx];
extern void ld_eax_18(void);
#pragma aux ld_eax_18 = "mov eax,[ebp+18h]" modify exact [eax];
extern void cl_al(unsigned char);
#pragma aux cl_al = "db 8ah, 0c8h" parm [al] modify exact [ecx];
extern void ld_ebx_18(void);
#pragma aux ld_ebx_18 = "mov ebx,[ebp+18h]" modify exact [ebx];
extern void ld_ecx_1c(void);
#pragma aux ld_ecx_1c = "mov ecx,[ebp+1ch]" modify exact [ecx];
extern void ld_edi_18(void);
#pragma aux ld_edi_18 = "mov edi,[ebp+18h]" modify exact [edi];
extern void bx_8(void);
#pragma aux bx_8 = "mov bx,8" modify exact [ebx];
extern void ld_bx_18(void);
#pragma aux ld_bx_18 = "mov bx,word ptr [ebp+18h]" modify exact [ebx];
extern void ld_cx_1c(void);
#pragma aux ld_cx_1c = "mov cx,word ptr [ebp+1ch]" modify exact [ecx];
extern void ld_dx_20(void);
#pragma aux ld_dx_20 = "mov dx,word ptr [ebp+20h]" modify exact [edx];
extern void ch_dl(unsigned char);
#pragma aux ch_dl = "db 8ah, 0eah" parm [dl] modify exact [ecx];
extern void ld_si_2c(void);
#pragma aux ld_si_2c = "mov si,word ptr [ebp+2ch]" modify exact [esi];

extern unsigned short detector_parameter_ax;
extern unsigned short detector_parameter_ch;
extern unsigned short detector_parameter_cl;
extern unsigned short detector_parameter_dx;

extern void store_ax(void);
#pragma aux store_ax = "mov word ptr detector_parameter_ax, ax" modify exact [];
extern void al_ch(unsigned char);
#pragma aux al_ch = "db 8ah, 0c5h" parm [ch] modify exact [eax];
extern void cbw_(void);
#pragma aux cbw_ = "cbw" modify exact [eax];
extern void store_ch(void);
#pragma aux store_ch = "mov word ptr detector_parameter_ch, ax" modify exact [];
extern void al_cl(unsigned char);
#pragma aux al_cl = "db 8ah, 0c1h" parm [cl] modify exact [eax];
extern void store_cl(void);
#pragma aux store_cl = "mov word ptr detector_parameter_cl, ax" modify exact [];
extern void store_dx(void);
#pragma aux store_dx = "mov word ptr detector_parameter_dx, dx" modify exact [];

void driver_command_5(void)
{
    save_registers();
    cmd5(5);
    lfs_edi_10();
    call_driver();
    restore_registers();
}

void driver_command_0(void)
{
    save_registers();
    cmd0();
    lfs_edi_10();
    call_driver();
    restore_registers();
}

void read_driver_parameters(void)
{
    save_registers();
    cmd1(1);
    lfs_edi_10();
    call_driver();
    store_ax();
    al_ch(current_ch());
    cbw_();
    store_ch();
    al_cl(current_cl());
    cbw_();
    store_cl();
    store_dx();
    restore_registers();
}

void driver_command_3(void)
{
    save_registers();
    ld_ebx_10();
    ld_eax_14();
    ch_al(current_al());
    ld_eax_18();
    cl_al(current_al());
    command_three(3);
    lfs_edi_1c();
    call_driver();
    restore_registers();
}

void driver_secondary_command_1(void)
{
    save_registers();
    cmd1(1);
    lfs_edi_10();
    call_driver();
    restore_registers();
}

void driver_configure_secondary(void)
{
    save_registers();
    lfs_edi_10();
    cmd0();
    ld_bx_18();
    ld_cx_1c();
    ld_dx_20();
    ch_dl(current_dl());
    ld_si_2c();
    call_driver();
    restore_registers();
}

void driver_secondary_command_4(void)
{
    save_registers();
    lfs_edi_10();
    cmd4();
    ld_ecx_1c();
    ld_edi_18();
    call_driver();
    restore_registers();
}

void driver_secondary_command_2(void)
{
    save_registers();
    lfs_edi_10();
    cmd2();
    ld_ebx_18();
    call_driver();
    restore_registers();
}

void driver_secondary_command_3(void)
{
    save_registers();
    lfs_edi_10();
    cmd3();
    bx_8();
    call_driver();
    restore_registers();
}
