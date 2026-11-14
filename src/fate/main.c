/* Provisional names for FATE's runtime-confirmed main entry at 0x1002c.
 * Callee names describe this orchestration only; their internals are separate.
 */
typedef struct { short saved, current; } MainRecord;
extern char main_group_name[], main_load_error[], main_default_selection[];
extern short connecthead, connectpoint2[], main_indices[];
extern MainRecord main_records[];
extern long main_before_players, main_state_a, main_state_b, main_state_c, main_finished;
extern void main_prepare_callback(void);
extern void main_prepare(void (*)(void)), main_init_sequences(void);
extern long initgroupfile(char *);
extern void main_get_selection(char *);
extern long main_load_selection(char *);
extern void main_report(char *), main_step_a(void), main_step_b(void);
extern char main_resource[];
extern void main_install_resource(char *);
extern void main_step_c(void), main_initialize_player(short), main_reset_timer(void);
extern void main_step_d(void), main_step_e(void), main_step_f(void), main_run(void);

void main(int argc, char **argv)
{
    char selection[80];
    long player;
    main_prepare(main_prepare_callback);
    main_init_sequences();
    initgroupfile(main_group_name);
    selection[0] = 0;
    main_get_selection(selection);
    if (selection[0]) {
        if (main_load_selection(selection)) main_report(main_load_error);
    } else main_load_selection(main_default_selection);
    main_step_a();
    main_step_b();
    main_install_resource(main_resource);
    main_step_c();
    main_before_players = 0;
    for (player = connecthead; player >= 0; player = connectpoint2[player])
        main_initialize_player((short)player);
    main_reset_timer();
    main_state_a = 0;
    main_state_b = 0;
    main_state_c = 0;
    for (player = 0; player <= 500;) {
        player++;
        main_indices[player] = -1;
        main_records[player].current = main_records[player].saved;
    }
    main_step_d();
    main_step_e();
    main_step_f();
    main_run();
    main_finished = 1;
}
