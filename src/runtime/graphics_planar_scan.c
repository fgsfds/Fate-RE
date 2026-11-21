/* Scan the two-plane left entry: set the mask count and jump into the scan. */
extern void scan_two_planes_left_body(void);
#pragma aux scan_two_planes_left_body = 0xb1 0x05 0xeb 0x02 modify exact [];
void scan_two_planes_left(void);
#pragma aux scan_two_planes_left aborts modify exact [];
void scan_two_planes_left(void)
{
    scan_two_planes_left_body();
}

/* Scan the two-plane right entry: set the mask count and jump into the scan. */
extern void scan_two_planes_right_body(void);
#pragma aux scan_two_planes_right_body = 0xb1 0x05 0xeb 0x02 modify exact [];
void scan_two_planes_right(void);
#pragma aux scan_two_planes_right aborts modify exact [];
void scan_two_planes_right(void)
{
    scan_two_planes_right_body();
}
