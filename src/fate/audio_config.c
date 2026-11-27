#include "cfgabi.h"

extern int open_configuration(Configuration *configuration, const char *file);
extern int find_configuration_section(Configuration *configuration, const char *section);
#pragma aux (config_call) open_configuration;
#pragma aux (config_call) find_configuration_section;

extern void report_audio_config_error(const char *message);
extern const char audio_config_filename[], audio_config_open_error[], digital_section[];
extern const char device_id_key[], device_port_key[], device_dma_key[], device_irq_key[];
extern int audio_device_id, audio_device_port, audio_device_dma, audio_device_irq;

int read_audio_configuration(void)
{
    Configuration configuration;

    if (!open_configuration(&configuration, audio_config_filename)) {
        report_audio_config_error(audio_config_open_error);
        return 0;
    }
    if (!find_configuration_section(&configuration, digital_section)) {
        close_configuration(&configuration);
        return 0;
    }
    read_configuration_integer(&configuration, device_id_key, &audio_device_id);
    read_configuration_integer(&configuration, device_port_key, &audio_device_port);
    read_configuration_integer(&configuration, device_dma_key, &audio_device_dma);
    read_configuration_integer(&configuration, device_irq_key, &audio_device_irq);
    close_configuration(&configuration);
    return 1;
}
