// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release.
/* PCX geometry fields. Select the two checked branches while retaining the
 * original short join jump and the caller's existing stack frame. */
extern long presentation_width, presentation_height, qsetmode;
extern unsigned char pcx_header[];

void capture_header(void)
{
    if (qsetmode == 200) {
        pcx_header[8] = (presentation_width - 1) & 255;
        pcx_header[9] = ((presentation_width - 1) >> 8) & 255;
        pcx_header[10] = (presentation_height - 1) & 255;
        pcx_header[11] = ((presentation_height - 1) >> 8) & 255;
        pcx_header[12] = presentation_width & 255;
        pcx_header[13] = (presentation_width >> 8) & 255;
        pcx_header[14] = presentation_height & 255;
        pcx_header[15] = (presentation_height >> 8) & 255;
        pcx_header[66] = pcx_header[12];
        pcx_header[67] = pcx_header[13];
    } else {
        pcx_header[8] = (640 - 1) & 255;
        pcx_header[10] = (qsetmode - 1) & 255;
        pcx_header[9] = (640 - 1) >> 8;
        pcx_header[11] = ((qsetmode - 1) >> 8) & 255;
        pcx_header[12] = 640 & 255;
        pcx_header[14] = qsetmode & 255;
        pcx_header[13] = 640 >> 8;
        pcx_header[66] = 640 & 255;
        pcx_header[67] = 640 >> 8;
        pcx_header[15] = (qsetmode >> 8) & 255;
    }
}
