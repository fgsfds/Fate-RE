/* Build the DOS environment block and measure the child command tail. */
/* Bind C sizing and cursor updates to the DOS runtime registers. */
extern void size_to_ebx(unsigned);
#pragma aux size_to_ebx = "" parm [ebx] modify exact [];
extern void entry_to_edx(const char **);
#pragma aux entry_to_edx = "" parm [edx] modify exact [];
extern unsigned environment_size(void);
#pragma aux environment_size = "" value [ebx] modify exact [];
extern void copy_to_ecx(const char **);
#pragma aux copy_to_ecx = "" parm [ecx] modify exact [];
extern void env_to_eax(char *);
#pragma aux env_to_eax = "" parm [eax] modify exact [];
extern void tail_to_edx(unsigned);
#pragma aux tail_to_edx = "" parm [edx] modify exact [];
extern void argv_to_esi(const char **);
#pragma aux argv_to_esi = "" parm [esi] modify exact [];
extern const char *entry_to_eax(const char *);
#pragma aux entry_to_eax = "" parm [eax] value [eax] modify exact [];
extern unsigned size_in_eax(unsigned);
#pragma aux size_in_eax = "" parm [eax] value [eax] modify exact [];
extern void size_to_eax(unsigned);
#pragma aux size_to_eax = "" parm [eax] modify exact [];
extern unsigned argument_length(void);
#pragma aux argument_length = "" value [eax] modify exact [];

extern void *allocation_in_eax(void *);
#pragma aux allocation_in_eax = "" parm [eax] value [eax] modify exact [];
extern void *current_allocation(void);
#pragma aux current_allocation = "" value [eax] modify exact [];

extern const char **environment_vector;
extern unsigned minimum_heap_growth;

extern unsigned entry_length(const char *);
#pragma aux entry_length "strlen_" parm [eax] modify exact [eax];
extern void *allocate_environment(unsigned);
#pragma aux allocate_environment "malloc_" parm [eax] modify exact [eax];
extern void release_environment(void *);
#pragma aux release_environment "free_" parm [eax] modify exact [eax];
extern void set_errno(int);
#pragma aux set_errno parm [eax] modify exact [eax];
extern void set_runtime_error(int);
#pragma aux set_runtime_error parm [eax] modify exact [eax];
extern char *copy_c_string(char *, const char *);
#pragma aux copy_c_string parm [eax] [edx] modify exact [eax edx];
extern char *strcpy(char *, const char *);
#pragma aux strcpy parm [eax] [edx] modify exact [eax edx];

extern void begin_environment(void);
#pragma aux begin_environment = "push esi" "push edi" "enter 8,0" modify exact [esi edi];
extern const char **incoming_arguments(void);
#pragma aux incoming_arguments = "" value [eax] modify exact [];
extern void **incoming_heap_slot(void);
#pragma aux incoming_heap_slot = "" value [ebx] modify exact [];
extern const char **provided_environment(void);
#pragma aux provided_environment = value [edx] modify exact [];
extern void use_environment(const char **);
#pragma aux use_environment = "" parm [edi] modify exact [];
extern const char **environment_entries(void);
#pragma aux environment_entries = value [edi] modify exact [];
extern const char **entry_cursor(void);
#pragma aux entry_cursor = value [edx] modify exact [];
extern const char **program_arguments(void);
#pragma aux program_arguments = value [esi] modify exact [];

extern unsigned first_allocation_size(void);
#pragma aux first_allocation_size = value [eax] modify exact [];
extern void **environment_offset(void);
#pragma aux environment_offset = value [ecx] modify exact [];
extern const char **copy_cursor(void);
#pragma aux copy_cursor = value [ecx] modify exact [];
extern char *environment_end(void);
#pragma aux environment_end = value [eax] modify exact [];

extern unsigned tail_length(void);
#pragma aux tail_length = value [edx] modify exact [];
extern const char *argument_in_eax(void);
#pragma aux argument_in_eax = value [eax] modify exact [];
extern int finish_environment(int);
#pragma aux finish_environment = "leave" "pop edi" "pop esi" parm [eax] value [eax] modify exact [esi edi];

/* Address the stack arguments through the original ENTER frame. */
typedef struct {
    unsigned char saved[0x10];
    unsigned *selector;
    unsigned *tail_allocation;
    int append_program;
} EnvironmentFrame;
typedef struct {
    unsigned heap_unit;
    void **heap_slot;
} EnvironmentLocals;
extern const EnvironmentFrame *environment_frame(void);
#pragma aux environment_frame = value [ebp] modify exact [];
#define ENVIRONMENT_LOCAL(member) (((EnvironmentLocals *)environment_frame())[-1].member)

int build_child_environment(const char **, const char **, void **, void **, unsigned *, unsigned *, int);
#pragma aux build_child_environment modify exact [eax ebx ecx edx esi edi];
int build_child_environment(const char **argv, const char **env, void **heap_block,
                            void **offset, unsigned *selector, unsigned *tail_allocation, int include_name)
{
    void *allocated;
    const char *entry;
    unsigned size;
    unsigned alignment;
    void **heap_slot;
    int result;

    begin_environment();
    argv_to_esi(incoming_arguments());
    use_environment(provided_environment());
    ENVIRONMENT_LOCAL(heap_slot) = incoming_heap_slot();
    if (!provided_environment())
        use_environment(environment_vector);
    size_to_ebx(0);
    if (environment_entries()) {
        entry_to_edx(environment_entries());
        goto check_environment;
        do {
            size_to_eax(entry_length(*entry_cursor()) + 1);
            entry_to_edx(entry_cursor() + 1);
            size_to_ebx(environment_size() + argument_length());
check_environment:;
        } while (*entry_cursor());
    }
    size_to_ebx(environment_size() + 1);
    if (environment_frame()->append_program) {
        size_to_eax(entry_length(*program_arguments()) + 3);
        size_to_ebx(environment_size() + argument_length());
    }

    alignment = minimum_heap_growth;
    size_to_ebx(environment_size() + 15);
    ENVIRONMENT_LOCAL(heap_unit) = size_in_eax(alignment);
    size_to_eax(environment_size());
    minimum_heap_growth = 16;
    allocated = allocation_in_eax(allocate_environment(first_allocation_size()));
    if (!allocated) {
        allocated = allocation_in_eax(allocate_environment(environment_size()));
        if (!allocated) {
            set_errno(5);
            set_runtime_error(8);
            minimum_heap_growth = ENVIRONMENT_LOCAL(heap_unit);
failure:
            result = -1;
            goto done;
        }
    }

    minimum_heap_growth = ENVIRONMENT_LOCAL(heap_unit);
    heap_slot = ENVIRONMENT_LOCAL(heap_slot);
    *heap_slot = current_allocation();
    *environment_frame()->selector = 0;
    *environment_offset() = current_allocation();
    if (environment_entries()) {
        copy_to_ecx(environment_entries());
        goto check_copy;
        do {
            env_to_eax(copy_c_string(environment_end(), *copy_cursor()) + 1);
            copy_to_ecx(copy_cursor() + 1);
check_copy:;
        } while (*copy_cursor());
    }
    *environment_end() = 0;
    env_to_eax(environment_end() + 1);
    if (environment_frame()->append_program) {
        env_to_eax(environment_end() + 1);
        env_to_eax(environment_end() + 1);
        strcpy(environment_end(), *program_arguments());
    }

    tail_to_edx(0);
    if (*program_arguments()) {
        argv_to_esi(program_arguments() + 1);
        goto check_argument;
        do {
            if (tail_length())
                tail_to_edx(tail_length() + 1);
            size = entry_length(argument_in_eax());
            argv_to_esi(program_arguments() + 1);
            tail_to_edx(tail_length() + size_in_eax(size));
check_argument:
            entry = entry_to_eax(*program_arguments());
        } while (entry);
    }
    if (tail_length() > 126) {
        set_errno(2);
        set_runtime_error(10);
        release_environment(*ENVIRONMENT_LOCAL(heap_slot));
        goto failure;
    }
    *environment_frame()->tail_allocation = 144;
    result = size_in_eax(environment_size() >> 4);

done:
    return finish_environment(result);
}
