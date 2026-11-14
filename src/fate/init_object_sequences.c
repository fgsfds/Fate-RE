/* Object-sequence definitions recovered as field values, not instruction bytes. */
#pragma pack(push, 1)
typedef struct {
    short start, end, final, next;
    short debris[12][4];
    short sounds[8];
} ObjectSequenceDefinition;
#pragma pack(pop)
extern ObjectSequenceDefinition object_sequence_definitions[];

void init_object_sequences(void)
{
    /* Sequence 1. */
    object_sequence_definitions[1].start = 807; object_sequence_definitions[1].end = 810; object_sequence_definitions[1].final = 0; object_sequence_definitions[1].next = 0;
    object_sequence_definitions[1].sounds[0] = 28; object_sequence_definitions[1].sounds[1] = 29; object_sequence_definitions[1].sounds[2] = 30; object_sequence_definitions[1].sounds[3] = 28;
    object_sequence_definitions[1].sounds[4] = 29; object_sequence_definitions[1].sounds[5] = 30; object_sequence_definitions[1].sounds[6] = 28; object_sequence_definitions[1].sounds[7] = 29;
    /* Sequence 2. */
    object_sequence_definitions[2].start = 1184; object_sequence_definitions[2].end = 1185; object_sequence_definitions[2].final = 1183; object_sequence_definitions[2].next = 2;
    /* Sequence 3. */
    object_sequence_definitions[3].start = 341; object_sequence_definitions[3].end = 345; object_sequence_definitions[3].final = 346; object_sequence_definitions[3].next = 0;
    object_sequence_definitions[3].debris[0][0] = 4; object_sequence_definitions[3].debris[0][1] = 1; object_sequence_definitions[3].debris[0][2] = 3; object_sequence_definitions[3].debris[0][3] = 1;
    object_sequence_definitions[3].debris[1][0] = 5; object_sequence_definitions[3].debris[1][1] = 1; object_sequence_definitions[3].debris[1][2] = 3; object_sequence_definitions[3].debris[1][3] = 1;
    object_sequence_definitions[3].debris[2][0] = 6; object_sequence_definitions[3].debris[2][1] = 1; object_sequence_definitions[3].debris[2][2] = 3; object_sequence_definitions[3].debris[2][3] = 1;
    object_sequence_definitions[3].debris[3][0] = 7; object_sequence_definitions[3].debris[3][1] = 1; object_sequence_definitions[3].debris[3][2] = 3; object_sequence_definitions[3].debris[3][3] = 1;
    object_sequence_definitions[3].debris[4][0] = 8; object_sequence_definitions[3].debris[4][1] = 1; object_sequence_definitions[3].debris[4][2] = 3; object_sequence_definitions[3].debris[4][3] = 1;
    object_sequence_definitions[3].debris[5][0] = 9; object_sequence_definitions[3].debris[5][1] = 1; object_sequence_definitions[3].debris[5][2] = 3; object_sequence_definitions[3].debris[5][3] = 1;
    object_sequence_definitions[3].debris[6][0] = 10; object_sequence_definitions[3].debris[6][1] = 1; object_sequence_definitions[3].debris[6][2] = 3; object_sequence_definitions[3].debris[6][3] = 1;
    object_sequence_definitions[3].debris[7][0] = 11; object_sequence_definitions[3].debris[7][1] = 1; object_sequence_definitions[3].debris[7][2] = 3; object_sequence_definitions[3].debris[7][3] = 1;
    object_sequence_definitions[3].debris[8][0] = 7; object_sequence_definitions[3].debris[8][1] = 1; object_sequence_definitions[3].debris[8][2] = 3; object_sequence_definitions[3].debris[8][3] = 1;
    object_sequence_definitions[3].debris[9][0] = 8; object_sequence_definitions[3].debris[9][1] = 1; object_sequence_definitions[3].debris[9][2] = 3; object_sequence_definitions[3].debris[9][3] = 1;
    object_sequence_definitions[3].debris[10][0] = 9; object_sequence_definitions[3].debris[10][1] = 1; object_sequence_definitions[3].debris[10][2] = 3; object_sequence_definitions[3].debris[10][3] = 1;
    object_sequence_definitions[3].debris[11][0] = 10; object_sequence_definitions[3].debris[11][1] = 1; object_sequence_definitions[3].debris[11][2] = 3; object_sequence_definitions[3].debris[11][3] = 1;
    object_sequence_definitions[3].sounds[0] = 100; object_sequence_definitions[3].sounds[1] = 101; object_sequence_definitions[3].sounds[2] = 102; object_sequence_definitions[3].sounds[3] = 100;
    object_sequence_definitions[3].sounds[4] = 101; object_sequence_definitions[3].sounds[5] = 102; object_sequence_definitions[3].sounds[6] = 100; object_sequence_definitions[3].sounds[7] = 101;
    /* Sequence 4. */
    object_sequence_definitions[4].start = 827; object_sequence_definitions[4].end = 832; object_sequence_definitions[4].final = 0; object_sequence_definitions[4].next = 0;
    object_sequence_definitions[4].debris[0][0] = 31; object_sequence_definitions[4].debris[0][1] = 0; object_sequence_definitions[4].debris[0][2] = 5; object_sequence_definitions[4].debris[0][3] = 1;
    object_sequence_definitions[4].debris[1][0] = 32; object_sequence_definitions[4].debris[1][1] = 0; object_sequence_definitions[4].debris[1][2] = 5; object_sequence_definitions[4].debris[1][3] = 1;
    object_sequence_definitions[4].debris[2][0] = 33; object_sequence_definitions[4].debris[2][1] = 0; object_sequence_definitions[4].debris[2][2] = 5; object_sequence_definitions[4].debris[2][3] = 1;
    object_sequence_definitions[4].debris[3][0] = 34; object_sequence_definitions[4].debris[3][1] = 0; object_sequence_definitions[4].debris[3][2] = 5; object_sequence_definitions[4].debris[3][3] = 1;
    object_sequence_definitions[4].debris[4][0] = 31; object_sequence_definitions[4].debris[4][1] = 0; object_sequence_definitions[4].debris[4][2] = 5; object_sequence_definitions[4].debris[4][3] = 1;
    object_sequence_definitions[4].debris[5][0] = 32; object_sequence_definitions[4].debris[5][1] = 0; object_sequence_definitions[4].debris[5][2] = 5; object_sequence_definitions[4].debris[5][3] = 1;
    object_sequence_definitions[4].debris[6][0] = 33; object_sequence_definitions[4].debris[6][1] = 0; object_sequence_definitions[4].debris[6][2] = 5; object_sequence_definitions[4].debris[6][3] = 1;
    object_sequence_definitions[4].debris[7][0] = 34; object_sequence_definitions[4].debris[7][1] = 0; object_sequence_definitions[4].debris[7][2] = 5; object_sequence_definitions[4].debris[7][3] = 1;
    object_sequence_definitions[4].debris[8][0] = 31; object_sequence_definitions[4].debris[8][1] = 0; object_sequence_definitions[4].debris[8][2] = 5; object_sequence_definitions[4].debris[8][3] = 1;
    object_sequence_definitions[4].debris[9][0] = 32; object_sequence_definitions[4].debris[9][1] = 0; object_sequence_definitions[4].debris[9][2] = 5; object_sequence_definitions[4].debris[9][3] = 1;
    object_sequence_definitions[4].debris[10][0] = 33; object_sequence_definitions[4].debris[10][1] = 0; object_sequence_definitions[4].debris[10][2] = 5; object_sequence_definitions[4].debris[10][3] = 1;
    object_sequence_definitions[4].debris[11][0] = 34; object_sequence_definitions[4].debris[11][1] = 0; object_sequence_definitions[4].debris[11][2] = 5; object_sequence_definitions[4].debris[11][3] = 1;
    object_sequence_definitions[4].sounds[0] = 93; object_sequence_definitions[4].sounds[1] = 94; object_sequence_definitions[4].sounds[2] = 93; object_sequence_definitions[4].sounds[3] = 93;
    object_sequence_definitions[4].sounds[4] = 94; object_sequence_definitions[4].sounds[5] = 96; object_sequence_definitions[4].sounds[6] = 97; object_sequence_definitions[4].sounds[7] = 94;
    /* Sequence 5. */
    object_sequence_definitions[5].start = 2477; object_sequence_definitions[5].end = 2485; object_sequence_definitions[5].final = 2486; object_sequence_definitions[5].next = 11;
    object_sequence_definitions[5].debris[0][0] = 71; object_sequence_definitions[5].debris[0][1] = 0; object_sequence_definitions[5].debris[0][2] = 3; object_sequence_definitions[5].debris[0][3] = 0;
    object_sequence_definitions[5].debris[1][0] = 71; object_sequence_definitions[5].debris[1][1] = 1; object_sequence_definitions[5].debris[1][2] = 3; object_sequence_definitions[5].debris[1][3] = 0;
    object_sequence_definitions[5].debris[2][0] = 71; object_sequence_definitions[5].debris[2][1] = 1; object_sequence_definitions[5].debris[2][2] = 4; object_sequence_definitions[5].debris[2][3] = 0;
    object_sequence_definitions[5].debris[3][0] = 71; object_sequence_definitions[5].debris[3][1] = 1; object_sequence_definitions[5].debris[3][2] = 5; object_sequence_definitions[5].debris[3][3] = 0;
    object_sequence_definitions[5].debris[4][0] = 71; object_sequence_definitions[5].debris[4][1] = 1; object_sequence_definitions[5].debris[4][2] = 4; object_sequence_definitions[5].debris[4][3] = 0;
    object_sequence_definitions[5].debris[5][0] = 71; object_sequence_definitions[5].debris[5][1] = 1; object_sequence_definitions[5].debris[5][2] = 4; object_sequence_definitions[5].debris[5][3] = 0;
    object_sequence_definitions[5].debris[6][0] = 71; object_sequence_definitions[5].debris[6][1] = 1; object_sequence_definitions[5].debris[6][2] = 5; object_sequence_definitions[5].debris[6][3] = 0;
    object_sequence_definitions[5].debris[7][0] = 71; object_sequence_definitions[5].debris[7][1] = 1; object_sequence_definitions[5].debris[7][2] = 5; object_sequence_definitions[5].debris[7][3] = 0;
    object_sequence_definitions[5].sounds[0] = 40; object_sequence_definitions[5].sounds[1] = 41; object_sequence_definitions[5].sounds[2] = 42; object_sequence_definitions[5].sounds[3] = 43;
    object_sequence_definitions[5].sounds[4] = 44; object_sequence_definitions[5].sounds[5] = 45; object_sequence_definitions[5].sounds[6] = 42; object_sequence_definitions[5].sounds[7] = 40;
    /* Sequence 6. */
    object_sequence_definitions[6].start = 2552; object_sequence_definitions[6].end = 2560; object_sequence_definitions[6].final = 2561; object_sequence_definitions[6].next = 6;
    /* Sequence 7. */
    object_sequence_definitions[7].start = 2552; object_sequence_definitions[7].end = 2560; object_sequence_definitions[7].final = 2561; object_sequence_definitions[7].next = 6;
    object_sequence_definitions[7].debris[0][0] = 25; object_sequence_definitions[7].debris[0][1] = 1; object_sequence_definitions[7].debris[0][2] = 5; object_sequence_definitions[7].debris[0][3] = 0;
    object_sequence_definitions[7].debris[1][0] = 37; object_sequence_definitions[7].debris[1][1] = 1; object_sequence_definitions[7].debris[1][2] = 5; object_sequence_definitions[7].debris[1][3] = 0;
    object_sequence_definitions[7].debris[2][0] = 88; object_sequence_definitions[7].debris[2][1] = 1; object_sequence_definitions[7].debris[2][2] = 4; object_sequence_definitions[7].debris[2][3] = 0;
    object_sequence_definitions[7].debris[3][0] = 88; object_sequence_definitions[7].debris[3][1] = 1; object_sequence_definitions[7].debris[3][2] = 5; object_sequence_definitions[7].debris[3][3] = 0;
    object_sequence_definitions[7].debris[4][0] = 88; object_sequence_definitions[7].debris[4][1] = 1; object_sequence_definitions[7].debris[4][2] = 4; object_sequence_definitions[7].debris[4][3] = 0;
    object_sequence_definitions[7].debris[5][0] = 88; object_sequence_definitions[7].debris[5][1] = 1; object_sequence_definitions[7].debris[5][2] = 4; object_sequence_definitions[7].debris[5][3] = 0;
    object_sequence_definitions[7].debris[6][0] = 88; object_sequence_definitions[7].debris[6][1] = 1; object_sequence_definitions[7].debris[6][2] = 5; object_sequence_definitions[7].debris[6][3] = 0;
    object_sequence_definitions[7].debris[7][0] = 88; object_sequence_definitions[7].debris[7][1] = 1; object_sequence_definitions[7].debris[7][2] = 5; object_sequence_definitions[7].debris[7][3] = 0;
    object_sequence_definitions[7].sounds[0] = 60; object_sequence_definitions[7].sounds[1] = 61; object_sequence_definitions[7].sounds[2] = 62; object_sequence_definitions[7].sounds[3] = 63;
    object_sequence_definitions[7].sounds[4] = 60; object_sequence_definitions[7].sounds[5] = 61; object_sequence_definitions[7].sounds[6] = 62; object_sequence_definitions[7].sounds[7] = 63;
    /* Sequence 8. */
    object_sequence_definitions[8].start = 2552; object_sequence_definitions[8].end = 2560; object_sequence_definitions[8].final = 2561; object_sequence_definitions[8].next = 6;
    object_sequence_definitions[8].debris[0][0] = 24; object_sequence_definitions[8].debris[0][1] = 1; object_sequence_definitions[8].debris[0][2] = 5; object_sequence_definitions[8].debris[0][3] = 0;
    object_sequence_definitions[8].debris[1][0] = 37; object_sequence_definitions[8].debris[1][1] = 1; object_sequence_definitions[8].debris[1][2] = 5; object_sequence_definitions[8].debris[1][3] = 0;
    object_sequence_definitions[8].debris[2][0] = 88; object_sequence_definitions[8].debris[2][1] = 1; object_sequence_definitions[8].debris[2][2] = 4; object_sequence_definitions[8].debris[2][3] = 0;
    object_sequence_definitions[8].debris[3][0] = 88; object_sequence_definitions[8].debris[3][1] = 1; object_sequence_definitions[8].debris[3][2] = 5; object_sequence_definitions[8].debris[3][3] = 0;
    object_sequence_definitions[8].debris[4][0] = 88; object_sequence_definitions[8].debris[4][1] = 1; object_sequence_definitions[8].debris[4][2] = 4; object_sequence_definitions[8].debris[4][3] = 0;
    object_sequence_definitions[8].debris[5][0] = 88; object_sequence_definitions[8].debris[5][1] = 1; object_sequence_definitions[8].debris[5][2] = 4; object_sequence_definitions[8].debris[5][3] = 0;
    object_sequence_definitions[8].debris[6][0] = 88; object_sequence_definitions[8].debris[6][1] = 1; object_sequence_definitions[8].debris[6][2] = 5; object_sequence_definitions[8].debris[6][3] = 0;
    object_sequence_definitions[8].debris[7][0] = 88; object_sequence_definitions[8].debris[7][1] = 1; object_sequence_definitions[8].debris[7][2] = 5; object_sequence_definitions[8].debris[7][3] = 0;
    object_sequence_definitions[8].sounds[0] = 60; object_sequence_definitions[8].sounds[1] = 61; object_sequence_definitions[8].sounds[2] = 62; object_sequence_definitions[8].sounds[3] = 63;
    object_sequence_definitions[8].sounds[4] = 60; object_sequence_definitions[8].sounds[5] = 61; object_sequence_definitions[8].sounds[6] = 62; object_sequence_definitions[8].sounds[7] = 63;
    /* Sequence 9. */
    object_sequence_definitions[9].start = 2552; object_sequence_definitions[9].end = 2560; object_sequence_definitions[9].final = 2561; object_sequence_definitions[9].next = 6;
    object_sequence_definitions[9].debris[0][0] = 26; object_sequence_definitions[9].debris[0][1] = 1; object_sequence_definitions[9].debris[0][2] = 5; object_sequence_definitions[9].debris[0][3] = 0;
    object_sequence_definitions[9].debris[1][0] = 37; object_sequence_definitions[9].debris[1][1] = 1; object_sequence_definitions[9].debris[1][2] = 5; object_sequence_definitions[9].debris[1][3] = 0;
    object_sequence_definitions[9].debris[2][0] = 88; object_sequence_definitions[9].debris[2][1] = 1; object_sequence_definitions[9].debris[2][2] = 4; object_sequence_definitions[9].debris[2][3] = 0;
    object_sequence_definitions[9].debris[3][0] = 88; object_sequence_definitions[9].debris[3][1] = 1; object_sequence_definitions[9].debris[3][2] = 5; object_sequence_definitions[9].debris[3][3] = 0;
    object_sequence_definitions[9].debris[4][0] = 88; object_sequence_definitions[9].debris[4][1] = 1; object_sequence_definitions[9].debris[4][2] = 4; object_sequence_definitions[9].debris[4][3] = 0;
    object_sequence_definitions[9].debris[5][0] = 88; object_sequence_definitions[9].debris[5][1] = 1; object_sequence_definitions[9].debris[5][2] = 4; object_sequence_definitions[9].debris[5][3] = 0;
    object_sequence_definitions[9].debris[6][0] = 88; object_sequence_definitions[9].debris[6][1] = 1; object_sequence_definitions[9].debris[6][2] = 5; object_sequence_definitions[9].debris[6][3] = 0;
    object_sequence_definitions[9].debris[7][0] = 88; object_sequence_definitions[9].debris[7][1] = 1; object_sequence_definitions[9].debris[7][2] = 5; object_sequence_definitions[9].debris[7][3] = 0;
    object_sequence_definitions[9].sounds[0] = 60; object_sequence_definitions[9].sounds[1] = 61; object_sequence_definitions[9].sounds[2] = 62; object_sequence_definitions[9].sounds[3] = 63;
    object_sequence_definitions[9].sounds[4] = 60; object_sequence_definitions[9].sounds[5] = 61; object_sequence_definitions[9].sounds[6] = 62; object_sequence_definitions[9].sounds[7] = 63;
    /* Sequence 10. */
    object_sequence_definitions[10].start = 803; object_sequence_definitions[10].end = 806; object_sequence_definitions[10].final = 0; object_sequence_definitions[10].next = 0;
    object_sequence_definitions[10].sounds[0] = 47; object_sequence_definitions[10].sounds[1] = 48; object_sequence_definitions[10].sounds[2] = 49; object_sequence_definitions[10].sounds[3] = 47;
    object_sequence_definitions[10].sounds[4] = 48; object_sequence_definitions[10].sounds[5] = 49; object_sequence_definitions[10].sounds[6] = 47; object_sequence_definitions[10].sounds[7] = 48;
    /* Sequence 11. */
    object_sequence_definitions[11].start = 2396; object_sequence_definitions[11].end = 2404; object_sequence_definitions[11].final = 2405; object_sequence_definitions[11].next = 11;
    /* Sequence 12. */
    object_sequence_definitions[12].start = 1386; object_sequence_definitions[12].end = 1386; object_sequence_definitions[12].final = 1386; object_sequence_definitions[12].next = 0;
    /* Sequence 13. */
    object_sequence_definitions[13].start = 910; object_sequence_definitions[13].end = 915; object_sequence_definitions[13].final = 0; object_sequence_definitions[13].next = 0;
    object_sequence_definitions[13].debris[0][0] = 41; object_sequence_definitions[13].debris[0][1] = 1; object_sequence_definitions[13].debris[0][2] = 3; object_sequence_definitions[13].debris[0][3] = 1;
    object_sequence_definitions[13].debris[1][0] = 41; object_sequence_definitions[13].debris[1][1] = 1; object_sequence_definitions[13].debris[1][2] = 3; object_sequence_definitions[13].debris[1][3] = 1;
    object_sequence_definitions[13].debris[2][0] = 41; object_sequence_definitions[13].debris[2][1] = 1; object_sequence_definitions[13].debris[2][2] = 3; object_sequence_definitions[13].debris[2][3] = 1;
    object_sequence_definitions[13].debris[3][0] = 41; object_sequence_definitions[13].debris[3][1] = 1; object_sequence_definitions[13].debris[3][2] = 3; object_sequence_definitions[13].debris[3][3] = 1;
    object_sequence_definitions[13].debris[4][0] = 41; object_sequence_definitions[13].debris[4][1] = 1; object_sequence_definitions[13].debris[4][2] = 3; object_sequence_definitions[13].debris[4][3] = 1;
    object_sequence_definitions[13].debris[5][0] = 41; object_sequence_definitions[13].debris[5][1] = 1; object_sequence_definitions[13].debris[5][2] = 3; object_sequence_definitions[13].debris[5][3] = 1;
    object_sequence_definitions[13].debris[6][0] = 41; object_sequence_definitions[13].debris[6][1] = 1; object_sequence_definitions[13].debris[6][2] = 3; object_sequence_definitions[13].debris[6][3] = 1;
    object_sequence_definitions[13].debris[7][0] = 41; object_sequence_definitions[13].debris[7][1] = 1; object_sequence_definitions[13].debris[7][2] = 3; object_sequence_definitions[13].debris[7][3] = 1;
    object_sequence_definitions[13].debris[8][0] = 41; object_sequence_definitions[13].debris[8][1] = 1; object_sequence_definitions[13].debris[8][2] = 3; object_sequence_definitions[13].debris[8][3] = 1;
    object_sequence_definitions[13].debris[9][0] = 41; object_sequence_definitions[13].debris[9][1] = 1; object_sequence_definitions[13].debris[9][2] = 3; object_sequence_definitions[13].debris[9][3] = 1;
    object_sequence_definitions[13].debris[10][0] = 41; object_sequence_definitions[13].debris[10][1] = 1; object_sequence_definitions[13].debris[10][2] = 3; object_sequence_definitions[13].debris[10][3] = 1;
    object_sequence_definitions[13].debris[11][0] = 41; object_sequence_definitions[13].debris[11][1] = 1; object_sequence_definitions[13].debris[11][2] = 3; object_sequence_definitions[13].debris[11][3] = 1;
    object_sequence_definitions[13].sounds[0] = 95; object_sequence_definitions[13].sounds[1] = 96; object_sequence_definitions[13].sounds[2] = 97; object_sequence_definitions[13].sounds[3] = 98;
    object_sequence_definitions[13].sounds[4] = 95; object_sequence_definitions[13].sounds[5] = 96; object_sequence_definitions[13].sounds[6] = 97; object_sequence_definitions[13].sounds[7] = 98;
    /* Sequence 14. */
    object_sequence_definitions[14].start = 859; object_sequence_definitions[14].end = 861; object_sequence_definitions[14].final = 858; object_sequence_definitions[14].next = 14;
    /* Sequence 15. */
    object_sequence_definitions[15].start = 910; object_sequence_definitions[15].end = 915; object_sequence_definitions[15].final = 0; object_sequence_definitions[15].next = 0;
    object_sequence_definitions[15].debris[0][0] = 42; object_sequence_definitions[15].debris[0][1] = 0; object_sequence_definitions[15].debris[0][2] = 5; object_sequence_definitions[15].debris[0][3] = 1;
    object_sequence_definitions[15].debris[1][0] = 42; object_sequence_definitions[15].debris[1][1] = 0; object_sequence_definitions[15].debris[1][2] = 5; object_sequence_definitions[15].debris[1][3] = 1;
    object_sequence_definitions[15].debris[2][0] = 42; object_sequence_definitions[15].debris[2][1] = 0; object_sequence_definitions[15].debris[2][2] = 5; object_sequence_definitions[15].debris[2][3] = 1;
    object_sequence_definitions[15].debris[3][0] = 42; object_sequence_definitions[15].debris[3][1] = 0; object_sequence_definitions[15].debris[3][2] = 5; object_sequence_definitions[15].debris[3][3] = 1;
    object_sequence_definitions[15].debris[4][0] = 42; object_sequence_definitions[15].debris[4][1] = 0; object_sequence_definitions[15].debris[4][2] = 5; object_sequence_definitions[15].debris[4][3] = 1;
    object_sequence_definitions[15].debris[5][0] = 42; object_sequence_definitions[15].debris[5][1] = 0; object_sequence_definitions[15].debris[5][2] = 5; object_sequence_definitions[15].debris[5][3] = 1;
    object_sequence_definitions[15].debris[6][0] = 42; object_sequence_definitions[15].debris[6][1] = 0; object_sequence_definitions[15].debris[6][2] = 5; object_sequence_definitions[15].debris[6][3] = 1;
    object_sequence_definitions[15].debris[7][0] = 42; object_sequence_definitions[15].debris[7][1] = 0; object_sequence_definitions[15].debris[7][2] = 5; object_sequence_definitions[15].debris[7][3] = 1;
    object_sequence_definitions[15].debris[8][0] = 42; object_sequence_definitions[15].debris[8][1] = 0; object_sequence_definitions[15].debris[8][2] = 5; object_sequence_definitions[15].debris[8][3] = 1;
    object_sequence_definitions[15].debris[9][0] = 42; object_sequence_definitions[15].debris[9][1] = 0; object_sequence_definitions[15].debris[9][2] = 5; object_sequence_definitions[15].debris[9][3] = 1;
    object_sequence_definitions[15].debris[10][0] = 42; object_sequence_definitions[15].debris[10][1] = 0; object_sequence_definitions[15].debris[10][2] = 5; object_sequence_definitions[15].debris[10][3] = 1;
    object_sequence_definitions[15].debris[11][0] = 42; object_sequence_definitions[15].debris[11][1] = 0; object_sequence_definitions[15].debris[11][2] = 5; object_sequence_definitions[15].debris[11][3] = 1;
    object_sequence_definitions[15].sounds[0] = 99; object_sequence_definitions[15].sounds[1] = 99; object_sequence_definitions[15].sounds[2] = 99; object_sequence_definitions[15].sounds[3] = 99;
    object_sequence_definitions[15].sounds[4] = 99; object_sequence_definitions[15].sounds[5] = 99; object_sequence_definitions[15].sounds[6] = 99; object_sequence_definitions[15].sounds[7] = 99;
    /* Sequence 16. */
    object_sequence_definitions[16].start = 910; object_sequence_definitions[16].end = 915; object_sequence_definitions[16].final = 0; object_sequence_definitions[16].next = 0;
    object_sequence_definitions[16].debris[0][0] = 31; object_sequence_definitions[16].debris[0][1] = 0; object_sequence_definitions[16].debris[0][2] = 5; object_sequence_definitions[16].debris[0][3] = 1;
    object_sequence_definitions[16].debris[1][0] = 32; object_sequence_definitions[16].debris[1][1] = 0; object_sequence_definitions[16].debris[1][2] = 5; object_sequence_definitions[16].debris[1][3] = 1;
    object_sequence_definitions[16].sounds[0] = 95; object_sequence_definitions[16].sounds[1] = 96; object_sequence_definitions[16].sounds[2] = 97; object_sequence_definitions[16].sounds[3] = 98;
    object_sequence_definitions[16].sounds[4] = 95; object_sequence_definitions[16].sounds[5] = 96; object_sequence_definitions[16].sounds[6] = 97; object_sequence_definitions[16].sounds[7] = 98;
    /* Sequence 17. */
    object_sequence_definitions[17].start = 2477; object_sequence_definitions[17].end = 2485; object_sequence_definitions[17].final = 2486; object_sequence_definitions[17].next = 11;
    object_sequence_definitions[17].debris[0][0] = 44; object_sequence_definitions[17].debris[0][1] = 1; object_sequence_definitions[17].debris[0][2] = 5; object_sequence_definitions[17].debris[0][3] = 0;
    object_sequence_definitions[17].debris[1][0] = 71; object_sequence_definitions[17].debris[1][1] = 1; object_sequence_definitions[17].debris[1][2] = 3; object_sequence_definitions[17].debris[1][3] = 0;
    object_sequence_definitions[17].debris[2][0] = 71; object_sequence_definitions[17].debris[2][1] = 1; object_sequence_definitions[17].debris[2][2] = 4; object_sequence_definitions[17].debris[2][3] = 0;
    object_sequence_definitions[17].debris[3][0] = 71; object_sequence_definitions[17].debris[3][1] = 1; object_sequence_definitions[17].debris[3][2] = 5; object_sequence_definitions[17].debris[3][3] = 0;
    object_sequence_definitions[17].debris[4][0] = 71; object_sequence_definitions[17].debris[4][1] = 1; object_sequence_definitions[17].debris[4][2] = 4; object_sequence_definitions[17].debris[4][3] = 0;
    object_sequence_definitions[17].debris[5][0] = 71; object_sequence_definitions[17].debris[5][1] = 1; object_sequence_definitions[17].debris[5][2] = 4; object_sequence_definitions[17].debris[5][3] = 0;
    object_sequence_definitions[17].debris[6][0] = 71; object_sequence_definitions[17].debris[6][1] = 1; object_sequence_definitions[17].debris[6][2] = 5; object_sequence_definitions[17].debris[6][3] = 0;
    object_sequence_definitions[17].sounds[0] = 40; object_sequence_definitions[17].sounds[1] = 41; object_sequence_definitions[17].sounds[2] = 42; object_sequence_definitions[17].sounds[3] = 43;
    object_sequence_definitions[17].sounds[4] = 44; object_sequence_definitions[17].sounds[5] = 45; object_sequence_definitions[17].sounds[6] = 40; object_sequence_definitions[17].sounds[7] = 41;
    /* Sequence 18. */
    object_sequence_definitions[18].start = 2477; object_sequence_definitions[18].end = 2485; object_sequence_definitions[18].final = 2486; object_sequence_definitions[18].next = 11;
    object_sequence_definitions[18].debris[0][0] = 45; object_sequence_definitions[18].debris[0][1] = 1; object_sequence_definitions[18].debris[0][2] = 5; object_sequence_definitions[18].debris[0][3] = 0;
    object_sequence_definitions[18].debris[1][0] = 71; object_sequence_definitions[18].debris[1][1] = 1; object_sequence_definitions[18].debris[1][2] = 3; object_sequence_definitions[18].debris[1][3] = 0;
    object_sequence_definitions[18].debris[2][0] = 71; object_sequence_definitions[18].debris[2][1] = 1; object_sequence_definitions[18].debris[2][2] = 4; object_sequence_definitions[18].debris[2][3] = 0;
    object_sequence_definitions[18].debris[3][0] = 71; object_sequence_definitions[18].debris[3][1] = 1; object_sequence_definitions[18].debris[3][2] = 5; object_sequence_definitions[18].debris[3][3] = 0;
    object_sequence_definitions[18].debris[4][0] = 71; object_sequence_definitions[18].debris[4][1] = 1; object_sequence_definitions[18].debris[4][2] = 4; object_sequence_definitions[18].debris[4][3] = 0;
    object_sequence_definitions[18].debris[5][0] = 71; object_sequence_definitions[18].debris[5][1] = 1; object_sequence_definitions[18].debris[5][2] = 4; object_sequence_definitions[18].debris[5][3] = 0;
    object_sequence_definitions[18].debris[6][0] = 71; object_sequence_definitions[18].debris[6][1] = 1; object_sequence_definitions[18].debris[6][2] = 5; object_sequence_definitions[18].debris[6][3] = 0;
    object_sequence_definitions[18].sounds[0] = 40; object_sequence_definitions[18].sounds[1] = 41; object_sequence_definitions[18].sounds[2] = 42; object_sequence_definitions[18].sounds[3] = 43;
    object_sequence_definitions[18].sounds[4] = 44; object_sequence_definitions[18].sounds[5] = 45; object_sequence_definitions[18].sounds[6] = 40; object_sequence_definitions[18].sounds[7] = 41;
    /* Sequence 19. */
    object_sequence_definitions[19].start = 2477; object_sequence_definitions[19].end = 2485; object_sequence_definitions[19].final = 2486; object_sequence_definitions[19].next = 11;
    object_sequence_definitions[19].debris[0][0] = 46; object_sequence_definitions[19].debris[0][1] = 1; object_sequence_definitions[19].debris[0][2] = 5; object_sequence_definitions[19].debris[0][3] = 0;
    object_sequence_definitions[19].debris[1][0] = 71; object_sequence_definitions[19].debris[1][1] = 1; object_sequence_definitions[19].debris[1][2] = 3; object_sequence_definitions[19].debris[1][3] = 0;
    object_sequence_definitions[19].debris[2][0] = 71; object_sequence_definitions[19].debris[2][1] = 1; object_sequence_definitions[19].debris[2][2] = 4; object_sequence_definitions[19].debris[2][3] = 0;
    object_sequence_definitions[19].debris[3][0] = 71; object_sequence_definitions[19].debris[3][1] = 1; object_sequence_definitions[19].debris[3][2] = 5; object_sequence_definitions[19].debris[3][3] = 0;
    object_sequence_definitions[19].debris[4][0] = 71; object_sequence_definitions[19].debris[4][1] = 1; object_sequence_definitions[19].debris[4][2] = 4; object_sequence_definitions[19].debris[4][3] = 0;
    object_sequence_definitions[19].debris[5][0] = 71; object_sequence_definitions[19].debris[5][1] = 1; object_sequence_definitions[19].debris[5][2] = 4; object_sequence_definitions[19].debris[5][3] = 0;
    object_sequence_definitions[19].debris[6][0] = 71; object_sequence_definitions[19].debris[6][1] = 1; object_sequence_definitions[19].debris[6][2] = 5; object_sequence_definitions[19].debris[6][3] = 0;
    object_sequence_definitions[19].sounds[0] = 40; object_sequence_definitions[19].sounds[1] = 41; object_sequence_definitions[19].sounds[2] = 42; object_sequence_definitions[19].sounds[3] = 43;
    object_sequence_definitions[19].sounds[4] = 44; object_sequence_definitions[19].sounds[5] = 45; object_sequence_definitions[19].sounds[6] = 40; object_sequence_definitions[19].sounds[7] = 41;
    /* Sequence 20. */
    object_sequence_definitions[20].start = 2477; object_sequence_definitions[20].end = 2485; object_sequence_definitions[20].final = 2486; object_sequence_definitions[20].next = 11;
    object_sequence_definitions[20].debris[0][0] = 47; object_sequence_definitions[20].debris[0][1] = 1; object_sequence_definitions[20].debris[0][2] = 5; object_sequence_definitions[20].debris[0][3] = 0;
    object_sequence_definitions[20].debris[1][0] = 71; object_sequence_definitions[20].debris[1][1] = 1; object_sequence_definitions[20].debris[1][2] = 3; object_sequence_definitions[20].debris[1][3] = 0;
    object_sequence_definitions[20].debris[2][0] = 71; object_sequence_definitions[20].debris[2][1] = 1; object_sequence_definitions[20].debris[2][2] = 4; object_sequence_definitions[20].debris[2][3] = 0;
    object_sequence_definitions[20].debris[3][0] = 71; object_sequence_definitions[20].debris[3][1] = 1; object_sequence_definitions[20].debris[3][2] = 5; object_sequence_definitions[20].debris[3][3] = 0;
    object_sequence_definitions[20].debris[4][0] = 71; object_sequence_definitions[20].debris[4][1] = 1; object_sequence_definitions[20].debris[4][2] = 4; object_sequence_definitions[20].debris[4][3] = 0;
    object_sequence_definitions[20].debris[5][0] = 71; object_sequence_definitions[20].debris[5][1] = 1; object_sequence_definitions[20].debris[5][2] = 4; object_sequence_definitions[20].debris[5][3] = 0;
    object_sequence_definitions[20].debris[6][0] = 71; object_sequence_definitions[20].debris[6][1] = 1; object_sequence_definitions[20].debris[6][2] = 5; object_sequence_definitions[20].debris[6][3] = 0;
    object_sequence_definitions[20].sounds[0] = 40; object_sequence_definitions[20].sounds[1] = 41; object_sequence_definitions[20].sounds[2] = 42; object_sequence_definitions[20].sounds[3] = 43;
    object_sequence_definitions[20].sounds[4] = 44; object_sequence_definitions[20].sounds[5] = 45; object_sequence_definitions[20].sounds[6] = 40; object_sequence_definitions[20].sounds[7] = 41;
    /* Sequence 21. */
    object_sequence_definitions[21].start = 2477; object_sequence_definitions[21].end = 2485; object_sequence_definitions[21].final = 2486; object_sequence_definitions[21].next = 11;
    object_sequence_definitions[21].debris[0][0] = 48; object_sequence_definitions[21].debris[0][1] = 1; object_sequence_definitions[21].debris[0][2] = 5; object_sequence_definitions[21].debris[0][3] = 0;
    object_sequence_definitions[21].debris[1][0] = 71; object_sequence_definitions[21].debris[1][1] = 1; object_sequence_definitions[21].debris[1][2] = 3; object_sequence_definitions[21].debris[1][3] = 0;
    object_sequence_definitions[21].debris[2][0] = 71; object_sequence_definitions[21].debris[2][1] = 1; object_sequence_definitions[21].debris[2][2] = 4; object_sequence_definitions[21].debris[2][3] = 0;
    object_sequence_definitions[21].debris[3][0] = 71; object_sequence_definitions[21].debris[3][1] = 1; object_sequence_definitions[21].debris[3][2] = 5; object_sequence_definitions[21].debris[3][3] = 0;
    object_sequence_definitions[21].debris[4][0] = 71; object_sequence_definitions[21].debris[4][1] = 1; object_sequence_definitions[21].debris[4][2] = 4; object_sequence_definitions[21].debris[4][3] = 0;
    object_sequence_definitions[21].debris[5][0] = 71; object_sequence_definitions[21].debris[5][1] = 1; object_sequence_definitions[21].debris[5][2] = 4; object_sequence_definitions[21].debris[5][3] = 0;
    object_sequence_definitions[21].debris[6][0] = 71; object_sequence_definitions[21].debris[6][1] = 1; object_sequence_definitions[21].debris[6][2] = 5; object_sequence_definitions[21].debris[6][3] = 0;
    object_sequence_definitions[21].sounds[0] = 40; object_sequence_definitions[21].sounds[1] = 41; object_sequence_definitions[21].sounds[2] = 42; object_sequence_definitions[21].sounds[3] = 43;
    object_sequence_definitions[21].sounds[4] = 44; object_sequence_definitions[21].sounds[5] = 45; object_sequence_definitions[21].sounds[6] = 40; object_sequence_definitions[21].sounds[7] = 41;
    /* Sequence 22. */
    object_sequence_definitions[22].start = 2477; object_sequence_definitions[22].end = 2485; object_sequence_definitions[22].final = 2486; object_sequence_definitions[22].next = 11;
    object_sequence_definitions[22].debris[0][0] = 49; object_sequence_definitions[22].debris[0][1] = 1; object_sequence_definitions[22].debris[0][2] = 5; object_sequence_definitions[22].debris[0][3] = 0;
    object_sequence_definitions[22].debris[1][0] = 71; object_sequence_definitions[22].debris[1][1] = 1; object_sequence_definitions[22].debris[1][2] = 3; object_sequence_definitions[22].debris[1][3] = 0;
    object_sequence_definitions[22].debris[2][0] = 71; object_sequence_definitions[22].debris[2][1] = 1; object_sequence_definitions[22].debris[2][2] = 4; object_sequence_definitions[22].debris[2][3] = 0;
    object_sequence_definitions[22].debris[3][0] = 71; object_sequence_definitions[22].debris[3][1] = 1; object_sequence_definitions[22].debris[3][2] = 5; object_sequence_definitions[22].debris[3][3] = 0;
    object_sequence_definitions[22].debris[4][0] = 71; object_sequence_definitions[22].debris[4][1] = 1; object_sequence_definitions[22].debris[4][2] = 4; object_sequence_definitions[22].debris[4][3] = 0;
    object_sequence_definitions[22].debris[5][0] = 71; object_sequence_definitions[22].debris[5][1] = 1; object_sequence_definitions[22].debris[5][2] = 4; object_sequence_definitions[22].debris[5][3] = 0;
    object_sequence_definitions[22].debris[6][0] = 71; object_sequence_definitions[22].debris[6][1] = 1; object_sequence_definitions[22].debris[6][2] = 5; object_sequence_definitions[22].debris[6][3] = 0;
    object_sequence_definitions[22].sounds[0] = 40; object_sequence_definitions[22].sounds[1] = 41; object_sequence_definitions[22].sounds[2] = 42; object_sequence_definitions[22].sounds[3] = 43;
    object_sequence_definitions[22].sounds[4] = 44; object_sequence_definitions[22].sounds[5] = 45; object_sequence_definitions[22].sounds[6] = 40; object_sequence_definitions[22].sounds[7] = 41;
    /* Sequence 23. */
    object_sequence_definitions[23].start = 2477; object_sequence_definitions[23].end = 2485; object_sequence_definitions[23].final = 2486; object_sequence_definitions[23].next = 11;
    object_sequence_definitions[23].debris[0][0] = 50; object_sequence_definitions[23].debris[0][1] = 1; object_sequence_definitions[23].debris[0][2] = 5; object_sequence_definitions[23].debris[0][3] = 0;
    object_sequence_definitions[23].debris[1][0] = 71; object_sequence_definitions[23].debris[1][1] = 1; object_sequence_definitions[23].debris[1][2] = 3; object_sequence_definitions[23].debris[1][3] = 0;
    object_sequence_definitions[23].debris[2][0] = 71; object_sequence_definitions[23].debris[2][1] = 1; object_sequence_definitions[23].debris[2][2] = 4; object_sequence_definitions[23].debris[2][3] = 0;
    object_sequence_definitions[23].debris[3][0] = 71; object_sequence_definitions[23].debris[3][1] = 1; object_sequence_definitions[23].debris[3][2] = 5; object_sequence_definitions[23].debris[3][3] = 0;
    object_sequence_definitions[23].debris[4][0] = 71; object_sequence_definitions[23].debris[4][1] = 1; object_sequence_definitions[23].debris[4][2] = 4; object_sequence_definitions[23].debris[4][3] = 0;
    object_sequence_definitions[23].debris[5][0] = 71; object_sequence_definitions[23].debris[5][1] = 1; object_sequence_definitions[23].debris[5][2] = 4; object_sequence_definitions[23].debris[5][3] = 0;
    object_sequence_definitions[23].debris[6][0] = 71; object_sequence_definitions[23].debris[6][1] = 1; object_sequence_definitions[23].debris[6][2] = 5; object_sequence_definitions[23].debris[6][3] = 0;
    object_sequence_definitions[23].sounds[0] = 40; object_sequence_definitions[23].sounds[1] = 41; object_sequence_definitions[23].sounds[2] = 42; object_sequence_definitions[23].sounds[3] = 43;
    object_sequence_definitions[23].sounds[4] = 44; object_sequence_definitions[23].sounds[5] = 45; object_sequence_definitions[23].sounds[6] = 40; object_sequence_definitions[23].sounds[7] = 41;
    /* Sequence 24. */
    object_sequence_definitions[24].start = 2477; object_sequence_definitions[24].end = 2485; object_sequence_definitions[24].final = 2486; object_sequence_definitions[24].next = 11;
    object_sequence_definitions[24].debris[0][0] = 51; object_sequence_definitions[24].debris[0][1] = 1; object_sequence_definitions[24].debris[0][2] = 5; object_sequence_definitions[24].debris[0][3] = 0;
    object_sequence_definitions[24].debris[1][0] = 71; object_sequence_definitions[24].debris[1][1] = 1; object_sequence_definitions[24].debris[1][2] = 3; object_sequence_definitions[24].debris[1][3] = 0;
    object_sequence_definitions[24].debris[2][0] = 71; object_sequence_definitions[24].debris[2][1] = 1; object_sequence_definitions[24].debris[2][2] = 4; object_sequence_definitions[24].debris[2][3] = 0;
    object_sequence_definitions[24].debris[3][0] = 71; object_sequence_definitions[24].debris[3][1] = 1; object_sequence_definitions[24].debris[3][2] = 5; object_sequence_definitions[24].debris[3][3] = 0;
    object_sequence_definitions[24].debris[4][0] = 71; object_sequence_definitions[24].debris[4][1] = 1; object_sequence_definitions[24].debris[4][2] = 4; object_sequence_definitions[24].debris[4][3] = 0;
    object_sequence_definitions[24].debris[5][0] = 71; object_sequence_definitions[24].debris[5][1] = 1; object_sequence_definitions[24].debris[5][2] = 4; object_sequence_definitions[24].debris[5][3] = 0;
    object_sequence_definitions[24].debris[6][0] = 71; object_sequence_definitions[24].debris[6][1] = 1; object_sequence_definitions[24].debris[6][2] = 5; object_sequence_definitions[24].debris[6][3] = 0;
    object_sequence_definitions[24].sounds[0] = 40; object_sequence_definitions[24].sounds[1] = 41; object_sequence_definitions[24].sounds[2] = 42; object_sequence_definitions[24].sounds[3] = 43;
    object_sequence_definitions[24].sounds[4] = 44; object_sequence_definitions[24].sounds[5] = 45; object_sequence_definitions[24].sounds[6] = 40; object_sequence_definitions[24].sounds[7] = 41;
    /* Sequence 25. */
    object_sequence_definitions[25].start = 1362; object_sequence_definitions[25].end = 1363; object_sequence_definitions[25].final = 1363; object_sequence_definitions[25].next = 0;
    object_sequence_definitions[25].sounds[0] = 103; object_sequence_definitions[25].sounds[1] = 104; object_sequence_definitions[25].sounds[2] = 103; object_sequence_definitions[25].sounds[3] = 104;
    object_sequence_definitions[25].sounds[4] = 103; object_sequence_definitions[25].sounds[5] = 104; object_sequence_definitions[25].sounds[6] = 103; object_sequence_definitions[25].sounds[7] = 104;
    /* Sequence 26. */
    object_sequence_definitions[26].start = 2772; object_sequence_definitions[26].end = 2780; object_sequence_definitions[26].final = 2781; object_sequence_definitions[26].next = 27;
    object_sequence_definitions[26].debris[1][0] = 71; object_sequence_definitions[26].debris[1][1] = 1; object_sequence_definitions[26].debris[1][2] = 3; object_sequence_definitions[26].debris[1][3] = 0;
    object_sequence_definitions[26].debris[2][0] = 71; object_sequence_definitions[26].debris[2][1] = 1; object_sequence_definitions[26].debris[2][2] = 4; object_sequence_definitions[26].debris[2][3] = 0;
    object_sequence_definitions[26].debris[3][0] = 71; object_sequence_definitions[26].debris[3][1] = 1; object_sequence_definitions[26].debris[3][2] = 5; object_sequence_definitions[26].debris[3][3] = 0;
    object_sequence_definitions[26].debris[4][0] = 71; object_sequence_definitions[26].debris[4][1] = 1; object_sequence_definitions[26].debris[4][2] = 4; object_sequence_definitions[26].debris[4][3] = 0;
    object_sequence_definitions[26].debris[5][0] = 71; object_sequence_definitions[26].debris[5][1] = 1; object_sequence_definitions[26].debris[5][2] = 4; object_sequence_definitions[26].debris[5][3] = 0;
    object_sequence_definitions[26].debris[6][0] = 71; object_sequence_definitions[26].debris[6][1] = 1; object_sequence_definitions[26].debris[6][2] = 5; object_sequence_definitions[26].debris[6][3] = 0;
    object_sequence_definitions[26].sounds[0] = 75; object_sequence_definitions[26].sounds[1] = 76; object_sequence_definitions[26].sounds[2] = 77; object_sequence_definitions[26].sounds[3] = 78;
    object_sequence_definitions[26].sounds[4] = 75; object_sequence_definitions[26].sounds[5] = 76; object_sequence_definitions[26].sounds[6] = 77; object_sequence_definitions[26].sounds[7] = 78;
    /* Sequence 27. */
    object_sequence_definitions[27].start = 2772; object_sequence_definitions[27].end = 2780; object_sequence_definitions[27].final = 2781; object_sequence_definitions[27].next = 27;
    /* Sequence 28: prison door first stage. */
    object_sequence_definitions[28].start = 1516; object_sequence_definitions[28].end = 1516; object_sequence_definitions[28].final = 1516; object_sequence_definitions[28].next = 29;
    object_sequence_definitions[28].sounds[0] = 103; object_sequence_definitions[28].sounds[1] = 104; object_sequence_definitions[28].sounds[2] = 103; object_sequence_definitions[28].sounds[3] = 104;
    object_sequence_definitions[28].sounds[4] = 103; object_sequence_definitions[28].sounds[5] = 104; object_sequence_definitions[28].sounds[6] = 103; object_sequence_definitions[28].sounds[7] = 104;
    /* Sequence 29: prison door second stage. */
    object_sequence_definitions[29].start = 1517; object_sequence_definitions[29].end = 1521; object_sequence_definitions[29].final = 1521; object_sequence_definitions[29].next = 0;
    object_sequence_definitions[29].debris[0][0] = 59; object_sequence_definitions[29].debris[0][1] = 1; object_sequence_definitions[29].debris[0][2] = 4; object_sequence_definitions[29].debris[0][3] = 0;
    object_sequence_definitions[29].debris[1][0] = 60; object_sequence_definitions[29].debris[1][1] = 2; object_sequence_definitions[29].debris[1][2] = 3; object_sequence_definitions[29].debris[1][3] = 0;
    object_sequence_definitions[29].debris[2][0] = 61; object_sequence_definitions[29].debris[2][1] = 2; object_sequence_definitions[29].debris[2][2] = 5; object_sequence_definitions[29].debris[2][3] = 0;
    object_sequence_definitions[29].debris[3][0] = 62; object_sequence_definitions[29].debris[3][1] = 2; object_sequence_definitions[29].debris[3][2] = 3; object_sequence_definitions[29].debris[3][3] = 0;
    object_sequence_definitions[29].debris[4][0] = 63; object_sequence_definitions[29].debris[4][1] = 2; object_sequence_definitions[29].debris[4][2] = 2; object_sequence_definitions[29].debris[4][3] = 0;
    object_sequence_definitions[29].debris[5][0] = 64; object_sequence_definitions[29].debris[5][1] = 2; object_sequence_definitions[29].debris[5][2] = 4; object_sequence_definitions[29].debris[5][3] = 0;
    object_sequence_definitions[29].debris[6][0] = 65; object_sequence_definitions[29].debris[6][1] = 2; object_sequence_definitions[29].debris[6][2] = 4; object_sequence_definitions[29].debris[6][3] = 0;
    object_sequence_definitions[29].debris[7][0] = 62; object_sequence_definitions[29].debris[7][1] = 2; object_sequence_definitions[29].debris[7][2] = 3; object_sequence_definitions[29].debris[7][3] = 0;
    object_sequence_definitions[29].debris[8][0] = 63; object_sequence_definitions[29].debris[8][1] = 2; object_sequence_definitions[29].debris[8][2] = 2; object_sequence_definitions[29].debris[8][3] = 0;
    object_sequence_definitions[29].debris[9][0] = 64; object_sequence_definitions[29].debris[9][1] = 2; object_sequence_definitions[29].debris[9][2] = 4; object_sequence_definitions[29].debris[9][3] = 0;
    object_sequence_definitions[29].debris[10][0] = 65; object_sequence_definitions[29].debris[10][1] = 1; object_sequence_definitions[29].debris[10][2] = 2; object_sequence_definitions[29].debris[10][3] = 0;
    object_sequence_definitions[29].sounds[0] = 103; object_sequence_definitions[29].sounds[1] = 104; object_sequence_definitions[29].sounds[2] = 103; object_sequence_definitions[29].sounds[3] = 104;
    object_sequence_definitions[29].sounds[4] = 103; object_sequence_definitions[29].sounds[5] = 104; object_sequence_definitions[29].sounds[6] = 103; object_sequence_definitions[29].sounds[7] = 104;
    /* Sequence 30. */
    object_sequence_definitions[30].start = 1524; object_sequence_definitions[30].end = 1524; object_sequence_definitions[30].final = 1524; object_sequence_definitions[30].next = 0;
    /* Sequence 31. */
    object_sequence_definitions[31].start = 1525; object_sequence_definitions[31].end = 1525; object_sequence_definitions[31].final = 1525; object_sequence_definitions[31].next = 0;
    object_sequence_definitions[31].debris[0][0] = 4; object_sequence_definitions[31].debris[0][1] = 1; object_sequence_definitions[31].debris[0][2] = 5; object_sequence_definitions[31].debris[0][3] = 1;
    object_sequence_definitions[31].debris[1][0] = 5; object_sequence_definitions[31].debris[1][1] = 1; object_sequence_definitions[31].debris[1][2] = 4; object_sequence_definitions[31].debris[1][3] = 1;
    object_sequence_definitions[31].debris[2][0] = 6; object_sequence_definitions[31].debris[2][1] = 1; object_sequence_definitions[31].debris[2][2] = 6; object_sequence_definitions[31].debris[2][3] = 1;
    object_sequence_definitions[31].debris[3][0] = 7; object_sequence_definitions[31].debris[3][1] = 1; object_sequence_definitions[31].debris[3][2] = 5; object_sequence_definitions[31].debris[3][3] = 1;
    object_sequence_definitions[31].debris[4][0] = 8; object_sequence_definitions[31].debris[4][1] = 1; object_sequence_definitions[31].debris[4][2] = 5; object_sequence_definitions[31].debris[4][3] = 1;
    object_sequence_definitions[31].debris[5][0] = 9; object_sequence_definitions[31].debris[5][1] = 1; object_sequence_definitions[31].debris[5][2] = 6; object_sequence_definitions[31].debris[5][3] = 1;
    object_sequence_definitions[31].debris[6][0] = 10; object_sequence_definitions[31].debris[6][1] = 1; object_sequence_definitions[31].debris[6][2] = 5; object_sequence_definitions[31].debris[6][3] = 1;
    object_sequence_definitions[31].debris[7][0] = 11; object_sequence_definitions[31].debris[7][1] = 1; object_sequence_definitions[31].debris[7][2] = 4; object_sequence_definitions[31].debris[7][3] = 1;
    object_sequence_definitions[31].debris[8][0] = 7; object_sequence_definitions[31].debris[8][1] = 1; object_sequence_definitions[31].debris[8][2] = 4; object_sequence_definitions[31].debris[8][3] = 1;
    object_sequence_definitions[31].debris[9][0] = 8; object_sequence_definitions[31].debris[9][1] = 1; object_sequence_definitions[31].debris[9][2] = 5; object_sequence_definitions[31].debris[9][3] = 1;
    object_sequence_definitions[31].debris[10][0] = 9; object_sequence_definitions[31].debris[10][1] = 1; object_sequence_definitions[31].debris[10][2] = 4; object_sequence_definitions[31].debris[10][3] = 1;
    object_sequence_definitions[31].debris[11][0] = 10; object_sequence_definitions[31].debris[11][1] = 1; object_sequence_definitions[31].debris[11][2] = 3; object_sequence_definitions[31].debris[11][3] = 1;
    object_sequence_definitions[31].sounds[0] = 100; object_sequence_definitions[31].sounds[1] = 101; object_sequence_definitions[31].sounds[2] = 102; object_sequence_definitions[31].sounds[3] = 100;
    object_sequence_definitions[31].sounds[4] = 101; object_sequence_definitions[31].sounds[5] = 102; object_sequence_definitions[31].sounds[6] = 100; object_sequence_definitions[31].sounds[7] = 101;
    /* Sequence 32. */
    object_sequence_definitions[32].start = 1402; object_sequence_definitions[32].end = 1402; object_sequence_definitions[32].final = 1402; object_sequence_definitions[32].next = 0;
    /* Sequence 33. */
    object_sequence_definitions[33].start = 1400; object_sequence_definitions[33].end = 1400; object_sequence_definitions[33].final = 1400; object_sequence_definitions[33].next = 0;
    /* Sequence 34. */
    object_sequence_definitions[34].start = 1392; object_sequence_definitions[34].end = 1392; object_sequence_definitions[34].final = 1392; object_sequence_definitions[34].next = 35;
    /* Sequence 35. */
    object_sequence_definitions[35].start = 1393; object_sequence_definitions[35].end = 1393; object_sequence_definitions[35].final = 1393; object_sequence_definitions[35].next = 36;
    /* Sequence 36. */
    object_sequence_definitions[36].start = 1393; object_sequence_definitions[36].end = 1393; object_sequence_definitions[36].final = 1393; object_sequence_definitions[36].next = 0;
    /* Sequence 37. */
    object_sequence_definitions[37].start = 1398; object_sequence_definitions[37].end = 1398; object_sequence_definitions[37].final = 1398; object_sequence_definitions[37].next = 42;
    /* Sequence 38. */
    object_sequence_definitions[38].start = 1291; object_sequence_definitions[38].end = 1291; object_sequence_definitions[38].final = 1291; object_sequence_definitions[38].next = 0;
    object_sequence_definitions[38].debris[0][0] = 3; object_sequence_definitions[38].debris[0][1] = 1; object_sequence_definitions[38].debris[0][2] = 6; object_sequence_definitions[38].debris[0][3] = 0;
    object_sequence_definitions[38].debris[1][0] = 3; object_sequence_definitions[38].debris[1][1] = 1; object_sequence_definitions[38].debris[1][2] = 5; object_sequence_definitions[38].debris[1][3] = 0;
    object_sequence_definitions[38].debris[2][0] = 3; object_sequence_definitions[38].debris[2][1] = 1; object_sequence_definitions[38].debris[2][2] = 5; object_sequence_definitions[38].debris[2][3] = 0;
    object_sequence_definitions[38].debris[3][0] = 3; object_sequence_definitions[38].debris[3][1] = 1; object_sequence_definitions[38].debris[3][2] = 5; object_sequence_definitions[38].debris[3][3] = 0;
    object_sequence_definitions[38].debris[4][0] = 3; object_sequence_definitions[38].debris[4][1] = 1; object_sequence_definitions[38].debris[4][2] = 5; object_sequence_definitions[38].debris[4][3] = 0;
    object_sequence_definitions[38].debris[5][0] = 3; object_sequence_definitions[38].debris[5][1] = 1; object_sequence_definitions[38].debris[5][2] = 5; object_sequence_definitions[38].debris[5][3] = 0;
    object_sequence_definitions[38].debris[6][0] = 4; object_sequence_definitions[38].debris[6][1] = 1; object_sequence_definitions[38].debris[6][2] = 6; object_sequence_definitions[38].debris[6][3] = 1;
    object_sequence_definitions[38].debris[7][0] = 5; object_sequence_definitions[38].debris[7][1] = 1; object_sequence_definitions[38].debris[7][2] = 4; object_sequence_definitions[38].debris[7][3] = 1;
    object_sequence_definitions[38].debris[8][0] = 6; object_sequence_definitions[38].debris[8][1] = 1; object_sequence_definitions[38].debris[8][2] = 4; object_sequence_definitions[38].debris[8][3] = 1;
    object_sequence_definitions[38].debris[9][0] = 7; object_sequence_definitions[38].debris[9][1] = 1; object_sequence_definitions[38].debris[9][2] = 4; object_sequence_definitions[38].debris[9][3] = 1;
    object_sequence_definitions[38].debris[10][0] = 8; object_sequence_definitions[38].debris[10][1] = 1; object_sequence_definitions[38].debris[10][2] = 5; object_sequence_definitions[38].debris[10][3] = 1;
    object_sequence_definitions[38].debris[11][0] = 9; object_sequence_definitions[38].debris[11][1] = 1; object_sequence_definitions[38].debris[11][2] = 5; object_sequence_definitions[38].debris[11][3] = 1;
    object_sequence_definitions[38].sounds[0] = 95; object_sequence_definitions[38].sounds[1] = 96; object_sequence_definitions[38].sounds[2] = 97; object_sequence_definitions[38].sounds[3] = 98;
    object_sequence_definitions[38].sounds[4] = 95; object_sequence_definitions[38].sounds[5] = 96; object_sequence_definitions[38].sounds[6] = 97; object_sequence_definitions[38].sounds[7] = 98;
    /* Sequence 39. */
    object_sequence_definitions[39].start = 957; object_sequence_definitions[39].end = 966; object_sequence_definitions[39].final = 0; object_sequence_definitions[39].next = 0;
    object_sequence_definitions[39].sounds[0] = 95; object_sequence_definitions[39].sounds[1] = 96; object_sequence_definitions[39].sounds[2] = 97; object_sequence_definitions[39].sounds[3] = 98;
    object_sequence_definitions[39].sounds[4] = 95; object_sequence_definitions[39].sounds[5] = 96; object_sequence_definitions[39].sounds[6] = 97; object_sequence_definitions[39].sounds[7] = 98;
    /* Sequence 40. */
    object_sequence_definitions[40].start = 917; object_sequence_definitions[40].end = 926; object_sequence_definitions[40].final = 0; object_sequence_definitions[40].next = 0;
    object_sequence_definitions[40].debris[0][0] = 53; object_sequence_definitions[40].debris[0][1] = 1; object_sequence_definitions[40].debris[0][2] = 5; object_sequence_definitions[40].debris[0][3] = 0;
    object_sequence_definitions[40].debris[1][0] = 54; object_sequence_definitions[40].debris[1][1] = 1; object_sequence_definitions[40].debris[1][2] = 6; object_sequence_definitions[40].debris[1][3] = 1;
    object_sequence_definitions[40].debris[2][0] = 55; object_sequence_definitions[40].debris[2][1] = 1; object_sequence_definitions[40].debris[2][2] = 6; object_sequence_definitions[40].debris[2][3] = 0;
    object_sequence_definitions[40].debris[3][0] = 56; object_sequence_definitions[40].debris[3][1] = 1; object_sequence_definitions[40].debris[3][2] = 5; object_sequence_definitions[40].debris[3][3] = 1;
    object_sequence_definitions[40].debris[4][0] = 57; object_sequence_definitions[40].debris[4][1] = 1; object_sequence_definitions[40].debris[4][2] = 4; object_sequence_definitions[40].debris[4][3] = 0;
    object_sequence_definitions[40].debris[5][0] = 56; object_sequence_definitions[40].debris[5][1] = 1; object_sequence_definitions[40].debris[5][2] = 5; object_sequence_definitions[40].debris[5][3] = 0;
    object_sequence_definitions[40].debris[6][0] = 55; object_sequence_definitions[40].debris[6][1] = 1; object_sequence_definitions[40].debris[6][2] = 6; object_sequence_definitions[40].debris[6][3] = 1;
    object_sequence_definitions[40].debris[7][0] = 58; object_sequence_definitions[40].debris[7][1] = 1; object_sequence_definitions[40].debris[7][2] = 5; object_sequence_definitions[40].debris[7][3] = 0;
    object_sequence_definitions[40].debris[8][0] = 53; object_sequence_definitions[40].debris[8][1] = 1; object_sequence_definitions[40].debris[8][2] = 5; object_sequence_definitions[40].debris[8][3] = 1;
    object_sequence_definitions[40].debris[9][0] = 57; object_sequence_definitions[40].debris[9][1] = 1; object_sequence_definitions[40].debris[9][2] = 4; object_sequence_definitions[40].debris[9][3] = 0;
    object_sequence_definitions[40].debris[10][0] = 55; object_sequence_definitions[40].debris[10][1] = 1; object_sequence_definitions[40].debris[10][2] = 5; object_sequence_definitions[40].debris[10][3] = 0;
    object_sequence_definitions[40].debris[11][0] = 56; object_sequence_definitions[40].debris[11][1] = 1; object_sequence_definitions[40].debris[11][2] = 5; object_sequence_definitions[40].debris[11][3] = 0;
    object_sequence_definitions[40].sounds[0] = 95; object_sequence_definitions[40].sounds[1] = 96; object_sequence_definitions[40].sounds[2] = 97; object_sequence_definitions[40].sounds[3] = 98;
    object_sequence_definitions[40].sounds[4] = 95; object_sequence_definitions[40].sounds[5] = 96; object_sequence_definitions[40].sounds[6] = 97; object_sequence_definitions[40].sounds[7] = 98;
    /* Sequence 41. */
    object_sequence_definitions[41].start = 910; object_sequence_definitions[41].end = 916; object_sequence_definitions[41].final = 0; object_sequence_definitions[41].next = 0;
    object_sequence_definitions[41].debris[0][0] = 53; object_sequence_definitions[41].debris[0][1] = 1; object_sequence_definitions[41].debris[0][2] = 5; object_sequence_definitions[41].debris[0][3] = 1;
    object_sequence_definitions[41].debris[1][0] = 54; object_sequence_definitions[41].debris[1][1] = 1; object_sequence_definitions[41].debris[1][2] = 4; object_sequence_definitions[41].debris[1][3] = 1;
    object_sequence_definitions[41].debris[2][0] = 55; object_sequence_definitions[41].debris[2][1] = 1; object_sequence_definitions[41].debris[2][2] = 4; object_sequence_definitions[41].debris[2][3] = 1;
    object_sequence_definitions[41].debris[3][0] = 56; object_sequence_definitions[41].debris[3][1] = 1; object_sequence_definitions[41].debris[3][2] = 5; object_sequence_definitions[41].debris[3][3] = 1;
    object_sequence_definitions[41].debris[4][0] = 57; object_sequence_definitions[41].debris[4][1] = 1; object_sequence_definitions[41].debris[4][2] = 4; object_sequence_definitions[41].debris[4][3] = 1;
    object_sequence_definitions[41].debris[5][0] = 58; object_sequence_definitions[41].debris[5][1] = 1; object_sequence_definitions[41].debris[5][2] = 4; object_sequence_definitions[41].debris[5][3] = 1;
    object_sequence_definitions[41].debris[6][0] = 56; object_sequence_definitions[41].debris[6][1] = 1; object_sequence_definitions[41].debris[6][2] = 5; object_sequence_definitions[41].debris[6][3] = 1;
    object_sequence_definitions[41].debris[7][0] = 55; object_sequence_definitions[41].debris[7][1] = 1; object_sequence_definitions[41].debris[7][2] = 4; object_sequence_definitions[41].debris[7][3] = 1;
    object_sequence_definitions[41].debris[8][0] = 32; object_sequence_definitions[41].debris[8][1] = 1; object_sequence_definitions[41].debris[8][2] = 4; object_sequence_definitions[41].debris[8][3] = 1;
    object_sequence_definitions[41].debris[9][0] = 33; object_sequence_definitions[41].debris[9][1] = 1; object_sequence_definitions[41].debris[9][2] = 4; object_sequence_definitions[41].debris[9][3] = 1;
    object_sequence_definitions[41].debris[10][0] = 34; object_sequence_definitions[41].debris[10][1] = 1; object_sequence_definitions[41].debris[10][2] = 4; object_sequence_definitions[41].debris[10][3] = 1;
    object_sequence_definitions[41].debris[11][0] = 31; object_sequence_definitions[41].debris[11][1] = 1; object_sequence_definitions[41].debris[11][2] = 5; object_sequence_definitions[41].debris[11][3] = 1;
    object_sequence_definitions[41].sounds[0] = 95; object_sequence_definitions[41].sounds[1] = 96; object_sequence_definitions[41].sounds[2] = 97; object_sequence_definitions[41].sounds[3] = 98;
    object_sequence_definitions[41].sounds[4] = 95; object_sequence_definitions[41].sounds[5] = 96; object_sequence_definitions[41].sounds[6] = 97; object_sequence_definitions[41].sounds[7] = 98;
    /* Sequence 42. */
    object_sequence_definitions[42].start = 827; object_sequence_definitions[42].end = 832; object_sequence_definitions[42].final = 0; object_sequence_definitions[42].next = 0;
    object_sequence_definitions[42].debris[0][0] = 52; object_sequence_definitions[42].debris[0][1] = 1; object_sequence_definitions[42].debris[0][2] = 4; object_sequence_definitions[42].debris[0][3] = 0;
    object_sequence_definitions[42].debris[1][0] = 53; object_sequence_definitions[42].debris[1][1] = 0; object_sequence_definitions[42].debris[1][2] = 6; object_sequence_definitions[42].debris[1][3] = 0;
    object_sequence_definitions[42].debris[2][0] = 54; object_sequence_definitions[42].debris[2][1] = 0; object_sequence_definitions[42].debris[2][2] = 4; object_sequence_definitions[42].debris[2][3] = 0;
    object_sequence_definitions[42].debris[3][0] = 55; object_sequence_definitions[42].debris[3][1] = 0; object_sequence_definitions[42].debris[3][2] = 4; object_sequence_definitions[42].debris[3][3] = 0;
    object_sequence_definitions[42].debris[4][0] = 56; object_sequence_definitions[42].debris[4][1] = 0; object_sequence_definitions[42].debris[4][2] = 3; object_sequence_definitions[42].debris[4][3] = 0;
    object_sequence_definitions[42].debris[5][0] = 57; object_sequence_definitions[42].debris[5][1] = 0; object_sequence_definitions[42].debris[5][2] = 2; object_sequence_definitions[42].debris[5][3] = 0;
    object_sequence_definitions[42].debris[6][0] = 58; object_sequence_definitions[42].debris[6][1] = 0; object_sequence_definitions[42].debris[6][2] = 3; object_sequence_definitions[42].debris[6][3] = 0;
    object_sequence_definitions[42].debris[7][0] = 52; object_sequence_definitions[42].debris[7][1] = 1; object_sequence_definitions[42].debris[7][2] = 4; object_sequence_definitions[42].debris[7][3] = 0;
    object_sequence_definitions[42].debris[8][0] = 52; object_sequence_definitions[42].debris[8][1] = 1; object_sequence_definitions[42].debris[8][2] = 6; object_sequence_definitions[42].debris[8][3] = 0;
    object_sequence_definitions[42].debris[9][0] = 52; object_sequence_definitions[42].debris[9][1] = 1; object_sequence_definitions[42].debris[9][2] = 5; object_sequence_definitions[42].debris[9][3] = 0;
    object_sequence_definitions[42].sounds[0] = 95; object_sequence_definitions[42].sounds[1] = 96; object_sequence_definitions[42].sounds[2] = 97; object_sequence_definitions[42].sounds[3] = 98;
    object_sequence_definitions[42].sounds[4] = 95; object_sequence_definitions[42].sounds[5] = 96; object_sequence_definitions[42].sounds[6] = 97; object_sequence_definitions[42].sounds[7] = 98;
    /* Sequence 43. */
    object_sequence_definitions[43].start = 886; object_sequence_definitions[43].end = 890; object_sequence_definitions[43].final = 890; object_sequence_definitions[43].next = 43;
    /* Sequence 44. */
    object_sequence_definitions[44].start = 942; object_sequence_definitions[44].end = 944; object_sequence_definitions[44].final = 944; object_sequence_definitions[44].next = 44;
    /* Sequence 45. */
    object_sequence_definitions[45].start = 945; object_sequence_definitions[45].end = 947; object_sequence_definitions[45].final = 947; object_sequence_definitions[45].next = 45;
    /* Sequence 46. */
    object_sequence_definitions[46].start = 2662; object_sequence_definitions[46].end = 2670; object_sequence_definitions[46].final = 2671; object_sequence_definitions[46].next = 47;
    object_sequence_definitions[46].sounds[0] = 89; object_sequence_definitions[46].sounds[1] = 90; object_sequence_definitions[46].sounds[2] = 91; object_sequence_definitions[46].sounds[3] = 92;
    object_sequence_definitions[46].sounds[4] = 89; object_sequence_definitions[46].sounds[5] = 90; object_sequence_definitions[46].sounds[6] = 91; object_sequence_definitions[46].sounds[7] = 92;
    /* Sequence 47. */
    object_sequence_definitions[47].start = 2662; object_sequence_definitions[47].end = 2670; object_sequence_definitions[47].final = 2671; object_sequence_definitions[47].next = 47;
    /* Sequence 48. */
    object_sequence_definitions[48].start = 866; object_sequence_definitions[48].end = 869; object_sequence_definitions[48].final = 0; object_sequence_definitions[48].next = 0;
    object_sequence_definitions[48].sounds[0] = 80; object_sequence_definitions[48].sounds[1] = 80; object_sequence_definitions[48].sounds[2] = 80; object_sequence_definitions[48].sounds[3] = 80;
    object_sequence_definitions[48].sounds[4] = 80; object_sequence_definitions[48].sounds[5] = 80; object_sequence_definitions[48].sounds[6] = 80; object_sequence_definitions[48].sounds[7] = 80;
    /* Sequence 49. */
    object_sequence_definitions[49].start = 1200; object_sequence_definitions[49].end = 1205; object_sequence_definitions[49].final = 1206; object_sequence_definitions[49].next = 0;
    object_sequence_definitions[49].debris[0][0] = 75; object_sequence_definitions[49].debris[0][1] = 1; object_sequence_definitions[49].debris[0][2] = 4; object_sequence_definitions[49].debris[0][3] = 0;
    object_sequence_definitions[49].debris[1][0] = 76; object_sequence_definitions[49].debris[1][1] = 1; object_sequence_definitions[49].debris[1][2] = 3; object_sequence_definitions[49].debris[1][3] = 0;
    object_sequence_definitions[49].debris[2][0] = 77; object_sequence_definitions[49].debris[2][1] = 1; object_sequence_definitions[49].debris[2][2] = 3; object_sequence_definitions[49].debris[2][3] = 0;
    object_sequence_definitions[49].debris[3][0] = 78; object_sequence_definitions[49].debris[3][1] = 1; object_sequence_definitions[49].debris[3][2] = 3; object_sequence_definitions[49].debris[3][3] = 0;
    object_sequence_definitions[49].debris[4][0] = 75; object_sequence_definitions[49].debris[4][1] = 1; object_sequence_definitions[49].debris[4][2] = 3; object_sequence_definitions[49].debris[4][3] = 0;
    object_sequence_definitions[49].debris[5][0] = 76; object_sequence_definitions[49].debris[5][1] = 1; object_sequence_definitions[49].debris[5][2] = 3; object_sequence_definitions[49].debris[5][3] = 0;
    object_sequence_definitions[49].debris[6][0] = 77; object_sequence_definitions[49].debris[6][1] = 1; object_sequence_definitions[49].debris[6][2] = 3; object_sequence_definitions[49].debris[6][3] = 0;
    object_sequence_definitions[49].debris[7][0] = 78; object_sequence_definitions[49].debris[7][1] = 1; object_sequence_definitions[49].debris[7][2] = 3; object_sequence_definitions[49].debris[7][3] = 0;
    object_sequence_definitions[49].debris[8][0] = 75; object_sequence_definitions[49].debris[8][1] = 1; object_sequence_definitions[49].debris[8][2] = 3; object_sequence_definitions[49].debris[8][3] = 0;
    object_sequence_definitions[49].debris[9][0] = 76; object_sequence_definitions[49].debris[9][1] = 1; object_sequence_definitions[49].debris[9][2] = 3; object_sequence_definitions[49].debris[9][3] = 0;
    object_sequence_definitions[49].debris[10][0] = 77; object_sequence_definitions[49].debris[10][1] = 1; object_sequence_definitions[49].debris[10][2] = 3; object_sequence_definitions[49].debris[10][3] = 0;
    object_sequence_definitions[49].debris[11][0] = 78; object_sequence_definitions[49].debris[11][1] = 1; object_sequence_definitions[49].debris[11][2] = 3; object_sequence_definitions[49].debris[11][3] = 0;
    object_sequence_definitions[49].sounds[0] = 95; object_sequence_definitions[49].sounds[1] = 96; object_sequence_definitions[49].sounds[2] = 97; object_sequence_definitions[49].sounds[3] = 98;
    object_sequence_definitions[49].sounds[4] = 95; object_sequence_definitions[49].sounds[5] = 96; object_sequence_definitions[49].sounds[6] = 97; object_sequence_definitions[49].sounds[7] = 98;
    /* Sequence 50: barrel sequence. */
    object_sequence_definitions[50].start = 1014; object_sequence_definitions[50].end = 1019; object_sequence_definitions[50].final = 0; object_sequence_definitions[50].next = 0;
    object_sequence_definitions[50].debris[0][0] = 59; object_sequence_definitions[50].debris[0][1] = 1; object_sequence_definitions[50].debris[0][2] = 4; object_sequence_definitions[50].debris[0][3] = 0;
    object_sequence_definitions[50].debris[1][0] = 60; object_sequence_definitions[50].debris[1][1] = 2; object_sequence_definitions[50].debris[1][2] = 3; object_sequence_definitions[50].debris[1][3] = 0;
    object_sequence_definitions[50].debris[2][0] = 61; object_sequence_definitions[50].debris[2][1] = 2; object_sequence_definitions[50].debris[2][2] = 5; object_sequence_definitions[50].debris[2][3] = 0;
    object_sequence_definitions[50].debris[3][0] = 62; object_sequence_definitions[50].debris[3][1] = 2; object_sequence_definitions[50].debris[3][2] = 3; object_sequence_definitions[50].debris[3][3] = 0;
    object_sequence_definitions[50].debris[4][0] = 63; object_sequence_definitions[50].debris[4][1] = 2; object_sequence_definitions[50].debris[4][2] = 2; object_sequence_definitions[50].debris[4][3] = 0;
    object_sequence_definitions[50].debris[5][0] = 64; object_sequence_definitions[50].debris[5][1] = 2; object_sequence_definitions[50].debris[5][2] = 4; object_sequence_definitions[50].debris[5][3] = 0;
    object_sequence_definitions[50].debris[6][0] = 65; object_sequence_definitions[50].debris[6][1] = 2; object_sequence_definitions[50].debris[6][2] = 4; object_sequence_definitions[50].debris[6][3] = 0;
    object_sequence_definitions[50].debris[7][0] = 62; object_sequence_definitions[50].debris[7][1] = 2; object_sequence_definitions[50].debris[7][2] = 3; object_sequence_definitions[50].debris[7][3] = 0;
    object_sequence_definitions[50].debris[8][0] = 63; object_sequence_definitions[50].debris[8][1] = 2; object_sequence_definitions[50].debris[8][2] = 2; object_sequence_definitions[50].debris[8][3] = 0;
    object_sequence_definitions[50].debris[9][0] = 64; object_sequence_definitions[50].debris[9][1] = 2; object_sequence_definitions[50].debris[9][2] = 4; object_sequence_definitions[50].debris[9][3] = 0;
    object_sequence_definitions[50].debris[10][0] = 72; object_sequence_definitions[50].debris[10][1] = 0; object_sequence_definitions[50].debris[10][2] = 2; object_sequence_definitions[50].debris[10][3] = 0;
    object_sequence_definitions[50].debris[11][0] = 73; object_sequence_definitions[50].debris[11][1] = 0; object_sequence_definitions[50].debris[11][2] = 2; object_sequence_definitions[50].debris[11][3] = 0;
    object_sequence_definitions[50].sounds[0] = 103; object_sequence_definitions[50].sounds[1] = 104; object_sequence_definitions[50].sounds[2] = 103; object_sequence_definitions[50].sounds[3] = 104;
    object_sequence_definitions[50].sounds[4] = 103; object_sequence_definitions[50].sounds[5] = 104; object_sequence_definitions[50].sounds[6] = 103; object_sequence_definitions[50].sounds[7] = 104;
    /* Sequence 51. */
    object_sequence_definitions[51].start = 1008; object_sequence_definitions[51].end = 1013; object_sequence_definitions[51].final = 1013; object_sequence_definitions[51].next = 51;
    /* Sequence 52. */
    object_sequence_definitions[52].start = 358; object_sequence_definitions[52].end = 361; object_sequence_definitions[52].final = 361; object_sequence_definitions[52].next = 0;
    /* Sequence 53. */
    object_sequence_definitions[53].start = 1014; object_sequence_definitions[53].end = 1019; object_sequence_definitions[53].final = 0; object_sequence_definitions[53].next = 0;
    object_sequence_definitions[53].debris[0][0] = 59; object_sequence_definitions[53].debris[0][1] = 1; object_sequence_definitions[53].debris[0][2] = 4; object_sequence_definitions[53].debris[0][3] = 0;
    object_sequence_definitions[53].debris[1][0] = 60; object_sequence_definitions[53].debris[1][1] = 2; object_sequence_definitions[53].debris[1][2] = 3; object_sequence_definitions[53].debris[1][3] = 0;
    object_sequence_definitions[53].debris[2][0] = 61; object_sequence_definitions[53].debris[2][1] = 2; object_sequence_definitions[53].debris[2][2] = 5; object_sequence_definitions[53].debris[2][3] = 0;
    object_sequence_definitions[53].debris[3][0] = 62; object_sequence_definitions[53].debris[3][1] = 2; object_sequence_definitions[53].debris[3][2] = 3; object_sequence_definitions[53].debris[3][3] = 0;
    object_sequence_definitions[53].debris[4][0] = 63; object_sequence_definitions[53].debris[4][1] = 2; object_sequence_definitions[53].debris[4][2] = 2; object_sequence_definitions[53].debris[4][3] = 0;
    object_sequence_definitions[53].debris[5][0] = 64; object_sequence_definitions[53].debris[5][1] = 2; object_sequence_definitions[53].debris[5][2] = 4; object_sequence_definitions[53].debris[5][3] = 0;
    object_sequence_definitions[53].debris[6][0] = 65; object_sequence_definitions[53].debris[6][1] = 2; object_sequence_definitions[53].debris[6][2] = 4; object_sequence_definitions[53].debris[6][3] = 0;
    object_sequence_definitions[53].debris[7][0] = 62; object_sequence_definitions[53].debris[7][1] = 2; object_sequence_definitions[53].debris[7][2] = 3; object_sequence_definitions[53].debris[7][3] = 0;
    object_sequence_definitions[53].debris[8][0] = 63; object_sequence_definitions[53].debris[8][1] = 2; object_sequence_definitions[53].debris[8][2] = 2; object_sequence_definitions[53].debris[8][3] = 0;
    object_sequence_definitions[53].debris[9][0] = 64; object_sequence_definitions[53].debris[9][1] = 2; object_sequence_definitions[53].debris[9][2] = 4; object_sequence_definitions[53].debris[9][3] = 0;
    object_sequence_definitions[53].debris[10][0] = 65; object_sequence_definitions[53].debris[10][1] = 1; object_sequence_definitions[53].debris[10][2] = 2; object_sequence_definitions[53].debris[10][3] = 0;
    object_sequence_definitions[53].debris[11][0] = 74; object_sequence_definitions[53].debris[11][1] = 0; object_sequence_definitions[53].debris[11][2] = 2; object_sequence_definitions[53].debris[11][3] = 0;
    object_sequence_definitions[53].sounds[0] = 103; object_sequence_definitions[53].sounds[1] = 104; object_sequence_definitions[53].sounds[2] = 103; object_sequence_definitions[53].sounds[3] = 104;
    object_sequence_definitions[53].sounds[4] = 103; object_sequence_definitions[53].sounds[5] = 104; object_sequence_definitions[53].sounds[6] = 103; object_sequence_definitions[53].sounds[7] = 104;
    /* Sequence 54. */
    object_sequence_definitions[54].start = 2552; object_sequence_definitions[54].end = 2560; object_sequence_definitions[54].final = 2561; object_sequence_definitions[54].next = 6;
    object_sequence_definitions[54].debris[0][0] = 37; object_sequence_definitions[54].debris[0][1] = 1; object_sequence_definitions[54].debris[0][2] = 5; object_sequence_definitions[54].debris[0][3] = 0;
    object_sequence_definitions[54].debris[1][0] = 88; object_sequence_definitions[54].debris[1][1] = 0; object_sequence_definitions[54].debris[1][2] = 3; object_sequence_definitions[54].debris[1][3] = 0;
    object_sequence_definitions[54].debris[2][0] = 88; object_sequence_definitions[54].debris[2][1] = 1; object_sequence_definitions[54].debris[2][2] = 4; object_sequence_definitions[54].debris[2][3] = 0;
    object_sequence_definitions[54].debris[3][0] = 88; object_sequence_definitions[54].debris[3][1] = 1; object_sequence_definitions[54].debris[3][2] = 5; object_sequence_definitions[54].debris[3][3] = 0;
    object_sequence_definitions[54].debris[4][0] = 88; object_sequence_definitions[54].debris[4][1] = 1; object_sequence_definitions[54].debris[4][2] = 4; object_sequence_definitions[54].debris[4][3] = 0;
    object_sequence_definitions[54].debris[5][0] = 88; object_sequence_definitions[54].debris[5][1] = 1; object_sequence_definitions[54].debris[5][2] = 4; object_sequence_definitions[54].debris[5][3] = 0;
    object_sequence_definitions[54].debris[6][0] = 88; object_sequence_definitions[54].debris[6][1] = 1; object_sequence_definitions[54].debris[6][2] = 5; object_sequence_definitions[54].debris[6][3] = 0;
    object_sequence_definitions[54].debris[7][0] = 88; object_sequence_definitions[54].debris[7][1] = 1; object_sequence_definitions[54].debris[7][2] = 5; object_sequence_definitions[54].debris[7][3] = 0;
    object_sequence_definitions[54].debris[8][0] = 88; object_sequence_definitions[54].debris[8][1] = 1; object_sequence_definitions[54].debris[8][2] = 3; object_sequence_definitions[54].debris[8][3] = 0;
    object_sequence_definitions[54].sounds[0] = 60; object_sequence_definitions[54].sounds[1] = 61; object_sequence_definitions[54].sounds[2] = 62; object_sequence_definitions[54].sounds[3] = 63;
    object_sequence_definitions[54].sounds[4] = 60; object_sequence_definitions[54].sounds[5] = 61; object_sequence_definitions[54].sounds[6] = 62; object_sequence_definitions[54].sounds[7] = 63;
    /* Sequence 55: barrel sequence. */
    object_sequence_definitions[55].start = 1014; object_sequence_definitions[55].end = 1019; object_sequence_definitions[55].final = 0; object_sequence_definitions[55].next = 0;
    object_sequence_definitions[55].debris[0][0] = 59; object_sequence_definitions[55].debris[0][1] = 1; object_sequence_definitions[55].debris[0][2] = 4; object_sequence_definitions[55].debris[0][3] = 0;
    object_sequence_definitions[55].debris[1][0] = 60; object_sequence_definitions[55].debris[1][1] = 2; object_sequence_definitions[55].debris[1][2] = 3; object_sequence_definitions[55].debris[1][3] = 0;
    object_sequence_definitions[55].debris[2][0] = 61; object_sequence_definitions[55].debris[2][1] = 2; object_sequence_definitions[55].debris[2][2] = 5; object_sequence_definitions[55].debris[2][3] = 0;
    object_sequence_definitions[55].debris[3][0] = 62; object_sequence_definitions[55].debris[3][1] = 2; object_sequence_definitions[55].debris[3][2] = 3; object_sequence_definitions[55].debris[3][3] = 0;
    object_sequence_definitions[55].debris[4][0] = 63; object_sequence_definitions[55].debris[4][1] = 2; object_sequence_definitions[55].debris[4][2] = 2; object_sequence_definitions[55].debris[4][3] = 0;
    object_sequence_definitions[55].debris[5][0] = 64; object_sequence_definitions[55].debris[5][1] = 2; object_sequence_definitions[55].debris[5][2] = 4; object_sequence_definitions[55].debris[5][3] = 0;
    object_sequence_definitions[55].debris[6][0] = 65; object_sequence_definitions[55].debris[6][1] = 2; object_sequence_definitions[55].debris[6][2] = 4; object_sequence_definitions[55].debris[6][3] = 0;
    object_sequence_definitions[55].debris[7][0] = 62; object_sequence_definitions[55].debris[7][1] = 2; object_sequence_definitions[55].debris[7][2] = 3; object_sequence_definitions[55].debris[7][3] = 0;
    object_sequence_definitions[55].debris[8][0] = 63; object_sequence_definitions[55].debris[8][1] = 2; object_sequence_definitions[55].debris[8][2] = 2; object_sequence_definitions[55].debris[8][3] = 0;
    object_sequence_definitions[55].debris[9][0] = 64; object_sequence_definitions[55].debris[9][1] = 2; object_sequence_definitions[55].debris[9][2] = 4; object_sequence_definitions[55].debris[9][3] = 0;
    object_sequence_definitions[55].debris[10][0] = 65; object_sequence_definitions[55].debris[10][1] = 1; object_sequence_definitions[55].debris[10][2] = 2; object_sequence_definitions[55].debris[10][3] = 0;
    object_sequence_definitions[55].debris[11][0] = 62; object_sequence_definitions[55].debris[11][1] = 1; object_sequence_definitions[55].debris[11][2] = 3; object_sequence_definitions[55].debris[11][3] = 0;
    object_sequence_definitions[55].sounds[0] = 103; object_sequence_definitions[55].sounds[1] = 104; object_sequence_definitions[55].sounds[2] = 103; object_sequence_definitions[55].sounds[3] = 104;
    object_sequence_definitions[55].sounds[4] = 103; object_sequence_definitions[55].sounds[5] = 104; object_sequence_definitions[55].sounds[6] = 103; object_sequence_definitions[55].sounds[7] = 104;
    /* Sequence 56. */
    object_sequence_definitions[56].start = 1213; object_sequence_definitions[56].end = 1218; object_sequence_definitions[56].final = 863; object_sequence_definitions[56].next = 0;
    object_sequence_definitions[56].debris[0][0] = 75; object_sequence_definitions[56].debris[0][1] = 1; object_sequence_definitions[56].debris[0][2] = 4; object_sequence_definitions[56].debris[0][3] = 0;
    object_sequence_definitions[56].debris[1][0] = 76; object_sequence_definitions[56].debris[1][1] = 1; object_sequence_definitions[56].debris[1][2] = 3; object_sequence_definitions[56].debris[1][3] = 0;
    object_sequence_definitions[56].debris[2][0] = 77; object_sequence_definitions[56].debris[2][1] = 1; object_sequence_definitions[56].debris[2][2] = 3; object_sequence_definitions[56].debris[2][3] = 0;
    object_sequence_definitions[56].debris[3][0] = 78; object_sequence_definitions[56].debris[3][1] = 1; object_sequence_definitions[56].debris[3][2] = 3; object_sequence_definitions[56].debris[3][3] = 0;
    object_sequence_definitions[56].debris[4][0] = 75; object_sequence_definitions[56].debris[4][1] = 1; object_sequence_definitions[56].debris[4][2] = 3; object_sequence_definitions[56].debris[4][3] = 0;
    object_sequence_definitions[56].debris[5][0] = 76; object_sequence_definitions[56].debris[5][1] = 1; object_sequence_definitions[56].debris[5][2] = 3; object_sequence_definitions[56].debris[5][3] = 0;
    object_sequence_definitions[56].debris[6][0] = 77; object_sequence_definitions[56].debris[6][1] = 1; object_sequence_definitions[56].debris[6][2] = 3; object_sequence_definitions[56].debris[6][3] = 0;
    object_sequence_definitions[56].debris[7][0] = 78; object_sequence_definitions[56].debris[7][1] = 1; object_sequence_definitions[56].debris[7][2] = 3; object_sequence_definitions[56].debris[7][3] = 0;
    object_sequence_definitions[56].debris[8][0] = 75; object_sequence_definitions[56].debris[8][1] = 1; object_sequence_definitions[56].debris[8][2] = 3; object_sequence_definitions[56].debris[8][3] = 0;
    object_sequence_definitions[56].debris[9][0] = 76; object_sequence_definitions[56].debris[9][1] = 1; object_sequence_definitions[56].debris[9][2] = 3; object_sequence_definitions[56].debris[9][3] = 0;
    object_sequence_definitions[56].debris[10][0] = 77; object_sequence_definitions[56].debris[10][1] = 1; object_sequence_definitions[56].debris[10][2] = 3; object_sequence_definitions[56].debris[10][3] = 0;
    object_sequence_definitions[56].debris[11][0] = 78; object_sequence_definitions[56].debris[11][1] = 1; object_sequence_definitions[56].debris[11][2] = 3; object_sequence_definitions[56].debris[11][3] = 0;
    object_sequence_definitions[56].sounds[0] = 95; object_sequence_definitions[56].sounds[1] = 96; object_sequence_definitions[56].sounds[2] = 97; object_sequence_definitions[56].sounds[3] = 98;
    object_sequence_definitions[56].sounds[4] = 95; object_sequence_definitions[56].sounds[5] = 96; object_sequence_definitions[56].sounds[6] = 97; object_sequence_definitions[56].sounds[7] = 98;
    /* Sequence 57. */
    object_sequence_definitions[57].start = 1219; object_sequence_definitions[57].end = 1219; object_sequence_definitions[57].final = 1219; object_sequence_definitions[57].next = 59;
    object_sequence_definitions[57].debris[0][0] = 79; object_sequence_definitions[57].debris[0][1] = 3; object_sequence_definitions[57].debris[0][2] = 6; object_sequence_definitions[57].debris[0][3] = 0;
    object_sequence_definitions[57].debris[1][0] = 80; object_sequence_definitions[57].debris[1][1] = 2; object_sequence_definitions[57].debris[1][2] = 5; object_sequence_definitions[57].debris[1][3] = 0;
    object_sequence_definitions[57].debris[2][0] = 81; object_sequence_definitions[57].debris[2][1] = 3; object_sequence_definitions[57].debris[2][2] = 5; object_sequence_definitions[57].debris[2][3] = 1;
    object_sequence_definitions[57].debris[3][0] = 79; object_sequence_definitions[57].debris[3][1] = 2; object_sequence_definitions[57].debris[3][2] = 5; object_sequence_definitions[57].debris[3][3] = 1;
    object_sequence_definitions[57].debris[4][0] = 80; object_sequence_definitions[57].debris[4][1] = 4; object_sequence_definitions[57].debris[4][2] = 6; object_sequence_definitions[57].debris[4][3] = 0;
    object_sequence_definitions[57].debris[5][0] = 81; object_sequence_definitions[57].debris[5][1] = 3; object_sequence_definitions[57].debris[5][2] = 5; object_sequence_definitions[57].debris[5][3] = 1;
    object_sequence_definitions[57].debris[6][0] = 79; object_sequence_definitions[57].debris[6][1] = 3; object_sequence_definitions[57].debris[6][2] = 6; object_sequence_definitions[57].debris[6][3] = 0;
    object_sequence_definitions[57].debris[7][0] = 80; object_sequence_definitions[57].debris[7][1] = 4; object_sequence_definitions[57].debris[7][2] = 5; object_sequence_definitions[57].debris[7][3] = 1;
    object_sequence_definitions[57].debris[8][0] = 81; object_sequence_definitions[57].debris[8][1] = 2; object_sequence_definitions[57].debris[8][2] = 6; object_sequence_definitions[57].debris[8][3] = 0;
    object_sequence_definitions[57].debris[9][0] = 80; object_sequence_definitions[57].debris[9][1] = 3; object_sequence_definitions[57].debris[9][2] = 5; object_sequence_definitions[57].debris[9][3] = 1;
    object_sequence_definitions[57].sounds[0] = 100; object_sequence_definitions[57].sounds[1] = 101; object_sequence_definitions[57].sounds[2] = 102; object_sequence_definitions[57].sounds[3] = 100;
    object_sequence_definitions[57].sounds[4] = 101; object_sequence_definitions[57].sounds[5] = 102; object_sequence_definitions[57].sounds[6] = 100; object_sequence_definitions[57].sounds[7] = 101;
    /* Sequence 58. */
    object_sequence_definitions[58].start = 1233; object_sequence_definitions[58].end = 1236; object_sequence_definitions[58].final = 1236; object_sequence_definitions[58].next = 58;
    /* Sequence 59. */
    object_sequence_definitions[59].start = 1220; object_sequence_definitions[59].end = 1220; object_sequence_definitions[59].final = 1220; object_sequence_definitions[59].next = 0;
    object_sequence_definitions[59].sounds[0] = 100; object_sequence_definitions[59].sounds[1] = 101; object_sequence_definitions[59].sounds[2] = 102; object_sequence_definitions[59].sounds[3] = 100;
    object_sequence_definitions[59].sounds[4] = 101; object_sequence_definitions[59].sounds[5] = 102; object_sequence_definitions[59].sounds[6] = 100; object_sequence_definitions[59].sounds[7] = 101;
    /* Sequence 60. */
    object_sequence_definitions[60].start = 974; object_sequence_definitions[60].end = 977; object_sequence_definitions[60].final = 977; object_sequence_definitions[60].next = 0;
    /* Sequence 61: grate sequence. */
    object_sequence_definitions[61].start = 1408; object_sequence_definitions[61].end = 1408; object_sequence_definitions[61].final = 0; object_sequence_definitions[61].next = 0;
    object_sequence_definitions[61].debris[0][0] = 62; object_sequence_definitions[61].debris[0][1] = 1; object_sequence_definitions[61].debris[0][2] = 3; object_sequence_definitions[61].debris[0][3] = 0;
    object_sequence_definitions[61].debris[1][0] = 63; object_sequence_definitions[61].debris[1][1] = 1; object_sequence_definitions[61].debris[1][2] = 3; object_sequence_definitions[61].debris[1][3] = 0;
    object_sequence_definitions[61].debris[2][0] = 64; object_sequence_definitions[61].debris[2][1] = 1; object_sequence_definitions[61].debris[2][2] = 3; object_sequence_definitions[61].debris[2][3] = 0;
    object_sequence_definitions[61].debris[3][0] = 65; object_sequence_definitions[61].debris[3][1] = 1; object_sequence_definitions[61].debris[3][2] = 3; object_sequence_definitions[61].debris[3][3] = 0;
    object_sequence_definitions[61].debris[4][0] = 62; object_sequence_definitions[61].debris[4][1] = 1; object_sequence_definitions[61].debris[4][2] = 3; object_sequence_definitions[61].debris[4][3] = 0;
    object_sequence_definitions[61].debris[5][0] = 63; object_sequence_definitions[61].debris[5][1] = 1; object_sequence_definitions[61].debris[5][2] = 3; object_sequence_definitions[61].debris[5][3] = 0;
    object_sequence_definitions[61].sounds[0] = 103; object_sequence_definitions[61].sounds[1] = 104; object_sequence_definitions[61].sounds[2] = 103; object_sequence_definitions[61].sounds[3] = 104;
    object_sequence_definitions[61].sounds[4] = 103; object_sequence_definitions[61].sounds[5] = 104; object_sequence_definitions[61].sounds[6] = 103; object_sequence_definitions[61].sounds[7] = 104;
    /* Sequence 62. */
    object_sequence_definitions[62].start = 1426; object_sequence_definitions[62].end = 1431; object_sequence_definitions[62].final = 187; object_sequence_definitions[62].next = 62;
    /* Sequence 63. */
    object_sequence_definitions[63].start = 1419; object_sequence_definitions[63].end = 1422; object_sequence_definitions[63].final = 1387; object_sequence_definitions[63].next = 63;
    /* Sequence 64. */
    object_sequence_definitions[64].start = 1237; object_sequence_definitions[64].end = 1237; object_sequence_definitions[64].final = 1237; object_sequence_definitions[64].next = 0;
    object_sequence_definitions[64].debris[0][0] = 82; object_sequence_definitions[64].debris[0][1] = 1; object_sequence_definitions[64].debris[0][2] = 3; object_sequence_definitions[64].debris[0][3] = 1;
    object_sequence_definitions[64].debris[1][0] = 82; object_sequence_definitions[64].debris[1][1] = 1; object_sequence_definitions[64].debris[1][2] = 3; object_sequence_definitions[64].debris[1][3] = 1;
    object_sequence_definitions[64].debris[2][0] = 82; object_sequence_definitions[64].debris[2][1] = 1; object_sequence_definitions[64].debris[2][2] = 3; object_sequence_definitions[64].debris[2][3] = 1;
    object_sequence_definitions[64].sounds[0] = 103; object_sequence_definitions[64].sounds[1] = 104; object_sequence_definitions[64].sounds[2] = 103; object_sequence_definitions[64].sounds[3] = 104;
    object_sequence_definitions[64].sounds[4] = 103; object_sequence_definitions[64].sounds[5] = 104; object_sequence_definitions[64].sounds[6] = 103; object_sequence_definitions[64].sounds[7] = 104;
    /* Sequence 65. */
    object_sequence_definitions[65].start = 364; object_sequence_definitions[65].end = 364; object_sequence_definitions[65].final = 364; object_sequence_definitions[65].next = 0;
    object_sequence_definitions[65].debris[0][0] = 84; object_sequence_definitions[65].debris[0][1] = 1; object_sequence_definitions[65].debris[0][2] = 4; object_sequence_definitions[65].debris[0][3] = 0;
    object_sequence_definitions[65].debris[1][0] = 85; object_sequence_definitions[65].debris[1][1] = 1; object_sequence_definitions[65].debris[1][2] = 4; object_sequence_definitions[65].debris[1][3] = 0;
    object_sequence_definitions[65].debris[2][0] = 86; object_sequence_definitions[65].debris[2][1] = 1; object_sequence_definitions[65].debris[2][2] = 4; object_sequence_definitions[65].debris[2][3] = 0;
    object_sequence_definitions[65].debris[3][0] = 87; object_sequence_definitions[65].debris[3][1] = 1; object_sequence_definitions[65].debris[3][2] = 4; object_sequence_definitions[65].debris[3][3] = 0;
    object_sequence_definitions[65].debris[4][0] = 71; object_sequence_definitions[65].debris[4][1] = 1; object_sequence_definitions[65].debris[4][2] = 3; object_sequence_definitions[65].debris[4][3] = 0;
    object_sequence_definitions[65].debris[5][0] = 71; object_sequence_definitions[65].debris[5][1] = 1; object_sequence_definitions[65].debris[5][2] = 3; object_sequence_definitions[65].debris[5][3] = 0;
    object_sequence_definitions[65].debris[6][0] = 71; object_sequence_definitions[65].debris[6][1] = 1; object_sequence_definitions[65].debris[6][2] = 4; object_sequence_definitions[65].debris[6][3] = 0;
    object_sequence_definitions[65].debris[7][0] = 71; object_sequence_definitions[65].debris[7][1] = 2; object_sequence_definitions[65].debris[7][2] = 5; object_sequence_definitions[65].debris[7][3] = 0;
    object_sequence_definitions[65].debris[8][0] = 71; object_sequence_definitions[65].debris[8][1] = 1; object_sequence_definitions[65].debris[8][2] = 4; object_sequence_definitions[65].debris[8][3] = 0;
    /* Sequence 66. */
    object_sequence_definitions[66].start = 807; object_sequence_definitions[66].end = 810; object_sequence_definitions[66].final = 0; object_sequence_definitions[66].next = 0;
    object_sequence_definitions[66].sounds[0] = 163; object_sequence_definitions[66].sounds[1] = 163; object_sequence_definitions[66].sounds[2] = 163; object_sequence_definitions[66].sounds[3] = 163;
    object_sequence_definitions[66].sounds[4] = 163; object_sequence_definitions[66].sounds[5] = 163; object_sequence_definitions[66].sounds[6] = 163; object_sequence_definitions[66].sounds[7] = 163;
    /* Sequence 67. */
    object_sequence_definitions[67].start = 1509; object_sequence_definitions[67].end = 1509; object_sequence_definitions[67].final = 1509; object_sequence_definitions[67].next = 67;
    object_sequence_definitions[67].debris[0][0] = 42; object_sequence_definitions[67].debris[0][1] = 0; object_sequence_definitions[67].debris[0][2] = 5; object_sequence_definitions[67].debris[0][3] = 1;
    object_sequence_definitions[67].debris[1][0] = 42; object_sequence_definitions[67].debris[1][1] = 0; object_sequence_definitions[67].debris[1][2] = 5; object_sequence_definitions[67].debris[1][3] = 1;
    object_sequence_definitions[67].debris[2][0] = 42; object_sequence_definitions[67].debris[2][1] = 0; object_sequence_definitions[67].debris[2][2] = 5; object_sequence_definitions[67].debris[2][3] = 1;
    object_sequence_definitions[67].debris[3][0] = 42; object_sequence_definitions[67].debris[3][1] = 0; object_sequence_definitions[67].debris[3][2] = 5; object_sequence_definitions[67].debris[3][3] = 1;
    object_sequence_definitions[67].debris[4][0] = 42; object_sequence_definitions[67].debris[4][1] = 0; object_sequence_definitions[67].debris[4][2] = 5; object_sequence_definitions[67].debris[4][3] = 1;
    object_sequence_definitions[67].debris[5][0] = 42; object_sequence_definitions[67].debris[5][1] = 0; object_sequence_definitions[67].debris[5][2] = 5; object_sequence_definitions[67].debris[5][3] = 1;
    object_sequence_definitions[67].debris[6][0] = 42; object_sequence_definitions[67].debris[6][1] = 0; object_sequence_definitions[67].debris[6][2] = 5; object_sequence_definitions[67].debris[6][3] = 1;
    object_sequence_definitions[67].debris[7][0] = 42; object_sequence_definitions[67].debris[7][1] = 0; object_sequence_definitions[67].debris[7][2] = 5; object_sequence_definitions[67].debris[7][3] = 1;
    object_sequence_definitions[67].debris[8][0] = 42; object_sequence_definitions[67].debris[8][1] = 0; object_sequence_definitions[67].debris[8][2] = 5; object_sequence_definitions[67].debris[8][3] = 1;
    object_sequence_definitions[67].debris[9][0] = 42; object_sequence_definitions[67].debris[9][1] = 0; object_sequence_definitions[67].debris[9][2] = 5; object_sequence_definitions[67].debris[9][3] = 1;
    /* Sequence 68. */
    object_sequence_definitions[68].start = 1255; object_sequence_definitions[68].end = 1259; object_sequence_definitions[68].final = 0; object_sequence_definitions[68].next = 0;
    object_sequence_definitions[68].sounds[0] = 119; object_sequence_definitions[68].sounds[1] = 119; object_sequence_definitions[68].sounds[2] = 119; object_sequence_definitions[68].sounds[3] = 119;
    object_sequence_definitions[68].sounds[4] = 123; object_sequence_definitions[68].sounds[5] = 123; object_sequence_definitions[68].sounds[6] = 123; object_sequence_definitions[68].sounds[7] = 123;
    /* Sequence 69. */
    object_sequence_definitions[69].start = 2288; object_sequence_definitions[69].end = 2292; object_sequence_definitions[69].final = 2292; object_sequence_definitions[69].next = 69;
    /* Sequence 70. */
    object_sequence_definitions[70].start = 2552; object_sequence_definitions[70].end = 2560; object_sequence_definitions[70].final = 2561; object_sequence_definitions[70].next = 6;
    object_sequence_definitions[70].debris[0][0] = 88; object_sequence_definitions[70].debris[0][1] = 0; object_sequence_definitions[70].debris[0][2] = 3; object_sequence_definitions[70].debris[0][3] = 0;
    object_sequence_definitions[70].debris[1][0] = 88; object_sequence_definitions[70].debris[1][1] = 1; object_sequence_definitions[70].debris[1][2] = 3; object_sequence_definitions[70].debris[1][3] = 0;
    object_sequence_definitions[70].debris[2][0] = 88; object_sequence_definitions[70].debris[2][1] = 1; object_sequence_definitions[70].debris[2][2] = 4; object_sequence_definitions[70].debris[2][3] = 0;
    object_sequence_definitions[70].debris[3][0] = 88; object_sequence_definitions[70].debris[3][1] = 1; object_sequence_definitions[70].debris[3][2] = 5; object_sequence_definitions[70].debris[3][3] = 0;
    object_sequence_definitions[70].debris[4][0] = 88; object_sequence_definitions[70].debris[4][1] = 1; object_sequence_definitions[70].debris[4][2] = 4; object_sequence_definitions[70].debris[4][3] = 0;
    object_sequence_definitions[70].debris[5][0] = 88; object_sequence_definitions[70].debris[5][1] = 1; object_sequence_definitions[70].debris[5][2] = 4; object_sequence_definitions[70].debris[5][3] = 0;
    object_sequence_definitions[70].debris[6][0] = 88; object_sequence_definitions[70].debris[6][1] = 1; object_sequence_definitions[70].debris[6][2] = 5; object_sequence_definitions[70].debris[6][3] = 0;
    object_sequence_definitions[70].debris[7][0] = 88; object_sequence_definitions[70].debris[7][1] = 1; object_sequence_definitions[70].debris[7][2] = 5; object_sequence_definitions[70].debris[7][3] = 0;
    object_sequence_definitions[70].sounds[0] = 60; object_sequence_definitions[70].sounds[1] = 61; object_sequence_definitions[70].sounds[2] = 62; object_sequence_definitions[70].sounds[3] = 63;
    object_sequence_definitions[70].sounds[4] = 60; object_sequence_definitions[70].sounds[5] = 61; object_sequence_definitions[70].sounds[6] = 62; object_sequence_definitions[70].sounds[7] = 63;
    /* Sequence 71. */
    object_sequence_definitions[71].start = 1450; object_sequence_definitions[71].end = 1450; object_sequence_definitions[71].final = 1450; object_sequence_definitions[71].next = 0;
    /* Sequence 72. */
    object_sequence_definitions[72].start = 1449; object_sequence_definitions[72].end = 1449; object_sequence_definitions[72].final = 1449; object_sequence_definitions[72].next = 0;
    /* Sequence 73. */
    object_sequence_definitions[73].start = 1437; object_sequence_definitions[73].end = 1437; object_sequence_definitions[73].final = 1437; object_sequence_definitions[73].next = 0;
}
