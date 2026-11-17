/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
/* Fate uses an older 2,048-entry Newton/correction table. The pinned
 * vanilla_duke3D ENGINE.C:2779-2790 instead builds 4,096 msqrtasm entries;
 * do not replace this version's algorithm with that newer implementation. */
extern unsigned sqrt_number_in_esi(void);
#pragma aux sqrt_number_in_esi = value [esi] modify exact [];
extern unsigned sqrt_prior_in_ebx(unsigned root);
#pragma aux sqrt_prior_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern unsigned sqrt_next_in_ecx(unsigned root);
#pragma aux sqrt_next_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern unsigned sqrt_change_in_eax(unsigned delta);
#pragma aux sqrt_change_in_eax = "" parm [eax] value [eax] modify exact [];
extern unsigned sqrt_current_index(void);
#pragma aux sqrt_current_index = value [edi] modify exact [];
extern unsigned short sqrtable[];
extern void finish_sqrt_table(void);
#pragma aux finish_sqrt_table "shared_graphics_epilogue_" aborts modify exact [eax];
extern unsigned sqrt_number_set(unsigned);
#pragma aux sqrt_number_set = "" parm [esi] value [esi] modify exact [];
extern long abs_sqrt_error(long value);
#pragma aux abs_sqrt_error = "test eax,eax" "jns error_is_positive" "neg eax" "error_is_positive:" parm [eax] value [eax] modify exact [eax];
extern long lower_sqrt_error_in_esi(long value);
#pragma aux lower_sqrt_error_in_esi = "" parm [esi] value [esi] modify exact [];
extern long upper_sqrt_error_in_edx(long value);
#pragma aux upper_sqrt_error_in_edx = "" parm [edx] value [edx] modify exact [];
extern long current_sqrt_error(void);
#pragma aux current_sqrt_error = value [ebx] modify exact [];
extern long sqrt_root(void);
#pragma aux sqrt_root = value [ecx] modify exact [];
extern long sqrt_root_in_ecx(long root);
#pragma aux sqrt_root_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern long sqrt_error_in_ebx(long error);
#pragma aux sqrt_error_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern long sqrt_delta_in_edx(void);
#pragma aux sqrt_delta_in_edx = "" value [edx] modify exact [];
extern long sqrt_delta_in_eax(long);
#pragma aux sqrt_delta_in_eax = "" parm [eax] value [eax] modify exact [];
extern long sqrt_eax(void);
#pragma aux sqrt_eax = "" value [eax] modify exact [];
/* Conservatively end ECX's compiler lifetime here so DEC ECX cannot move
 * before INC EAX. The empty constraint emits no instructions. */
extern long finish_lower_delta(long);
#pragma aux finish_lower_delta = "" parm [eax] value [eax] modify exact [ecx];
extern long upper_sqrt_delta(void);
#pragma aux upper_sqrt_delta = "lea eax,[ebx+esi*1+1]" value [eax] modify exact [eax];
extern unsigned initial_sqrt_index(unsigned index);
#pragma aux initial_sqrt_index = "" parm [edi] value [edi] modify exact [];
extern unsigned short sqrt_result(void);
#pragma aux sqrt_result = value [cx] modify exact [];

void initksqrt(void)
{
    unsigned int quotient, previous, next;
    long error, delta;

    initial_sqrt_index(0);
    goto check_index;
    do {
        /* Seed the Newton iteration for the current index scaled by 2^20. */
        sqrt_number_set(sqrt_current_index());
        sqrt_root_in_ecx(128);
        sqrt_number_set(sqrt_number_in_esi() << 20);
        do {
            quotient = sqrt_change_in_eax(sqrt_number_in_esi() / (unsigned)sqrt_root());
            previous = sqrt_prior_in_ebx(sqrt_root());
            next = sqrt_next_in_ecx((sqrt_root() + quotient) >> 1);
        } while (sqrt_change_in_eax(previous - next + 1) > 2U);
        /* Correct the integer estimate to minimize the squared error. */
        sqrt_error_in_ebx(sqrt_prior_in_ebx(sqrt_root()) * sqrt_root() - sqrt_number_in_esi());
        do {
            error = current_sqrt_error();
            delta = upper_sqrt_error_in_edx(sqrt_root() * 2);
            if (lower_sqrt_error_in_esi(abs_sqrt_error(error - delta + 1)) >= abs_sqrt_error(current_sqrt_error()))
                break;
            sqrt_delta_in_eax(sqrt_delta_in_edx());
            sqrt_delta_in_eax(-sqrt_eax());
            delta = finish_lower_delta(sqrt_eax() + 1);
            sqrt_root_in_ecx(sqrt_root() - 1);
            sqrt_error_in_ebx(current_sqrt_error() + delta);
        } while (1);
        do {
            /* Across all 2048 indices, root is 0..46330 here; doubling fits long. */
            sqrt_number_set(sqrt_root() * 2);
            if (upper_sqrt_error_in_edx(abs_sqrt_error(upper_sqrt_delta())) >= abs_sqrt_error(current_sqrt_error()))
                break;
            delta = lower_sqrt_error_in_esi(sqrt_number_in_esi() + 1);
            sqrt_root_in_ecx(sqrt_root() + 1);
            sqrt_error_in_ebx(current_sqrt_error() + delta);
        } while (1);
        initial_sqrt_index(sqrt_current_index() + 1);
        sqrtable[sqrt_current_index() - 1] = sqrt_result();
    check_index:
        ;
    } while (sqrt_current_index() < 2048);
    finish_sqrt_table();
}
