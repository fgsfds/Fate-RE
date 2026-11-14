/* Ordered subsystem teardown at loaded0x3b34d; unknown callees stay provisional. */
extern char shutdown_network, shutdown_b, shutdown_c, shutdown_d;
extern char shutdown_e, shutdown_video, shutdown_group, shutdown_h;
extern char shutdown_message[];
extern void uninitmultiplayers(void), shutdown_step_b(void), shutdown_step_c(void);
extern void shutdown_step_d(void), shutdown_step_e(void), uninitengine(void);
extern void uninitgroupfile(void), shutdown_step_h(void);
extern int printf(const char *, ...);
void shutdown_textmode(void);
#pragma aux shutdown_textmode = "mov eax, 3" "int 10h" modify [eax]

void main_run(void)
{
    if (shutdown_network) uninitmultiplayers();
    if (shutdown_b) shutdown_step_b();
    if (shutdown_c) shutdown_step_c();
    if (shutdown_d) shutdown_step_d();
    if (shutdown_e) shutdown_step_e();
    if (shutdown_video) {
        uninitengine();
        shutdown_textmode();
        printf(shutdown_message);
    }
    if (shutdown_group) uninitgroupfile();
    if (shutdown_h) shutdown_step_h();
    shutdown_network = 0;
    shutdown_b = 0;
    shutdown_c = 0;
    shutdown_d = 0;
    shutdown_e = 0;
    shutdown_video = 0;
    shutdown_group = 0;
    shutdown_h = 0;
}
