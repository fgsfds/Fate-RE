// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// See ../engine/BUILDLIC.TXT. Modified from the pinned historical GAME.C.
/* Production selects nine unchanged C sections (714 bytes); the remaining
 * 202 bytes stay in the receive_*.asm fragments. The full compiler context is
 * 910 bytes and is not itself an exact replacement. Branch linking changes
 * validated displacement operands only; see LEAF_CODE_SLICES.
 * Packets/chains must be valid; ring cursors are 0..255. A text packet copies
 * its byte-truncated length without a terminator. All storage is a fixed DOS
 * DS overlay; signed word views preserve the same bits as other unsigned views.
 * Counter and clock arithmetic wraps as unsigned 32-bit. */
#pragma pack(push, 1)
typedef struct {
    unsigned char forward, strafe, turn;
    short buttons;
} Input;
#pragma pack(pop)

extern unsigned char network_enabled, packet[546];
extern short player_count, local_player, connecthead, connectpoint2[16];
extern Input current_input[16];
extern long event_write_index, received_write_index, event_read_index;
extern short received_checksum[256], generated_checksum[256];
extern short sync_error;
extern unsigned char message_text[255], message_length, peer_ready_stage[16];
extern unsigned char quit_requested;
extern unsigned long message_deadline, totalclock, last_tick;

extern short getpacket(short *, unsigned char *);
#pragma aux getpacket parm [eax] [edx] value [ax] modify exact [eax edx];
extern void sendpacket(int, unsigned char *, int);
#pragma aux sendpacket parm [eax] [edx] [ebx] modify exact [eax edx ebx];
/* The real snapshot callee preserves ESI, so expose that same incoming value
 * as a passthrough result while retaining its real call and clobbers. */
extern unsigned long snapshot_with_count(unsigned long);
#pragma aux snapshot_with_count "snapshot_input_" parm [esi] value [esi] modify exact [eax ebx ecx edx];
extern int random_value(void);
#pragma aux random_value parm [] value [eax] modify exact [eax];

typedef struct {
    long flags;
    short length, reserved_length;
    unsigned long snapshots;
    short sender, reserved_sender;
} PacketFrame;
extern short checksum_sum(short);
#pragma aux checksum_sum = parm nomemory [di] value [di] modify exact nomemory [];
extern short parity_word(unsigned long);
#pragma aux parity_word = parm nomemory [eax] value [ax] modify exact nomemory [];
void receive_packets(void);
/* Assembly saves EBX ECX EDX ESI EDI and leaves only EAX unspecified. */
#pragma aux receive_packets parm [] modify exact [eax];
void receive_packets(void)
{
    long index, bit, player;
    PacketFrame frame;

    if (network_enabled == 0)
        return;

    frame.snapshots = 0;
    while ((frame.length = getpacket(&frame.sender, packet)) > 0) {
        switch (packet[0]) {
        case 0:
            index = ((player_count + 1) >> 1) + 1;
            bit = 8;
            for (player = connecthead; player >= 0;
                 player = connectpoint2[player]) {
                frame.flags = packet[bit >> 3] >> (bit & 7);
                if (frame.flags & 1)
                    current_input[player].forward = packet[index++];
                if (frame.flags & 2)
                    current_input[player].strafe = packet[index++];
                if (frame.flags & 4)
                    current_input[player].turn = packet[index++];
                if (frame.flags & 8) {
                    current_input[player].buttons = (short)packet[index] +
                        ((long)packet[index + 1] << 8);
                    index += 2;
                }
                bit += 4;
            }

            while (index != frame.length) {
                /* Keep the original two stores and intervening packet read.
                 * A packed 16-bit source read would lose this access order. */
                received_checksum[received_write_index] = packet[index];
                received_checksum[received_write_index] = checksum_sum(received_checksum[received_write_index] +
                    ((long)packet[index + 1] << 8));
                received_write_index = (received_write_index + 1) & 255;
                index += 2;
            }

            if (event_write_index != event_read_index &&
                event_read_index != received_write_index) {
                sync_error = 0;
                do {
                    long read = event_read_index + 1;
                    short error = sync_error;
                    error |= generated_checksum[read - 1] ^ received_checksum[read - 1];
                    event_read_index = read & 255;
                    sync_error = error;
                } while (event_write_index != event_read_index &&
                         event_read_index != received_write_index);
            }
            frame.snapshots = snapshot_with_count(frame.snapshots + 1);
            break;

        case 1:
            bit = packet[1];
            index = 2;
            if (bit & 1)
                current_input[frame.sender].forward = packet[index++];
            if (bit & 2)
                current_input[frame.sender].strafe = packet[index++];
            if (bit & 4)
                current_input[frame.sender].turn = packet[index++];
            if (bit & 8) {
                current_input[frame.sender].buttons =
                    (current_input[frame.sender].buttons & 0xff00) | (short)packet[index++];
            }
            if (bit & 16) {
                current_input[frame.sender].buttons =
                    (current_input[frame.sender].buttons & 255) |
                    ((short)packet[index] << 8);
            }
            break;

        case 2:
            /* Length truncation to a byte is part of the original behavior. */
            message_length = (unsigned char)(frame.length - 1);
            for (index = (long)message_length - 1; index >= 0; --index)
                message_text[index] = packet[index + 1];
            message_deadline = totalclock + 360UL +
                               ((unsigned long)message_length << 4);
            break;

        case 5:
            peer_ready_stage[frame.sender] = packet[1];
            if (frame.sender == connecthead && (unsigned long)packet[1] == 2)
                sendpacket(connecthead, packet, 2);
            break;

        case 255:
            quit_requested = 1;
            break;
        }
    }

    if (local_player != connecthead && (parity_word(frame.snapshots) & 1) == 0) {
        if (random_value() & 1)
            ++last_tick;
        else
            --last_tick;
    }
}


