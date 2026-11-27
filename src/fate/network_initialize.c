extern unsigned char transport, net_settings;
extern long network_id_byte, serial_transport, serial_baud;
extern short connecthead, connectpoint2[], numplayers;
extern long connectnum[];
extern const char ipx_missing_error[], ipx_socket_error[];
extern void initcrc(void), initialize_serial_network(void);
#pragma aux initcrc modify exact [eax];
#pragma aux initialize_serial_network modify exact [eax];
extern int initialize_ipx(void);
#pragma aux initialize_ipx modify exact [eax];
extern int printf(const char *, ...);
#pragma aux printf parm caller [] modify exact [eax];
extern void exit(int);
#pragma aux exit modify exact [eax];

/* Register hints for Watcom. These declarations emit no instructions. */
extern int hold_int(int);
#pragma aux hold_int = parm [eax] value [eax] modify exact [];

extern int hold_counter(int);
#pragma aux hold_counter = parm [edx] value [edx] modify exact [];
extern void reserve_loop_eax(void);
#pragma aux reserve_loop_eax = modify exact [eax];

void initialize_network(unsigned char driver, unsigned char settings, unsigned char id)
{
    int index;
    int mode;
    int inactive_head;

    net_settings = settings;
    connecthead = (inactive_head = hold_counter(0), transport = driver, inactive_head);

    /* Clear all 16 peer records from the final slot back to the first. */
    index = hold_counter(15);
    goto check_peer;
    do {
        reserve_loop_eax();
        --index;
        connectpoint2[index + 1] = -1;
        connectnum[index + 1] = 0x7fffffff;
    check_peer:
        ;
    } while (index >= 0);

    network_id_byte = (unsigned char)id;
    initcrc();
    mode = hold_int(transport);
    if (mode >= 1 && mode <= 4) {
        serial_transport = mode;
        switch ((unsigned char)settings & 15) {
        case 0: serial_baud = 2400; break;
        case 1: serial_baud = 4800; break;
        case 2: serial_baud = 9600; break;
        case 3: serial_baud = 14400; break;
        case 4: serial_baud = 19200; break;
        case 5: serial_baud = 28800; break;
        }
        initialize_serial_network();
    }
    if (hold_int(transport) >= 5) {
        int status = initialize_ipx();
        if (status) {
            if (status == -1)
                printf(ipx_missing_error);
            if (status == -2)
                printf(ipx_socket_error);
            exit(0);
        }
    }
    numplayers = 1;
}
