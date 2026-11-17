extern short ready_player_count, myconnectindex, connecthead, connectpoint2[];
extern unsigned char transport;
extern void send_ready_packet(short player, unsigned char *buffer, int size);
#pragma aux send_ready_packet modify exact [eax edx ebx];
void broadcast_network_ready(void)
{
    unsigned char packet[16];
    if ((long)ready_player_count > 1 && transport > 0) {
        int type = transport;
        packet[0] = 255;
        if (type < 5) {
            send_ready_packet(-1, packet, 1);
        } else {
            int player;
            packet[1] = (unsigned char)myconnectindex;
            for (player = connecthead; player >= 0; player = connectpoint2[player])
                if ((long)player != (long)myconnectindex)
                    send_ready_packet(player, packet, 2);
        }
    }
}
