extern float mouse_x_scale, mouse_y_scale;

/* Watcom normally folds this x87 stack duplicate and drop into the multiply.
 * Keep the two operations paired around each product to reproduce the demo. */
extern float preserve_x87_operand(float);
#pragma aux preserve_x87_operand = "fld st(0)" parm [8087] value [8087] modify exact [8087];
extern float discard_x87_operand(float);
#pragma aux discard_x87_operand = "fstp st(1)" parm [8087] value [8087] modify exact [8087];

void scale_mouse(short *x, short *y)
{
    *x = (short)discard_x87_operand(preserve_x87_operand(*x) * mouse_x_scale);
    *y = (short)discard_x87_operand(preserve_x87_operand(*y) * mouse_y_scale);
}
