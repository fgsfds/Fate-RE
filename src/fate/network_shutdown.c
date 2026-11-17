/* Stop serial play or close the IPX socket for the active transport. */
extern unsigned char transport;
extern short numplayers;

extern short socket;
extern void shutdown_serial_network(void);
#pragma aux shutdown_serial_network modify exact [eax];
/* DOS IPX close uses AH=0, BX=1, and the socket in DX. */
extern void close_ipx_socket(void);
#pragma aux close_ipx_socket = \
    "push ebx" \
    "push ecx" \
    "push edx" \
    "mov ebx,1" \
    "movsx edx,word ptr socket" \
    "xor ecx,ecx" \
    "xor eax,eax" \
    "int 7ah" \
    "pop edx" \
    "pop ecx" \
    "pop ebx" \
    modify exact [eax];

void uninitmultiplayers(void)
{
    if (numplayers <= 0)
        return;
    if ((int)transport >= 1 && (int)transport <= 4)
        shutdown_serial_network();
    if ((int)transport >= 5)
        close_ipx_socket();
}
