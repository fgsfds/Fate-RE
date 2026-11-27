typedef struct RuntimeDivision {
    int quot;
    int rem;
} RuntimeDivision;

/* Preserve the original registers through both signed divisions. */
extern int in_ebx(int);
#pragma aux in_ebx = parm [ebx] value [ebx] modify exact [];
extern int in_esi(int);
#pragma aux in_esi = parm [esi] value [esi] modify exact [];
extern int in_eax(int);
#pragma aux in_eax = parm [eax] value [eax] modify exact [];

RuntimeDivision div(int numerator, int denominator)
{
    RuntimeDivision result;
    numerator = in_ebx(numerator);
    denominator = in_esi(denominator);
    result.quot = in_eax(numerator) / denominator;
    result.rem = numerator % denominator;
    return result;
}
