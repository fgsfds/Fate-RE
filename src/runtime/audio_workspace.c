/* Allocate and lock audio workspace or delegate to caller-provided hooks. */

extern int lock_memory_region(unsigned long, unsigned);
#pragma aux lock_memory_region parm caller [] modify exact [eax];

extern int unlock_memory_region(unsigned long,unsigned);
#pragma aux unlock_memory_region parm caller [] modify exact [eax];

/* In these unoptimized routines, listing GS suppresses Watcom's unused GS save. */

typedef void *allocate_hook_type(unsigned);
#pragma aux allocate_hook_type parm [eax] value [eax] modify exact [eax];
typedef void release_hook_type(void *, unsigned);
#pragma aux release_hook_type parm [eax] [edx] modify exact [eax edx];
extern allocate_hook_type *workspace_allocate_hook;
extern release_hook_type *workspace_release_hook;
extern void *workspace_malloc(unsigned);
#pragma aux workspace_malloc "malloc_" parm [eax] modify exact [eax];
extern void workspace_free(void *);
#pragma aux workspace_free "free_" parm [eax] modify exact [eax];

void *allocate_driver_workspace(unsigned);
#pragma aux allocate_driver_workspace parm [eax] modify exact [eax gs];
void *allocate_driver_workspace(unsigned bytes)
{
    void *buffer;
    if (workspace_allocate_hook)
        return workspace_allocate_hook(bytes);
    buffer = workspace_malloc(bytes);
    if (buffer != 0) {
        if (lock_memory_region((unsigned long)buffer, bytes))
            return 0;
    }
    return buffer;
}

void release_driver_workspace(void *, unsigned);
#pragma aux release_driver_workspace parm [eax] [edx] modify exact [eax edx gs];
void release_driver_workspace(void *buffer, unsigned bytes)
{
    if (workspace_allocate_hook) {
        workspace_release_hook(buffer, bytes);
    } else {
        unlock_memory_region((unsigned long)buffer, bytes);
        workspace_free(buffer);
    }
}

void set_workspace_allocate_hook(allocate_hook_type *);
#pragma aux set_workspace_allocate_hook parm [eax] modify exact [eax gs];
void set_workspace_allocate_hook(allocate_hook_type *hook)
{
    workspace_allocate_hook = hook;
}

void set_workspace_release_hook(release_hook_type *);
#pragma aux set_workspace_release_hook parm [eax] modify exact [eax gs];
void set_workspace_release_hook(release_hook_type *hook)
{
    workspace_release_hook = hook;
}
