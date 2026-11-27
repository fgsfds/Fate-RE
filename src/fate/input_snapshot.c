#pragma pack(push, 1)
typedef struct {
    unsigned char forward, strafe, turn;
    unsigned short buttons;
} Input;
#pragma pack(pop)
extern long totalclock, input_clock;
extern unsigned long input_frame;
extern short connecthead, connectpoint2[];
extern Input current_input[], input_history[][16];

void snapshot_input(void)
{
    long player;
    input_clock = totalclock;
    for (player = connecthead; player >= 0; player = connectpoint2[player]) {
        input_history[input_frame][player].forward = current_input[player].forward;
        input_history[input_frame][player].strafe = current_input[player].strafe;
        input_history[input_frame][player].turn = current_input[player].turn;
        input_history[input_frame][player].buttons = current_input[player].buttons;
    }
    input_frame = (input_frame + 1) & 255;
}
