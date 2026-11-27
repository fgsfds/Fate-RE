typedef struct {
    short (*initialize)(short);
    void (*shutdown)(void);
    void (*begin)(void);
    void (*end)(void);
} GraphicsDevice;
extern const GraphicsDevice *graphics_device;

short initialize_graphics_device(short mode)
{
    return graphics_device->initialize(mode);
}

void shutdown_graphics_device(void)
{
    graphics_device->shutdown();
}

void begin_graphics_device(void)
{
    graphics_device->begin();
}

void end_graphics_device(void)
{
    graphics_device->end();
}
