/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

extern int rotation_angle_from_stack(void);
#pragma aux rotation_angle_from_stack = "movsx esi,word ptr [esp+1ch]" value [esi] modify exact [esi];
extern int prepare_cosine_lookup(int index);
#pragma aux prepare_cosine_lookup = "mov edx,dword ptr [esp+4]" "mov ebx,dword ptr [esp]" parm [eax] value [eax] modify exact [edx ebx];
extern int active_rotation_angle(void);
#pragma aux active_rotation_angle = value [esi] modify exact [];
extern int form_rotation_y_delta(int index);
#pragma aux form_rotation_y_delta = "sub ecx,ebx" parm [eax] value [eax] modify exact [ecx];
extern int prepare_sine_lookup(int index);
#pragma aux prepare_sine_lookup = "mov ebx,dword ptr [esp+8]" "mov esi,ecx" parm [eax] value [eax] modify exact [ebx esi];
extern void prepare_rotation_y(void);
extern long rotation_delta_y(void);
#pragma aux rotation_delta_y = value [eax] modify exact [];
#pragma aux prepare_rotation_y = "mov esi,ebp" "mov eax,ecx" "mov ecx,dword ptr [esp]" modify exact [eax ecx esi];
extern short sintable[];
/* The original entry saves this frame for a shared epilogue. */
extern void begin_point_rotation(long pivot_x, long pivot_y, long x);
#pragma aux begin_point_rotation = "push esi" "push edi" "push ebp" "sub esp,4" "push eax" "push edx" "mov ebp,ebx" parm [eax] [edx] [ebx] modify exact [];
#pragma aux rotatepoint modify exact [eax ebx ecx edx esi edi];
extern void hold_rotation_cosine(long cosine);
#pragma aux hold_rotation_cosine = "sub ebp,edx" "mov dword ptr [esp+8],eax" parm [eax] modify exact [];
extern void hold_rotation_sine(long sine);
#pragma aux hold_rotation_sine = "neg esi" "mov edi,eax" parm [eax] modify exact [esi edi];
extern long rotation_delta_x(void);
#pragma aux rotation_delta_x = value [ebp] modify exact [];
extern long rotation_y_pivot(void);
#pragma aux rotation_y_pivot = value [ecx] modify exact [];
extern long rotation_cosine(void);
#pragma aux rotation_cosine = value [ebx] modify exact [];
extern long rotation_sine(void);
#pragma aux rotation_sine = value [edi] modify exact [];
extern long rotation_second_delta(void);
#pragma aux rotation_second_delta = value [esi] modify exact [];
/* Add two signed products before shifting the full sum from 14-bit fixed point. */
extern long rotation_dot(long a, long cosine, long b, long sine);
#pragma aux rotation_dot = "imul ebx" "xchg eax,esi" "mov ebx,edx" "imul edi" "add eax,esi" "adc edx,ebx" "shrd eax,edx,14" parm [eax] [ebx] [esi] [edi] value [eax] modify exact [eax ebx edx esi];
extern long rotation_pivot_x(void);
#pragma aux rotation_pivot_x = "mov esi,dword ptr [esp+4]" value [esi] modify exact [esi];
extern long *rotation_out_x(void);
#pragma aux rotation_out_x = "mov eax,dword ptr [esp+20h]" value [eax] modify exact [eax];
extern long *rotation_out_y(void);
#pragma aux rotation_out_y = "mov eax,dword ptr [esp+24h]" value [eax] modify exact [eax];
extern void reload_rotation_cosine(void);
#pragma aux reload_rotation_cosine = "mov ebx,dword ptr [esp+8]" modify exact [ebx];
extern long rotation_x_in_esi(long x);
#pragma aux rotation_x_in_esi = "" parm [esi] value [esi] modify exact [];
extern long rotation_y_in_ecx(long y);
#pragma aux rotation_y_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern void finish_rotation(void);
#pragma aux finish_rotation aborts modify exact [eax];

void rotatepoint(long pivot_x, long pivot_y, long x, long y, short angle,
                 long *out_x, long *out_y)
{
    long cosine, sine, offset;
    long rotated_x, rotated_y;
    long *destination;

    begin_point_rotation(pivot_x, pivot_y, x);
    cosine = sintable[prepare_cosine_lookup((rotation_angle_from_stack() + 0xa00) & 0x7ff)];
    hold_rotation_cosine(cosine);
    sine = sintable[prepare_sine_lookup(form_rotation_y_delta(active_rotation_angle() + 0x800) & 0x7ff)];
    hold_rotation_sine(sine);
    /* Project onto X with dx * cos - dy * sin. */
    offset = rotation_dot(rotation_delta_x(), rotation_cosine(), rotation_second_delta(), rotation_sine());
    rotated_x = rotation_x_in_esi(rotation_pivot_x() + offset);
    destination = rotation_out_x();
    reload_rotation_cosine();
    *destination = rotated_x;

    /* Project onto Y with dy * cos + dx * sin. */
    prepare_rotation_y();
    offset = rotation_dot(rotation_delta_y(), rotation_cosine(), rotation_second_delta(), rotation_sine());
    rotated_y = rotation_y_in_ecx(rotation_y_pivot() + offset);
    *rotation_out_y() = rotated_y;
    finish_rotation();
}
