extern short drawing_action;

short get_drawing_action(void)
{
    switch (drawing_action) {
    case 0:
    default:
        return 3;
    case 1:
        return 4;
    case 2:
        return 1;
    case 3:
        return 0;
    }
}
