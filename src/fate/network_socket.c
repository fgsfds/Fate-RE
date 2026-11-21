#pragma pack(push, 1)
typedef struct {
    char padding[10];
    unsigned char socket_low, socket_high;
} IpxEventPrefix;
#pragma pack(pop)

extern unsigned char transport;
extern short socket;
extern unsigned char current_socket_low, current_socket_high;
extern char compaddr[16][12];
extern IpxEventPrefix *ipx_send_event;

/* Invoke the resident DOS IPX driver through interrupt 7Ah. */
extern int socket_service(int status, int function, int port, int flags);
#pragma aux socket_service = "int 7ah" parm [eax] [ebx] [edx] [ecx] value [eax] modify exact [eax ebx ecx edx];

extern int keep_transport(int);
#pragma aux keep_transport = parm [eax] value [eax] modify exact [];

int set_network_socket(int port)
{
    int index;
    unsigned char low;

    if (keep_transport((unsigned char)transport) < 5) {
        socket = port;
        return 0;
    }

    socket_service(0, 1, socket, 0);
    socket = port;
    socket_service(0, 1, (short)port, 0);
    if (socket_service(255, 0, socket, 0) & 0xff)
        return -2;

    /* Update the event block and every stored peer address. */
    current_socket_low = socket;
    current_socket_high = socket >> 8;
    ipx_send_event->socket_low = current_socket_low;
    ipx_send_event->socket_high = socket >> 8;
    low = socket;
    index = 0;
    goto next;
    do {
        compaddr[index][10] = low;
        compaddr[index][11] = socket >> 8;
        ++index;
next:
        ;
    } while (index < 16);
    return 0;
}
