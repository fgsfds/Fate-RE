/* Prepare executable and batch launches for the DOS runtime. */
typedef void SpawnHook(void *);
#pragma aux SpawnHook parm [eax] modify exact [eax];
extern SpawnHook *save_spawn_state, *restore_spawn_state;
extern unsigned char dos_major_version;
extern char current_directory_prefix[];
extern const char batch_extension[], com_extension[], exe_extension[];
extern const char comspec_name[], spawn_cmd_name[], spawn_command_name[];

/* The setup helpers push the remaining stack arguments before these register calls. */
extern void check_stack(void);
extern int build_child_environment(void *, void *, void *, void *);
#pragma aux build_child_environment modify exact [eax];
extern unsigned executable_name_length(const char *);
#pragma aux executable_name_length "strlen_" parm [eax] modify exact [eax];
extern void *spawn_malloc(unsigned);
#pragma aux spawn_malloc "malloc_" parm [eax] modify exact [eax];
extern void spawn_free(void *);
#pragma aux spawn_free "free_" parm [eax] modify exact [eax];
extern unsigned stackavail(void);
#pragma aux stackavail modify exact [eax];
extern void split_path(const char *, char *, char **, char **);
#pragma aux split_path modify exact [eax ebx ecx];
extern void make_path(char *, const char *, const char *, const char *);
#pragma aux make_path modify exact [eax ebx ecx edx];
extern int stricmp(const char *, const char *);
#pragma aux stricmp modify exact [eax];
extern void set_errno(int);
#pragma aux set_errno modify exact [eax];
extern void set_runtime_error(int);
#pragma aux set_runtime_error modify exact [eax];
extern int probe_executable(const char *);
#pragma aux probe_executable modify exact [eax];
extern int prepare_spawn(int, const char *, void *, void *);
#pragma aux prepare_spawn modify exact [eax];
extern int *get_errno_address(void);
#pragma aux get_errno_address modify exact [eax];
extern void build_command_tail(const char *, void *, void *, int);
#pragma aux build_command_tail modify exact [eax];
extern const char *select_shell_switch(char *, unsigned);
#pragma aux select_shell_switch modify exact [eax];
extern const char *getenv(const char *);
#pragma aux getenv modify exact [eax];
extern int spawn_with_arguments(void);
#pragma aux spawn_with_arguments modify exact [eax];

/* Slot offsets are relative to the adjusted EBP from the original ENTER frame. */
#pragma pack(1)
typedef struct {
    unsigned char reserved[0x3e];
    const char *base, *extension, *drive, *directory;
    char shell_switch[4];
    unsigned tail_size, environment_selector;
    void *environment_offset, *environment_heap, *tail_heap, *path_heap;
    char *extension_slot;
    const char *const *arguments;
    void *tail;
    int result;
    char *path;
    unsigned char shell_kind;
} SpawnFrame;
#pragma pack()

extern SpawnFrame *spawn_frame(void);
#pragma aux spawn_frame = value [ebp] modify exact [];
extern void reserve_spawn_frame(void);
#pragma aux reserve_spawn_frame = 0x68 0xe4 0 0 0 "call check_stack" \
    "push esi" "push edi" "push es" "enter 0b0h,0" "push eax" 0x81 0xed 0x82 0 0 0 \
    modify exact [edi];

/* Bind C call arguments to the original Watcom registers. */
extern unsigned size_in_edx(unsigned);
#pragma aux size_in_edx = "" parm [edx] value [edx] modify exact [];
extern unsigned size_in_eax(unsigned);
#pragma aux size_in_eax = "" parm [eax] value [eax] modify exact [];
extern unsigned size_in_ebx(unsigned);
#pragma aux size_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern unsigned size_in_ecx(unsigned);
#pragma aux size_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern void *pointer_in_eax(const void *);
#pragma aux pointer_in_eax = "" parm [eax] value [eax] modify exact [];
extern void *pointer_in_edx(const void *);
#pragma aux pointer_in_edx = "" parm [edx] value [edx] modify exact [];
extern void *pointer_in_ebx(const void *);
#pragma aux pointer_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern void *pointer_in_ecx(const void *);
#pragma aux pointer_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern void *pointer_in_esi(const void *);
#pragma aux pointer_in_esi = "" parm [esi] value [esi] modify exact [];
extern void *pointer_in_edi(const void *);
#pragma aux pointer_in_edi = "" parm [edi] value [edi] modify exact [];
extern const char *original_path(void);
#pragma aux original_path = "" value [esi] modify exact [];

extern void *value_in_eax(void);
#pragma aux value_in_eax = value [eax] modify exact [];
extern void *value_in_ebx(void);
#pragma aux value_in_ebx = value [ebx] modify exact [];
extern void *value_in_ecx(void);
#pragma aux value_in_ecx = value [ecx] modify exact [];
extern void *value_in_edx(void);
#pragma aux value_in_edx = value [edx] modify exact [];

extern void *stack_buffer(unsigned);
#pragma aux stack_buffer = "sub esp,eax" "mov eax,esp" parm [eax] value [eax] modify exact [eax];
extern int int_in_eax(void);
#pragma aux int_in_eax = value [eax] modify exact [];
extern const char *extension_in_eax(void);
#pragma aux extension_in_eax = value [eax] modify exact [];

extern void clear_spawn_error(void);
#pragma aux clear_spawn_error = "xor eax,eax" modify exact [eax];
extern const char *begin_extension_trials(void);
#pragma aux begin_extension_trials = "mov eax,[ebp+7ah]" "mov edx,[ebp+7ah]" value [eax] modify exact [eax edx];

extern void path_segment(void);
#pragma aux path_segment = "push ds" "pop es" modify exact [];
extern void copy_extension_bytes(void);
#pragma aux copy_extension_bytes = "movsd" "movsb" modify exact [esi edi];

extern void add_split_path_base(void);
#pragma aux add_split_path_base = "add edx,[ebp+7ah]" modify exact [edx];
extern void push_environment_kind(void);
#pragma aux push_environment_kind = "push 0" modify exact [];
extern void push_spawn_argv(void);
#pragma aux push_spawn_argv = "push dword ptr [ebp+6eh]" modify exact [];
extern void push_path_extension(void);
#pragma aux push_path_extension = "push dword ptr [ebp+42h]" modify exact [];
extern void push_shell_switch_argument(void);
#pragma aux push_shell_switch_argument = "push dword ptr [ebp+72h]" modify exact [];
extern void push_shell_path_argument(void);
#pragma aux push_shell_path_argument = "push dword ptr [ebp+7ah]" modify exact [];
extern void push_shell_argument(const void *);
#pragma aux push_shell_argument = "push eax" parm [eax] modify exact [];
extern void push_shell_mode(void);
#pragma aux push_shell_mode = "push dword ptr [ebp-32h]" modify exact [];
extern void pop_shell_arguments(void);
#pragma aux pop_shell_arguments = "add esp,1ch" modify exact [];
extern int finish_spawn(int);
#pragma aux finish_spawn = 0x8d 0xa5 0x82 0 0 0 "pop ebp" "pop es" "pop edi" "pop esi" \
    parm [eax] value [eax] modify exact [esi edi];

int spawnve(int, const char *, const char *const *, const char *const *);
#pragma aux spawnve modify exact [eax ebx ecx edx esi edi];
int spawnve(int mode, const char *path, const char *const *argv, const char *const *envp)
{
    int result;
    unsigned bytes, capacity;
    void *block;
    const char *extension, *batch;
    const char *shell;

    reserve_spawn_frame();
    pointer_in_esi(value_in_edx());
    spawn_frame()->arguments = value_in_ebx();
    pointer_in_edx(value_in_ecx());
    spawn_frame()->shell_kind = 0;
    if ((unsigned)int_in_eax() >= 2) {
        set_errno(9);
return_failure:
        result = -1;
        goto done;
    }

    push_environment_kind();
    push_shell_argument(pointer_in_eax(&spawn_frame()->tail_size));
    block = pointer_in_eax(&spawn_frame()->environment_selector);
    pointer_in_ecx(&spawn_frame()->environment_offset);
    push_shell_argument(block);
    pointer_in_eax(value_in_ebx());
    pointer_in_ebx(&spawn_frame()->environment_heap);
    result = build_child_environment(value_in_eax(), value_in_edx(), value_in_ebx(), value_in_ecx());
    spawn_frame()->result = result;
    if (result == -1)
        goto done;

    bytes = size_in_eax(size_in_edx(executable_name_length(pointer_in_eax(original_path())) + 154));
    block = spawn_malloc(bytes);
    pointer_in_ebx(block);
    spawn_frame()->path_heap = block;
    if (block)
        goto use_path_heap;
    bytes = size_in_ebx((size_in_ebx((unsigned)value_in_edx() + 3)) & ~3U);
    capacity = stackavail();
    if (bytes >= capacity)
        goto fail_stack_path;
    stack_buffer((unsigned)value_in_ebx());
    goto check_stack_path;
fail_stack_path:
    size_in_eax(0);
check_stack_path:
    spawn_frame()->path = value_in_eax();
    if (value_in_eax())
        goto split_executable_path;
    spawn_free(spawn_frame()->environment_heap);
    goto return_failure;

use_path_heap:
    spawn_frame()->path = pointer_in_eax(block);

split_executable_path:
    block = pointer_in_eax(&spawn_frame()->extension);
    pointer_in_ebx(&spawn_frame()->drive);
    pointer_in_ecx(&spawn_frame()->directory);
    push_shell_argument(block);
    block = pointer_in_eax(&spawn_frame()->base);
    size_in_edx((unsigned)value_in_edx() - 147);
    push_shell_argument(block);
    add_split_path_base();
    pointer_in_eax(original_path());
    split_path(value_in_eax(), value_in_edx(), value_in_ebx(), value_in_ecx());
    save_spawn_state(pointer_in_eax((char *)spawn_frame() - 0x2e));
    block = spawn_malloc(spawn_frame()->tail_size);
    pointer_in_edx(block);
    spawn_frame()->tail_heap = block;
    if (block)
        goto use_tail_heap;
    bytes = size_in_edx(size_in_eax((size_in_eax(spawn_frame()->tail_size + 3)) & ~3U));
    capacity = stackavail();
    if (bytes >= capacity)
        goto fail_stack_tail;
    stack_buffer(size_in_eax(spawn_frame()->tail_size + 3) & ~3U);
    goto check_stack_tail;
fail_stack_tail:
    size_in_eax(0);
check_stack_tail:
    spawn_frame()->tail = value_in_eax();
    if (value_in_eax())
        goto check_relative_path;
    set_errno(2);
    size_in_eax(10);
    spawn_frame()->result = -1;
    set_runtime_error(int_in_eax());
    goto release_allocations;

use_tail_heap:
    spawn_frame()->tail = pointer_in_eax(block);

check_relative_path:
    if (dos_major_version >= 3 && !*spawn_frame()->drive && !*spawn_frame()->directory)
        spawn_frame()->directory = current_directory_prefix;
    push_path_extension();
    pointer_in_eax(spawn_frame()->path);
    pointer_in_edx(spawn_frame()->drive);
    pointer_in_ebx(spawn_frame()->directory);
    pointer_in_ecx(spawn_frame()->base);
    make_path(value_in_eax(), value_in_edx(), value_in_ebx(), value_in_ecx());
    set_errno(1);

    extension = pointer_in_eax(spawn_frame()->extension);
    if (!*extension)
        goto resolve_missing_extension;
    batch = pointer_in_edx(batch_extension);
    if (stricmp(extension_in_eax(), batch))
        goto explicit_executable;
    batch = pointer_in_eax(spawn_frame()->path);
    spawn_frame()->result = -1;
    if (probe_executable(batch))
        goto run_batch;
    goto release_allocations;

explicit_executable:
    pointer_in_edx(spawn_frame()->path);
    clear_spawn_error();
    pointer_in_ebx(spawn_frame()->tail);
    set_errno(int_in_eax());
    push_spawn_argv();
    size_in_eax(*(unsigned *)((char *)spawn_frame() - 0x32));
    pointer_in_ecx(spawn_frame()->environment_heap);
    result = prepare_spawn(int_in_eax(), value_in_edx(), value_in_ebx(), value_in_ecx());
    goto save_result;

resolve_missing_extension:
    spawn_frame()->extension_slot = pointer_in_edx((char *)value_in_edx() + executable_name_length(begin_extension_trials()));
    if (spawn_frame()->shell_kind) {
        set_errno(1);
        goto check_com_result;
    }

    pointer_in_ebx(spawn_frame()->tail);
    path_segment();
    pointer_in_edi(value_in_edx());
    pointer_in_esi(com_extension);
    clear_spawn_error();
    pointer_in_edx(spawn_frame()->path);
    copy_extension_bytes();
    set_errno(int_in_eax());
    push_spawn_argv();
    size_in_eax(*(unsigned *)((char *)spawn_frame() - 0x32));
    pointer_in_ecx(spawn_frame()->environment_heap);
    result = prepare_spawn(int_in_eax(), value_in_edx(), value_in_ebx(), value_in_ecx());
    spawn_frame()->result = result;

check_com_result:
    if (*get_errno_address() != 1)
        goto release_allocations;
    pointer_in_edi(spawn_frame()->extension_slot);
    pointer_in_edx(spawn_frame()->path);
    clear_spawn_error();
    pointer_in_ebx(spawn_frame()->tail);
    set_errno(int_in_eax());
    path_segment();
    pointer_in_esi(exe_extension);
    push_spawn_argv();
    copy_extension_bytes();
    size_in_eax(*(unsigned *)((char *)spawn_frame() - 0x32));
    pointer_in_ecx(spawn_frame()->environment_heap);
    result = prepare_spawn(int_in_eax(), value_in_edx(), value_in_ebx(), value_in_ecx());
    spawn_frame()->result = result;
    if (*get_errno_address() != 1)
        goto release_allocations;

    pointer_in_edi(spawn_frame()->extension_slot);
    clear_spawn_error();
    pointer_in_esi(batch_extension);
    set_errno(int_in_eax());
    extension = pointer_in_eax(spawn_frame()->path);
    copy_extension_bytes();
    if (!probe_executable(extension))
        goto release_allocations;

run_batch:
    block = pointer_in_eax(spawn_frame()->environment_heap);
    pointer_in_edx(spawn_frame()->arguments);
    pointer_in_ebx(spawn_frame()->tail);
    size_in_ecx(1);
    spawn_free(block);
    pointer_in_eax(spawn_frame()->path);
    spawn_frame()->environment_heap = 0;
    build_command_tail(value_in_eax(), value_in_edx(), value_in_ebx(), (int)value_in_ecx());
    push_environment_kind();
    push_shell_switch_argument();
    size_in_edx(spawn_frame()->shell_kind);
    push_shell_path_argument();
    pointer_in_eax(spawn_frame()->shell_switch);
    push_shell_argument(select_shell_switch(value_in_eax(), (unsigned)value_in_edx()));
    if (spawn_frame()->shell_kind)
        shell = spawn_cmd_name;
    else
        shell = spawn_command_name;
    push_shell_argument(shell);
    push_shell_argument(getenv(comspec_name));
    push_shell_mode();
    result = spawn_with_arguments();
    pop_shell_arguments();

save_result:
    spawn_frame()->result = result;

release_allocations:
    spawn_free(spawn_frame()->tail_heap);
    spawn_free(spawn_frame()->path_heap);
    spawn_free(spawn_frame()->environment_heap);
    restore_spawn_state(pointer_in_eax((char *)spawn_frame() - 0x2e));
    result = spawn_frame()->result;

done:
    return finish_spawn(result);
}
