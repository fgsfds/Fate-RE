/* Retry a DOS process launch in each semicolon-separated PATH directory. */
extern unsigned length_in_ecx(unsigned);
#pragma aux length_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern int value_in_ecx(int);
#pragma aux value_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern int value_in_edx(int);
#pragma aux value_in_edx = "" parm [edx] value [edx] modify exact [];
extern const char *path_in_edi(const char *);
#pragma aux path_in_edi = "" parm [edi] value [edi] modify exact [];
/* Preserve the PATH search call and cursor registers. */
extern const char *path_in_eax(const char *);
#pragma aux path_in_eax = "" parm [eax] value [eax] modify exact [];
extern const char *path_in_ebx(const char *);
#pragma aux path_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern char *target_in_eax(char *);
#pragma aux target_in_eax = "" parm [eax] value [eax] modify exact [];

extern void check_stack(void);
extern int spawnve(int, const char *, const char *const *, const char *const *);
#pragma aux spawnve modify exact [eax ebx ecx edx];
extern int *get_errno_address(void);
#pragma aux get_errno_address modify exact [eax];
extern char *getenv(const char *);
#pragma aux getenv parm [eax] modify exact [eax];
extern unsigned path_name_length(const char *);
#pragma aux path_name_length "strlen_" parm [eax] modify exact [eax];
extern const char *strchr(const char *, int);
#pragma aux strchr parm [eax] [edx] modify exact [eax edx];
extern void set_errno(int);
#pragma aux set_errno parm [eax] modify exact [eax];
extern void set_runtime_error(int);
#pragma aux set_runtime_error parm [eax] modify exact [eax];
extern void *copy_path_bytes(void *, const void *, unsigned);
#pragma aux copy_path_bytes "memcpy_" parm [eax] [edx] [ebx] modify exact [eax ebx edx];
extern const char spawn_path_variable[];

extern void begin_spawn_search(void);
#pragma aux begin_spawn_search = 0x68 0xb4 0 0 0 "call check_stack" \
    "push esi" "push edi" "enter 0a0h,0" "push eax" 0x81 0xed 0x82 0 0 0 modify exact [esi edi];
extern int spawn_mode(void);
#pragma aux spawn_mode = value [eax] modify exact [];
extern const char *spawn_name(void);
#pragma aux spawn_name = value [edx] modify exact [];
extern const char *const *spawn_argv(void);
#pragma aux spawn_argv = value [ebx] modify exact [];
extern const char *const *spawn_envp(void);
#pragma aux spawn_envp = value [ecx] modify exact [];
extern void name_to_esi(const char *);
#pragma aux name_to_esi = "" parm [esi] modify exact [];
extern const char *original_name(void);
#pragma aux original_name = value [esi] modify exact [];
extern int last_status(void);
#pragma aux last_status = value [edx] modify exact [];
extern int first_status(void);
#pragma aux first_status = value [ecx] modify exact [];

extern const char *prefix_start(void);
#pragma aux prefix_start = value [ebx] modify exact [];
extern const char *prefix_end(void);
#pragma aux prefix_end = value [edi] modify exact [];
extern const char *copy_source(void);
#pragma aux copy_source = value [edx] modify exact [];
extern unsigned copy_length(void);
#pragma aux copy_length = value [ebx] modify exact [];
extern char *current_target(void);
#pragma aux current_target = value [eax] modify exact [];
extern int finish_spawn_search(int);
#pragma aux finish_spawn_search = 0x8d 0xa5 0x82 0 0 0 "pop ebp" "pop edi" "pop esi" \
    parm [eax] value [eax] modify exact [esi edi];

/* Interpret the saved PATH search values relative to the adjusted EBP. */
enum { SEARCH_PATH_BYTES = 144 };
#pragma pack(push, 1)
typedef struct {
    unsigned char reserved[0x72];
    volatile unsigned maximum_prefix;
    const char *const *saved_envp;
    const char *const *saved_argv;
    unsigned name_length;
} SearchFrameView;
typedef struct {
    int mode;
    char path[SEARCH_PATH_BYTES];
} SearchLocals;
#pragma pack(pop)
extern SearchFrameView *search_frame(void);
#pragma aux search_frame = value [ebp] modify exact [];
#define SEARCH_LOCALS (*(SearchLocals *)((char *)search_frame() - 0x22))
extern unsigned size_in_eax(unsigned);
#pragma aux size_in_eax = "" parm [eax] value [eax] modify exact [];
extern const char *path_to_edx(const char *);
#pragma aux path_to_edx = "" parm [edx] value [edx] modify exact [];
extern unsigned length_to_ebx(unsigned);
#pragma aux length_to_ebx = "" parm [ebx] value [ebx] modify exact [];
extern const char *const *env_to_ecx(const char *const *);
#pragma aux env_to_ecx = "" parm [ecx] value [ecx] modify exact [];
extern const char *const *argv_to_ebx(const char *const *);
#pragma aux argv_to_ebx = "" parm [ebx] value [ebx] modify exact [];
extern int mode_to_eax(int);
#pragma aux mode_to_eax = "" parm [eax] value [eax] modify exact [];

int search_and_spawn(int, const char *, const char *const *, const char *const *);
#pragma aux search_and_spawn modify exact [eax ebx ecx edx esi edi];
int search_and_spawn(int mode, const char *name, const char *const *argv, const char *const *envp)
{
    unsigned length;
    const char *end;
    char *target;
    int result, delimiter;

    begin_spawn_search();
    name_to_esi(spawn_name());
    search_frame()->saved_argv = spawn_argv();
    search_frame()->saved_envp = spawn_envp();
    result = spawnve(spawn_mode(), spawn_name(), spawn_argv(), spawn_envp());
    value_in_ecx(result);
    value_in_edx(result);
    if (result != -1 || *get_errno_address() != 1 ||
        original_name()[0] == '\\' || !original_name()[0] || original_name()[1] == ':')
        goto return_result;
    if (!path_in_eax(path_in_ebx(getenv(spawn_path_variable)))) {
        result = first_status();
        goto done;
    }

    search_frame()->name_length = size_in_eax(path_name_length(path_in_eax(original_name())) + 1);
    search_frame()->maximum_prefix = size_in_eax(size_in_eax(SEARCH_PATH_BYTES) - search_frame()->name_length);
check_component:
    if (!*prefix_start())
        goto return_result;
    delimiter = value_in_edx(';');
    end = path_in_eax(path_in_edi(strchr(path_in_eax(prefix_start()), delimiter)));
    if (!end)
        path_in_edi(prefix_start() + path_name_length(path_in_eax(prefix_start())));

    length = length_in_ecx((unsigned)(prefix_end() - prefix_start()));
    if (length > search_frame()->maximum_prefix) {
        set_errno(2);
        set_runtime_error(10);
        result = -1;
        goto done;
    }
    target = target_in_eax(SEARCH_LOCALS.path);
    path_to_edx(prefix_start());
    length_to_ebx(length);
    copy_path_bytes(target, copy_source(), copy_length());
    target = target_in_eax(SEARCH_LOCALS.path + length);
    if (target[-1] != '\\') {
        *current_target() = '\\';
        target_in_eax(current_target() + 1);
    }
    length_to_ebx(search_frame()->name_length);
    path_to_edx(original_name());
    env_to_ecx(search_frame()->saved_envp);
    copy_path_bytes(current_target(), copy_source(), copy_length());
    mode_to_eax(SEARCH_LOCALS.mode);
    path_to_edx(SEARCH_LOCALS.path);
    argv_to_ebx(search_frame()->saved_argv);
    result = spawnve(spawn_mode(), spawn_name(), spawn_argv(), spawn_envp());
    value_in_edx(result);
    if (result == -1 && *get_errno_address() == 1 && *prefix_end() == ';') {
        path_in_ebx(prefix_end() + 1);
        goto check_component;
    }

return_result:
    result = last_status();
done:
    return finish_spawn_search(result);
}
