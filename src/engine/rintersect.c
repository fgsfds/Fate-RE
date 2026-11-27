/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

extern long from_ax(void);
#pragma aux from_ax = value [eax] modify exact [];
extern void in_ax(long value);
#pragma aux in_ax = "" parm [eax] modify exact [];
extern long from_bx(void);
#pragma aux from_bx = value [ebx] modify exact [];
extern void in_bx(long value);
#pragma aux in_bx = "" parm [ebx] modify exact [];
extern long from_cx(void);
#pragma aux from_cx = value [ecx] modify exact [];
extern void in_cx(long value);
#pragma aux in_cx = "" parm [ecx] modify exact [];
extern long from_dx(void);
#pragma aux from_dx = value [edx] modify exact [];
extern void in_dx(long value);
#pragma aux in_dx = "" parm [edx] modify exact [];
extern long from_si(void);
#pragma aux from_si = value [esi] modify exact [];
extern long from_bp(void);
#pragma aux from_bp = value [ebp] modify exact [];

/* Save the origin and preserve the frame consumed by the shared return. */
extern void begin_ray_intersection(long x1, long y1, long z1, long dx);
#pragma aux begin_ray_intersection = "push esi" "push edi" "push ebp" "sub esp,20" \
    "mov edi,eax" "mov [esp+16],edx" "mov [esp],ebx" "mov esi,ecx" \
    parm [eax] [edx] [ebx] [ecx] modify exact [esi edi];
/* With A = ray direction, B = wall start - wall end, and C = wall start - origin,
 * leave A x B in EAX, C x B in EDX, and A x C in ECX.
 */

extern void load_wall_y_endpoints(void);
#pragma aux load_wall_y_endpoints = "mov ecx,[esp+48]" "mov ebx,[esp+56]" modify exact [ebx ecx];
extern void load_wall_x_span(void);
#pragma aux load_wall_x_span = "mov ebp,[esp+44]" "sub ebp,[esp+52]" modify exact [];
extern void load_ray_y_span(void);
#pragma aux load_ray_y_span = "mov edx,[esp+36]" modify exact [edx];
extern void load_ray_y_origin(void);
#pragma aux load_ray_y_origin = "mov ebx,[esp+16]" modify exact [ebx];
extern void read_wall_start_y(void);
#pragma aux read_wall_start_y = "mov edx,[esp+48]" modify exact [edx];
extern void save_wall_ray_y(void);
#pragma aux save_wall_ray_y = "mov [esp+12],edx" modify exact [];
extern long calculate_ray_numerators(void);
#pragma aux calculate_ray_numerators = \
    "mov edx,[esp+44]" "mov ebx,[esp+36]" "sub edx,edi" "imul ebx,edx" "imul edx,ecx" "mov [esp+8],ebx" \
    "mov ebx,[esp+12]" "imul ebx,esi" "mov [esp+4],ebx" "imul ebp,[esp+12]" \
    "mov ecx,[esp+4]" "mov ebx,[esp+8]" "sub edx,ebp" "sub ecx,ebx" \
    value [eax] modify exact [ebx ecx edx];
extern long save_ray_numerator(void);
#pragma aux save_ray_numerator = "mov ebp,edx" value [edx] modify exact [];
extern long segment_numerator(void);
#pragma aux segment_numerator = value [ecx] modify exact [];
extern long ray_denominator(void);
#pragma aux ray_denominator = value [eax] modify exact [];
extern long ray_distance_16(long denominator);
#pragma aux ray_distance_16 = "mov ebx,eax" "mov eax,ebp" "mov edx,eax" \
    "sar edx,16" "shl eax,16" "idiv ebx" "mov ebx,eax" \
    parm [eax] value [ebx] modify exact [eax ebx edx];
extern long ray_mulscale16(long delta, long distance);
#pragma aux ray_mulscale16 = "imul ebx" "shrd eax,edx,16" \
    parm [eax] [ebx] value [eax] modify exact [eax edx];
extern long ray_delta_x(void);
#pragma aux ray_delta_x = value [esi] modify exact [];
extern long ray_delta_y(void);
#pragma aux ray_delta_y = "mov eax,[esp+36]" value [eax] modify exact [eax];
extern long ray_delta_z(void);
#pragma aux ray_delta_z = "mov eax,[esp+40]" value [eax] modify exact [eax];
extern long ray_origin_x(void);
#pragma aux ray_origin_x = value [edi] modify exact [];
extern long ray_origin_y(void);
#pragma aux ray_origin_y = "mov edx,[esp+16]" value [edx] modify exact [edx];
extern long ray_origin_z(void);
#pragma aux ray_origin_z = "mov edx,[esp]" value [edx] modify exact [edx];
extern long ray_projected_x(long coordinate);
#pragma aux ray_projected_x = "" parm [edi] value [edi] modify exact [];
extern long ray_projected_yz(long coordinate);
#pragma aux ray_projected_yz = "" parm [edx] value [edx] modify exact [];
extern long *ray_result_x(void);
#pragma aux ray_result_x = "mov eax,[esp+60]" value [eax] modify exact [eax];
extern long *ray_result_y(void);
#pragma aux ray_result_y = "mov eax,[esp+64]" value [eax] modify exact [eax];
extern long *ray_result_z(void);
#pragma aux ray_result_z = "mov eax,[esp+68]" value [eax] modify exact [eax];
extern void drop_ray_locals(void);
#pragma aux drop_ray_locals = "add esp,20" modify exact [];
extern int finish_rintersect(long result);
#pragma aux finish_rintersect aborts parm [eax] modify exact [eax];
#pragma aux rintersect modify exact [eax ebx ecx edx esi edi];

int rintersect(long x1, long y1, long z1, long dx, long dy, long dz,
               long x2, long y2, long x3, long y3, long *xout, long *yout, long *zout)
{
    long denominator, distance, offset, coordinate;

    begin_ray_intersection(x1, y1, z1, dx);

    /* Form the determinant and wall-to-ray Y offset in 32-bit arithmetic. */
    load_wall_y_endpoints();
    in_ax(from_si());
    in_cx((unsigned long)from_cx() - (unsigned long)from_bx());
    in_ax((unsigned long)from_ax() * (unsigned long)from_cx());
    load_wall_x_span();
    load_ray_y_span();
    in_dx((unsigned long)from_dx() * (unsigned long)from_bp());
    load_ray_y_origin();
    in_ax((unsigned long)from_ax() - (unsigned long)from_dx());
    read_wall_start_y();
    in_dx((unsigned long)from_dx() - (unsigned long)from_bx());
    save_wall_ray_y();
    denominator = calculate_ray_numerators();
    /* The ray starts at zero. The wall includes its start and excludes its end. */
    if (denominator < 0)
        goto negative;
    if (denominator == 0)
        goto done;
    if (save_ray_numerator() >= 0)
        goto positive_segment;
miss:
    in_ax(0);
    goto done;
positive_segment:
    if (segment_numerator() < 0)
        goto miss;
    if (segment_numerator() < ray_denominator())
        goto intersection;
    goto miss;
negative:
    if (save_ray_numerator() > 0 || segment_numerator() > 0 ||
        segment_numerator() <= ray_denominator())
        goto miss;
intersection:
    /* Project each coordinate with the same signed 16.16 ray distance. */
    distance = ray_distance_16(ray_denominator());
    offset = ray_mulscale16(ray_delta_x(), distance);
    coordinate = ray_projected_x(ray_origin_x() + offset);
    *ray_result_x() = coordinate;
    offset = ray_mulscale16(ray_delta_y(), distance);
    coordinate = ray_projected_yz(ray_origin_y() + offset);
    *ray_result_y() = coordinate;
    offset = ray_mulscale16(ray_delta_z(), distance);
    coordinate = ray_projected_yz(ray_origin_z() + offset);
    *ray_result_z() = coordinate;
    in_ax(1);
done:
    drop_ray_locals();
    return finish_rintersect(ray_denominator());
}
