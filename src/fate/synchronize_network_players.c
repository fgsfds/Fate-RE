/* Exchange readiness packets with the lead player. */
extern short sync_player_count, sync_local_player, sync_first_player, sync_next_player[];
extern unsigned char sync_packet[], sync_packet_ready_stage, sync_peer_ready_stage[];
extern volatile long totalclock;

extern void receive_packets(void);
#pragma aux receive_packets parm [] modify exact [eax edx ebx ecx];
extern void send_sync_packet(int, unsigned char *, long);
#pragma aux send_sync_packet "send_packet_" parm [eax] [edx] [ebx] modify exact [eax ebx edx];

/* Empty Watcom bindings preserve the original register assignments. */
extern long in_eax(long);
#pragma aux in_eax = parm [eax] value [eax] modify exact [];
extern long eax_value(void);
#pragma aux eax_value = value [eax] modify exact [];
extern long in_ebx(long);
#pragma aux in_ebx = parm [ebx] value [ebx] modify exact [];
extern long ebx_value(void);
#pragma aux ebx_value = value [ebx] modify exact [];
extern long in_ecx(long);
#pragma aux in_ecx = parm [ecx] value [ecx] modify exact [];
extern long ecx_value(void);
#pragma aux ecx_value = value [ecx] modify exact [];
extern long in_esi(long);
#pragma aux in_esi = parm [esi] value [esi] modify exact [];
extern long esi_value(void);
#pragma aux esi_value = value [esi] modify exact [];
extern long in_edi(long);
#pragma aux in_edi = parm [edi] value [edi] modify exact [];
extern short in_ax(short);
#pragma aux in_ax = parm [ax] value [ax] modify exact [];
extern short in_dx(short);
#pragma aux in_dx = parm [dx] value [dx] modify exact [];
extern unsigned char in_al(unsigned char);
#pragma aux in_al = parm [al] value [al] modify exact [];
extern unsigned char in_bh(unsigned char);
#pragma aux in_bh = parm [bh] value [bh] modify exact [];
extern unsigned char in_bl(unsigned char);
#pragma aux in_bl = parm [bl] value [bl] modify exact [];
extern unsigned char in_dl(unsigned char);
#pragma aux in_dl = parm [dl] value [dl] modify exact [];
extern unsigned char in_dh(unsigned char);
#pragma aux in_dh = parm [dh] value [dh] modify exact [];

void synchronize_network_players(void)
{
    long player, pending_stage, send_stage;
    volatile long stage;
    short local, lead;
    unsigned char kind, packet_stage, clear;

    if (in_eax(sync_player_count) < 2)
        return;
    local = in_ax(sync_local_player);
    lead = in_dx(sync_first_player);
    if (local != lead)
        goto client;

    /* The lead player completes two readiness stages in list order. */
    stage = 1;
    goto check_stage;
start_stage:
    in_ecx(sync_first_player);
    goto next_reset;
reset_peer:
    sync_peer_ready_stage[ecx_value()] = in_bl(0);
next_reset:
    in_ecx(sync_next_player[ecx_value()]);
    if (ecx_value() >= 0)
        goto reset_peer;

    in_esi(totalclock);
    pending_stage = stage;
    send_stage = in_edi(stage);
    in_esi((long)((unsigned long)esi_value() - 8UL));
poll_leader:
    /* Retransmit at eight-tick intervals to peers still waiting. */
    receive_packets();
    if (in_eax((long)((unsigned long)esi_value() + 8UL)) > totalclock)
        goto start_scan;
    in_esi(totalclock);
    kind = in_bh(5);
    packet_stage = in_al((unsigned char)stage);
    in_ecx(sync_first_player);
    sync_packet[0] = kind;
    sync_packet_ready_stage = packet_stage;
    goto next_send;
send_peer:
    if (in_eax(sync_peer_ready_stage[ecx_value()]) != send_stage)
        send_sync_packet(ecx_value(), sync_packet, 2);
next_send:
    in_ecx(sync_next_player[ecx_value()]);
    if (ecx_value() >= 0)
        goto send_peer;
start_scan:
    in_ecx(sync_first_player);
    goto next_check;
check_peer:
    if (in_eax(sync_peer_ready_stage[ecx_value()]) != pending_stage)
        goto incomplete;
next_check:
    in_ecx(sync_next_player[ecx_value()]);
    if (ecx_value() >= 0)
        goto check_peer;
incomplete:
    if (ecx_value() >= 0)
        goto poll_leader;

    ++stage;
check_stage:
    if (stage <= 2)
        goto start_stage;
    return;

client:
    /* A client acknowledges stage one and returns after stage two. */
    player = in_eax(lead);
    sync_peer_ready_stage[player] = in_dl(0);
poll_client:
    in_eax(sync_first_player);
    in_al(sync_peer_ready_stage[eax_value()]);
    if ((eax_value() & 255) == 2)
        return;
    receive_packets();
    in_eax(sync_first_player);
    if (in_ecx(sync_peer_ready_stage[eax_value()]) != 1)
        goto poll_client;
    clear = in_dh(0);
    in_ebx(2);
    sync_peer_ready_stage[eax_value()] = clear;
    send_sync_packet(eax_value(), sync_packet, ebx_value());
    goto poll_client;
}
