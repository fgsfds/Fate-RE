/* Return the data and code segment selectors of the audio driver. */
extern void get_audio_data_selector_body(void);
#pragma aux get_audio_data_selector_body = 0x66 0x8c 0xd8 modify exact [];

void get_audio_data_selector(void);
#pragma aux get_audio_data_selector modify exact [];
void get_audio_data_selector(void)
{
    get_audio_data_selector_body();
}

extern void get_audio_code_selector_body(void);
#pragma aux get_audio_code_selector_body = 0x66 0x8c 0xc8 modify exact [];

void get_audio_code_selector(void);
#pragma aux get_audio_code_selector modify exact [];
void get_audio_code_selector(void)
{
    get_audio_code_selector_body();
}
