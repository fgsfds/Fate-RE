/* Consume one queued input frame, snapshot interpolation state, and advance play. */
#pragma pack(push,1)
typedef struct FrameInput {
    unsigned char forward, strafe, turn;
    unsigned short buttons;
} FrameInput;
#pragma pack(pop)
typedef struct FrameSprite {
    long x,y,z;
    unsigned char rest[32];
} FrameSprite;
extern short connecthead, connectpoint2[], player_count;
extern short headspritestat[], nextspritestat[];
extern unsigned long processed_frame_count, actor_clock, input_read_index, event_write_index;
extern short event_queue[];
extern unsigned char frame_network_enabled;
extern long recorded_frame_count, frame_recording_mode;
extern FrameInput input_history[][16], frame_current_input[], frame_recorded_input[][2];
extern long frame_player_x[], frame_player_y[], frame_player_z[], frame_player_horizon[], frame_player_height[];
extern long frame_old_x[], frame_old_y[], frame_old_z[], frame_old_horizon[], frame_old_height[];
extern short frame_player_angle[], frame_old_angle[], frame_player_sector[], frame_previous_sector[];
extern signed char frame_status_mask[];
extern FrameSprite frame_sprite[];
extern long frame_sprite_positions[][3];
/* Copy exactly three position dwords; the only handwritten instructions here. */
extern void frame_copy_position(const void *,void *,unsigned);
#pragma aux frame_copy_position = "rep movsd" parm [esi] [edi] [ecx] modify exact [ecx esi edi];
extern int checksum_gameplay_state(void);
#pragma aux checksum_gameplay_state modify exact [eax];
extern void update_interpolations(void), update_player_motion(int), do_animations(void);
extern void update_board_environment(void), rotate_network_lead_player(void);
#pragma aux update_interpolations modify exact [eax];
#pragma aux update_player_motion parm [eax] modify exact [eax];
#pragma aux do_animations modify exact [eax];
#pragma aux update_board_environment modify exact [eax];
#pragma aux rotate_network_lead_player modify exact [eax];
/* Empty identity stages express register allocation without emitting opcodes. */
extern int frame_integer_eax(int);
#pragma aux frame_integer_eax = "" parm [eax] value [eax] modify exact [];
extern int frame_sprite_id_ebx(int);
#pragma aux frame_sprite_id_ebx = "" parm [ebx] value [ebx] modify exact [];
extern int frame_mask_esi(int);
#pragma aux frame_mask_esi = "" parm [esi] value [esi] modify exact [];
extern unsigned long frame_counter_eax(unsigned long);
#pragma aux frame_counter_eax = "" parm [eax] value [eax] modify exact [];
extern long frame_record_row(long);
#pragma aux frame_record_row = "" parm [esi] value [esi] modify exact [];
void process_gameplay_frame(void);
#pragma aux process_gameplay_frame modify exact [eax];
void process_gameplay_frame(void)
{
    short current, slot;
    ++processed_frame_count;
    for(current=connecthead;(short)current>=0;current=connectpoint2[(short)current]) {
        frame_current_input[(short)current].forward=input_history[input_read_index][(short)current].forward;
        frame_current_input[(short)current].strafe=input_history[input_read_index][(short)current].strafe;
        frame_current_input[(short)current].turn=input_history[input_read_index][(short)current].turn;
        frame_current_input[(short)current].buttons=input_history[input_read_index][(short)current].buttons;
    }
    input_read_index=(input_read_index+1U)&255U;
    if(frame_network_enabled) {
        event_queue[event_write_index]=(short)checksum_gameplay_state();
        event_write_index=(event_write_index+1U)&255U;
    }
    for(current=connecthead;(short)current>=0;current=connectpoint2[(short)current]) {
        frame_old_x[(short)current]=frame_player_x[(short)current];
        frame_old_y[(short)current]=frame_player_y[(short)current];
        frame_old_z[(short)current]=frame_player_z[(short)current];
        frame_old_horizon[(short)current]=frame_player_horizon[(short)current];
        frame_old_height[(short)current]=frame_player_height[(short)current];
        frame_old_angle[(short)current]=frame_player_angle[(short)current];
    }
    for(current=10;(short)current>=0;--current) {
        if(frame_status_mask[(short)current]<0)continue;
        for(slot=headspritestat[(short)current];slot>=0;slot=nextspritestat[slot]) {
            int status_index, sprite_index, mask;
            unsigned long frame;
            status_index=frame_integer_eax((short)current);
            sprite_index=frame_sprite_id_ebx(slot);
            mask=frame_mask_esi(frame_status_mask[status_index]);
            frame=frame_counter_eax(processed_frame_count);
            if(((frame-(unsigned long)sprite_index)&(unsigned long)mask)==0)
                frame_copy_position(&frame_sprite[sprite_index],frame_sprite_positions[sprite_index],3);
        }
    }
    for(current=connecthead;(short)current>=0;current=connectpoint2[(short)current])
        frame_previous_sector[(short)current]=frame_player_sector[(short)current];
    update_interpolations();
    if(frame_integer_eax(player_count)<=2 && frame_recording_mode==1) {
        slot=0;
        for(current=connecthead;current>=0;current=connectpoint2[current],++slot) {
            /* Count dies before the column reuses ESI, matching the original. */
            long record_row=frame_record_row(recorded_frame_count);
            frame_recorded_input[record_row][slot].forward=frame_current_input[current].forward;
            frame_recorded_input[record_row][slot].strafe=frame_current_input[current].strafe;
            frame_recorded_input[record_row][slot].turn=frame_current_input[current].turn;
            frame_recorded_input[record_row][slot].buttons=frame_current_input[current].buttons;
        }
        ++recorded_frame_count;
        if(recorded_frame_count>0x3fff)recorded_frame_count=0x3fff;
    }
    actor_clock+=3U;
    for(current=connecthead;(short)current>=0;current=connectpoint2[(short)current])
        update_player_motion((short)current);
    do_animations();
    update_board_environment();
    rotate_network_lead_player();
}
