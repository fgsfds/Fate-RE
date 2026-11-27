extern volatile short *outbufplc, *outbufend, *comport;
extern long comvect;
extern unsigned char serial_uses_uart;
extern int startcom(void), uninstallbicomhandlers(void);
extern void disable_interrupts(void), enable_interrupts(void);
#pragma aux startcom modify exact [eax];
#pragma aux disable_interrupts modify exact [eax ebx];
#pragma aux enable_interrupts modify exact [eax];
#pragma aux uninstallbicomhandlers modify exact [eax];
/* The port helpers use the low byte of EAX. The read invalidates the port register. */
extern unsigned int port_in(unsigned int);
#pragma aux port_in = "in al, dx" parm [edx] value [eax] modify exact [eax edx];
extern void port_out(unsigned int, unsigned int);
#pragma aux port_out = "out dx, al" parm [edx] [eax] modify exact [];

/* Register bindings for the original transmit drain and PIC mask sequence. */
extern long drain_budget(long);
#pragma aux drain_budget = parm [edx] value [edx] modify exact [];
extern unsigned long irq_bit(unsigned long);
#pragma aux irq_bit = parm [ebx] value [ebx] modify exact [];
/* Select the PIC line once the vector and command port registers are loaded. */
extern unsigned long irq_line(unsigned long vector, unsigned int port);
#pragma aux irq_line = "and ecx, 7" parm [ecx] [edx] value [ecx] modify exact [ecx];

void shutdown_serial_network(void)
{
    long budget = drain_budget(0x100000);
    while (*outbufplc != *outbufend && budget >= 0) {
        startcom();
        --budget;
    }

    /* Mask the serial IRQ at the primary PIC before uninstalling its handler. */
    disable_interrupts();
    {
        unsigned long mask = irq_bit(1UL);
        unsigned long irq = irq_line(*(volatile long *)&comvect, 0x21);
        unsigned int current = port_in(0x21);
        port_out(0x21, current | (mask << irq));
    }
    if (serial_uses_uart) {
        port_out(*comport + 1, 0);
        port_out(*comport + 4, 0);
    }
    enable_interrupts();
    uninstallbicomhandlers();
}
