/* Parse DOS launch options and take the first map name. */
extern int argument_count;
extern char **argument_vector;
extern const char map_extension[], extension_separator[];
extern const char *command_line_options[];
extern int force_video_setup;

extern void startup_copy_name(char *, const char *);
#pragma aux startup_copy_name "strcpy_" parm [eax] [edx] modify exact [eax];
extern void startup_uppercase(char *);
#pragma aux startup_uppercase "strupr_" parm [eax] modify exact [eax];
extern char *startup_find(char *);
#pragma aux startup_find "strstr_" parm [eax] modify exact [eax];
extern char *startup_strip(char *, const char *);
#pragma aux startup_strip "strtok_" parm [eax] [edx] modify exact [eax];
extern int startup_option_matches(const char *, const char *);
#pragma aux startup_option_matches "stricmp_" parm [eax] [edx] modify exact [eax];
extern void print_command_line_help(void);
#pragma aux print_command_line_help modify exact [eax];
extern void finish_startup_arguments(void);
#pragma aux finish_startup_arguments aborts modify exact [];

/* Keep the shared register frame and the scanner's live values across calls. */
extern int begin_parsing(char *);
#pragma aux begin_parsing = "push ebx" "push ecx" "push edx" "push esi" "push edi" "push ebp" \
    "sub esp,4" "mov ebx,eax" "mov byte ptr [eax],0" "mov eax,argument_count" \
    "mov edi,argument_vector" "mov [esp],eax" \
    parm [eax] value [eax] modify exact [eax ebx ecx edx esi edi];
extern void start_options(void);
#pragma aux start_options = "mov ebp,[esp]" "xor esi,esi" modify exact [esi];
extern void start_arguments(void);
#pragma aux start_arguments = "mov ecx,1" modify exact [ecx];
extern void next_argument(void);
#pragma aux next_argument = "inc ecx" modify exact [ecx];
extern void next_option(void);
#pragma aux next_option = "inc esi" modify exact [esi];

extern int argument_limit(void);
#pragma aux argument_limit = value [ebp] modify exact [];
extern int argument_index(void);
#pragma aux argument_index = value [ecx] modify exact [];
extern int option_number(void);
#pragma aux option_number = value [esi] modify exact [];
extern char *read_argument(void);
#pragma aux read_argument = "mov eax,ecx" "mov eax,[edi+eax*4]" value [eax] modify exact [eax];
extern const char *copy_source(void);
#pragma aux copy_source = "mov edx,eax" value [edx] modify exact [edx];
extern const char *without_option_prefix(void);
#pragma aux without_option_prefix = "inc eax" value [eax] modify exact [eax];
extern unsigned leading_byte(const char *);
#pragma aux leading_byte = "xor edx,edx" "mov dl,[eax]" parm [eax] value [edx] modify exact [edx];
extern char *map_output(void);
#pragma aux map_output = value [ebx] modify exact [];
extern char *map_in_eax(void);
#pragma aux map_in_eax = "mov eax,ebx" value [eax] modify exact [eax];
extern void set_map_output(char *);
#pragma aux set_map_output = "" parm [ebx] modify exact [];
extern void match_map_extension(void);
#pragma aux match_map_extension = "mov edx,offset map_extension" modify exact [edx];
extern const char *option_name(int);
#pragma aux option_name = "mov edx,[esi*4+command_line_options]" parm [esi] value [edx] modify exact [edx];

extern void release_argument_slot(void);
#pragma aux release_argument_slot = "add esp,4" modify exact [];

void parse_startup_arguments(char *);
#pragma aux parse_startup_arguments parm [eax] modify exact [eax ebx ecx edx esi edi];
void parse_startup_arguments(char *map_name)
{
    char *target;
    const char *keyword;
    unsigned first;

    if (begin_parsing(map_name) < 2)
        goto done;

    start_options();
    do {
        for (start_arguments(); argument_index() < argument_limit(); next_argument()) {
            first = leading_byte(read_argument());
            if (first == '-' || first == '/')
                goto check_option;

            if (!*map_output()) {
                startup_copy_name(map_output(), copy_source());
                target = map_in_eax();
                match_map_extension();
                startup_uppercase(target);
                if (startup_find(map_output()))
                    set_map_output(startup_strip(map_output(), extension_separator));
            }
            goto advance_argument;

check_option:
            read_argument();
            keyword = option_name(option_number());
            if (startup_option_matches(without_option_prefix(), keyword) != 0)
                goto advance_argument;
            if ((unsigned)option_number() <= 0)
                goto video_setup;
            if ((unsigned)option_number() <= 2)
                goto print_help;
            goto advance_argument;

video_setup:
            force_video_setup = 1;
            goto advance_argument;

print_help:
            print_command_line_help();
advance_argument:;
        }
        next_option();
    } while (option_number() < 3);

done:
    release_argument_slot();
    finish_startup_arguments();
}
