extern unsigned char transport;
extern long network_id_byte, myconnectnum;
extern const char ipx_local_address[];
extern void send_packet(int, char *, int);
#pragma aux send_packet modify exact [eax edx ebx];
/* Read the low counter byte. Watcom reloads DX for each timer sample. */
extern unsigned port_in(unsigned);
#pragma aux port_in = "in al, dx" parm [edx] value [eax] modify exact [eax edx];
void send_network_join_request(void)
{
    char packet[16];
    int index;
    int mode;

    if (transport <= 0)
        return;

    mode = transport;
    packet[0] = 0xfd;
    if (mode < 5) {
        /* The serial join packet derives the low three ID bytes from the PIT. */
        packet[1] = port_in(0x40);
        packet[2] = port_in(0x40);
        packet[3] = port_in(0x40);
        packet[4] = network_id_byte;
        myconnectnum = (unsigned char)packet[1] + ((unsigned char)packet[2] << 8) +
                       ((unsigned char)packet[3] << 16) + ((unsigned long)network_id_byte << 24);
        send_packet(-1, packet, 5);
        return;
    } else {
        packet[1] = myconnectnum;
        packet[2] = (myconnectnum >> 8) & 0xff;
        packet[3] = (myconnectnum >> 16) & 0xff;
        packet[4] = (myconnectnum >> 24) & 0xff;

        /* The IPX join packet also carries the local address. */
        index = 0;
        goto test;
        do {
            ++index;
            packet[index + 4] = ipx_local_address[index - 1];
        test:
            ;
        } while (index < 10);

    }
    send_packet(-1, packet, 15);
}
