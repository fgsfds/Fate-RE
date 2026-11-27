/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern char palette_filename[];
extern unsigned char palette_loaded, palette_lock, palette[];
extern unsigned char *palookup[], *translucency_table, *current_palookup;
extern short numpalookups;
extern long globalpal;

extern int kopen4load(const char *, int);
#pragma aux kopen4load modify exact [eax edx];
extern long kread(int, void *, long);
#pragma aux kread modify exact [eax edx ebx];
extern void kclose(int);
#pragma aux kclose modify exact [eax];
extern void *kmalloc(unsigned);
#pragma aux kmalloc modify exact [eax];
extern void allocache(unsigned char **, long, unsigned char *);
#pragma aux allocache modify exact [eax edx ebx];
extern void setpalookupaddress(unsigned char *);
#pragma aux setpalookupaddress modify exact [eax];
extern void fixtransluscence(unsigned char *);
#pragma aux fixtransluscence modify exact [eax];
extern void initialize_color_lookup(int, int, int);
#pragma aux initialize_color_lookup modify exact [eax edx ebx];

void load_palette_tables(void)
{
    int file;
    if (palette_loaded)
        return;
    file = kopen4load(palette_filename, 0);
    if (file == -1)
        return;
    kread(file, palette, 768);
    kread(file, &numpalookups, 2);
    palookup[0] = kmalloc(numpalookups << 8);
    if (!palookup[0])
        allocache(&palookup[0], numpalookups << 8, &palette_lock);
    translucency_table = kmalloc(65536);
    if (!translucency_table)
        allocache(&translucency_table, 65536, &palette_lock);
    current_palookup = palookup[0];
    globalpal = 0;
    setpalookupaddress(current_palookup);
    fixtransluscence(translucency_table);
    kread(file, palookup[globalpal], numpalookups << 8);
    kread(file, translucency_table, 65536);
    kclose(file);
    initialize_color_lookup(30, 59, 11);
    palette_loaded = 1;
}
