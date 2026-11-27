// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release.
/* Historical Build drawmasks context. Only the verified projection prefix is linked;
 * the existing sort continuation consumes the compiler-created frame. */
#pragma pack(1)
typedef struct {
    long x, y, z;
    short cstat, picnum;
    signed char shade;
    char pal, clipdist, filler;
    unsigned char xrepeat, yrepeat;
    signed char xoffset, yoffset;
    short sectnum, statnum, ang, owner, xvel, yvel, zvel, lotag, hitag, extra;
} spritetype;
#pragma pack()
extern spritetype tsprite[], tempsprite;
extern long vidoption, spritesortcnt, globalposx, globalposy, globalposz;
extern long cosviewingrangeglobalang, sinviewingrangeglobalang;
extern long cosglobalang, singlobalang, xdimen;
extern long spritesx[], spritesy[], xb1[], xb2[];
extern short maskwall[], maskwallcnt, thewall[];
extern long spritewallfront(spritetype *, long);
extern void drawsprite(long), drawmaskwall(short);

#pragma aux dmulscale6 = \
    "imul ebx" "xchg esi, eax" "mov ebx, edx" "imul edi" \
    "add eax, esi" "adc edx, ebx" "shrd eax, edx, 6" \
    parm nomemory [eax][ebx][esi][edi] modify exact [eax ebx edx esi]
#pragma aux scale = "imul ebx" "idiv ecx" \
    parm nomemory [eax][ebx][ecx] modify exact [eax edx]
#pragma aux koutp = "out dx, al" parm [edx][eax] modify exact []
#pragma aux copybufbyte = \
    "test cl, 1" "jz skip1" "movsb" "skip1: shr ecx, 2" \
    "jnc skip2" "movsw" "skip2: rep movsd" \
    parm [esi][edi][ecx] modify exact [ecx esi edi]

drawmasks()
{
    long i, j, k, l, gap, xs, ys, zs, xp, yp, zp, z1, z2;
    spritetype *s1, *s2, *st;

    if (vidoption > 0) koutp(0x3c4,2);
    for(i=spritesortcnt-1;i>=0;i--)
    {
        xs = tsprite[i].x-globalposx; ys = tsprite[i].y-globalposy;
        yp = dmulscale6(xs,cosviewingrangeglobalang,ys,sinviewingrangeglobalang);
        if (yp > (4<<8))
        {
            xp = dmulscale6(ys,cosglobalang,-xs,singlobalang);
            spritesx[i] = scale(xp+yp,xdimen<<7,yp);
        }
        else if ((long)(tsprite[i].cstat&48) == 0)
        {
            spritesortcnt--;
            if (i != spritesortcnt)
            {
                copybufbyte(&tsprite[spritesortcnt],&tsprite[i],sizeof(spritetype));
                spritesx[i] = spritesx[spritesortcnt];
                spritesy[i] = spritesy[spritesortcnt];
            }
            continue;
        }
        spritesy[i] = yp;
    }

    st = &tempsprite;
    for(gap=spritesortcnt>>1;gap>0;gap>>=1)
        for(i=0;i<spritesortcnt-gap;i++)
            for(l=i;l>=0;l-=gap)
            {
                xp = spritesy[l]-spritesy[l+gap];
                if (xp < 0) break;
                s1 = &tsprite[l]; s2 = &tsprite[l+gap];
                if (xp == 0)
                {
                    xp = (long)s1->statnum-(long)s2->statnum;
                    if (xp < 0) break;
                    if (xp == 0)
                    {
                        if ((long)(s1->cstat&48) == 32)
                        {
                            z1 = s1->z-globalposz; z2 = s2->z-globalposz;
                            if ((long)(s2->cstat&48) != 32) z2 -= 256;
                            if ((z1 < 0) != (z1 < z2)) break;
                        }
                        else if ((long)(s2->cstat&48) == 32)
                        {
                            z1 = s1->z-globalposz-256; z2 = s2->z-globalposz;
                            if ((z2 < 0) == (z1 > z2)) break;
                        }
                    }
                }
                copybufbyte(s1,st,sizeof(spritetype));
                copybufbyte(s2,s1,sizeof(spritetype));
                copybufbyte(st,s2,sizeof(spritetype));
                k = spritesx[l]; spritesx[l] = spritesx[l+gap]; spritesx[l+gap] = k;
                k = spritesy[l]; spritesy[l] = spritesy[l+gap]; spritesy[l+gap] = k;
            }

    while ((spritesortcnt > 0) && (maskwallcnt > 0))
    {
        j = maskwall[maskwallcnt-1];
        if (spritewallfront(&tsprite[spritesortcnt-1],(long)thewall[j]) == 0)
            drawsprite(--spritesortcnt);
        else
        {
            k = -1;
            gap = 0;
            for(i=spritesortcnt-2;i>=0;i--)
                if ((xb1[j] <= (spritesx[i]>>8)) && ((spritesx[i]>>8) <= xb2[j]))
                    if (spritewallfront(&tsprite[i],(long)thewall[j]) == 0)
                    {
                        drawsprite(i);
                        tsprite[i].owner = -1;
                        k = i;
                        gap++;
                    }
            if (k >= 0)
            {
                for(i=k;i<spritesortcnt;i++)
                    if (tsprite[i].owner >= 0)
                    {
                        if (i > k)
                        {
                            copybufbyte(&tsprite[i],&tsprite[k],sizeof(spritetype));
                            spritesx[k] = spritesx[i];
                            spritesy[k] = spritesy[i];
                        }
                        k++;
                    }
                spritesortcnt -= gap;
            }
            drawmaskwall(--maskwallcnt);
        }
    }
    while (spritesortcnt > 0) drawsprite(--spritesortcnt);
    while (maskwallcnt > 0) drawmaskwall(--maskwallcnt);
}
