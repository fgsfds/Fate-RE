/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

/* Accept the register and stacked arguments used by the shared return frame. */
extern void begin_intersection(long x1, long y1, long z1, long x2);
#pragma aux begin_intersection = "push esi" "push edi" "push ebp" "sub esp,24" \
    "push eax" "mov esi,edx" "mov [esp+20],ebx" "mov ebx,[esp+60]" "mov ebp,[esp+44]" \
    "mov edi,ecx" "mov ecx,[esp+64]" "sub edi,eax" "sub ebp,edx" \
    "mov eax,[esp+52]" "mov edx,[esp+56]" "sub eax,ebx" "sub edx,ecx" \
    parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx esi edi];
/* With A = end1 - start1, B = start2 - end2, and C = start2 - start1,
 * leave A x B in EBX, C x B in EAX, and A x C in ECX.
 */
extern long calculate_cross_products(void);
#pragma aux calculate_cross_products = "mov ebx,edi" "imul ebx,edx" "mov [esp+24],eax" \
    "imul eax,ebp" "sub ebx,eax" "mov eax,[esp+56]" "sub eax,esi" \
    "mov ecx,[esp]" "mov [esp+16],eax" "mov eax,[esp+52]" "sub eax,ecx" \
    "mov ecx,ebp" "imul ecx,eax" "imul eax,edx" "mov [esp+4],ecx" \
    "mov ecx,[esp+16]" "imul ecx,edi" "mov [esp+12],ecx" "mov ecx,[esp+16]" \
    "imul ecx,[esp+24]" "mov edx,[esp+4]" "mov [esp+8],ecx" "mov ecx,[esp+12]" \
    "sub ecx,edx" "sub eax,[esp+8]" value [ebx] modify exact [eax ebx ecx edx];
extern long preserve_first_parameter(void);
#pragma aux preserve_first_parameter = "mov edx,eax" value [eax] modify exact [edx];
extern long second_parameter(void);
#pragma aux second_parameter = value [ecx] modify exact [];
extern long first_parameter_in_edx(void);
#pragma aux first_parameter_in_edx = value [edx] modify exact [];
extern long determinant_in_ebx(void);
#pragma aux determinant_in_ebx = value [ebx] modify exact [];
extern long divscale24(long numerator, long denominator);
#pragma aux divscale24 = "mov edx,eax" "sar edx,8" "shl eax,24" "idiv ebx" \
    parm [eax] [ebx] value [eax] modify exact [eax edx];
extern long hold_projection_fraction(long fraction);
#pragma aux hold_projection_fraction = "mov ecx,eax" "mov ebx,eax" parm [eax] value [ebx] modify exact [ebx ecx];
extern long first_segment_dx(void);
#pragma aux first_segment_dx = value [edi] modify exact [];
extern long first_segment_dy(void);
#pragma aux first_segment_dy = value [ebp] modify exact [];
extern long first_segment_dz(void);
#pragma aux first_segment_dz = "mov eax,[esp+48]" "sub eax,ebx" value [eax] modify exact [eax];
extern long mulscale24(long delta, long fraction);
#pragma aux mulscale24 = "imul ebx" "shrd eax,edx,24" parm [eax] [ebx] value [eax] modify exact [eax edx];
extern long segment_base_x(void);
#pragma aux segment_base_x = "mov edx,[esp]" value [edx] modify exact [edx];
extern long segment_base_y(void);
#pragma aux segment_base_y = value [esi] modify exact [];
extern long segment_base_z(void);
#pragma aux segment_base_z = "mov edx,[esp+20]" value [edx] modify exact [edx];
extern long projected_x(long coordinate);
#pragma aux projected_x = "" parm [edx] value [edx] modify exact [];
extern long projected_y(long coordinate);
#pragma aux projected_y = "" parm [esi] value [esi] modify exact [];
extern long projected_z(long coordinate);
#pragma aux projected_z = "" parm [edx] value [edx] modify exact [];
extern long *intersection_x(void);
#pragma aux intersection_x = "mov eax,[esp+68]" value [eax] modify exact [eax];
extern long *intersection_y(void);
#pragma aux intersection_y = "mov eax,[esp+72]" value [eax] modify exact [eax];
extern long *intersection_z(void);
#pragma aux intersection_z = "mov eax,[esp+76]" value [eax] modify exact [eax];
extern void load_first_z(void);
#pragma aux load_first_z = "mov ebx,[esp+20]" modify exact [ebx];
extern long project_segment_z(long delta);
#pragma aux project_segment_z = "mov ebx,ecx" "imul ebx" "shrd eax,edx,24" \
    parm [eax] value [eax] modify exact [eax ebx edx];
extern long finish_lintersect(int hit);
#pragma aux finish_lintersect aborts parm [eax] modify exact [eax];
extern void drop_crossing_locals(void);
#pragma aux drop_crossing_locals = "add esp,28" modify exact [];
#pragma aux lintersect modify exact [eax ebx ecx edx esi edi];

int lintersect(long x1, long y1, long z1, long x2, long y2, long z2,
               long x3, long y3, long x4, long y4, long *xout, long *yout, long *zout)
{
    long denominator, first, fraction, offset, coordinate;
    long *destination;
    int hit;

    begin_intersection(x1, y1, z1, x2);
    denominator = calculate_cross_products();
    /* Both fractions must fall in the half-open interval [0, 1). */
    if (denominator < 0)
        goto negative;
    if (denominator != 0)
        goto positive;
miss:
    hit = 0;
    goto done;
positive:
    first = preserve_first_parameter();
    if (first < 0 || first >= determinant_in_ebx() ||
        second_parameter() < 0)
        goto miss;
    if (second_parameter() < determinant_in_ebx())
        goto project;
    goto miss;
negative:
    first = preserve_first_parameter();
    if (first > 0 || first <= determinant_in_ebx() ||
        second_parameter() > 0 || second_parameter() <= determinant_in_ebx())
        goto miss;
project:
    /* Use the first fraction in signed 8.24 fixed point for all three axes. */
    fraction = hold_projection_fraction(divscale24(first_parameter_in_edx(), determinant_in_ebx()));
    offset = mulscale24(first_segment_dx(), fraction);
    coordinate = projected_x(segment_base_x() + offset);
    *intersection_x() = coordinate;
    offset = mulscale24(first_segment_dy(), fraction);
    coordinate = projected_y(segment_base_y() + offset);
    destination = intersection_y();
    load_first_z();
    *destination = coordinate;
    offset = project_segment_z(first_segment_dz());
    coordinate = projected_z(segment_base_z() + offset);
    *intersection_z() = coordinate;
    hit = 1;
done:
    drop_crossing_locals();
    return finish_lintersect(hit);
}
