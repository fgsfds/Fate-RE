/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

/* Save the origin and preserve the frame consumed by the shared return. */
extern void begin_ray_intersection(long x1, long y1, long z1, long dx);
#pragma aux begin_ray_intersection = "push esi" "push edi" "push ebp" "sub esp,20" \
    "mov edi,eax" "mov [esp+16],edx" "mov [esp],ebx" "mov esi,ecx" \
    parm [eax] [edx] [ebx] [ecx] modify exact [esi edi];
/* With A = ray direction, B = wall start - wall end, and C = wall start - origin,
 * leave A x B in EAX, C x B in EDX, and A x C in ECX.
 */
extern long ray_cross_products(void);
#pragma aux ray_cross_products = "mov ecx,[esp+48]" "mov ebx,[esp+56]" "mov eax,esi" \
    "sub ecx,ebx" "imul eax,ecx" "mov ebp,[esp+44]" "sub ebp,[esp+52]" \
    "mov edx,[esp+36]" "imul edx,ebp" "mov ebx,[esp+16]" "sub eax,edx" \
    "mov edx,[esp+48]" "sub edx,ebx" "mov [esp+12],edx" "mov edx,[esp+44]" \
    "mov ebx,[esp+36]" "sub edx,edi" "imul ebx,edx" "imul edx,ecx" "mov [esp+8],ebx" \
    "mov ebx,[esp+12]" "imul ebx,esi" "mov [esp+4],ebx" "imul ebp,[esp+12]" \
    "mov ecx,[esp+4]" "mov ebx,[esp+8]" "sub edx,ebp" "sub ecx,ebx" \
    value [eax] modify exact [eax ebx ecx edx];
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
extern void set_ray_miss(void);
#pragma aux set_ray_miss = "xor eax,eax" modify exact [eax];
extern void set_ray_hit(void);
#pragma aux set_ray_hit = "mov eax,1" modify exact [eax];
extern int finish_rintersect(long result);
#pragma aux finish_rintersect aborts parm [eax] modify exact [eax];
#pragma aux rintersect modify exact [eax ebx ecx edx esi edi];

int rintersect(long x1, long y1, long z1, long dx, long dy, long dz,
               long x2, long y2, long x3, long y3, long *xout, long *yout, long *zout)
{
    long denominator, distance, offset, coordinate;

    begin_ray_intersection(x1, y1, z1, dx);
    denominator = ray_cross_products();
    /* The ray starts at zero. The wall includes its start and excludes its end. */
    if (denominator < 0)
        goto negative;
    if (denominator == 0)
        goto done;
    if (save_ray_numerator() >= 0)
        goto positive_segment;
miss:
    set_ray_miss();
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
    set_ray_hit();
done:
    drop_ray_locals();
    return finish_rintersect(ray_denominator());
}
