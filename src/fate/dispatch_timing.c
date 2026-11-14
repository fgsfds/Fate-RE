/* Timing conversions adjacent to dispatcher presentation helpers. */
long dispatch_ticks(long units)
{
    return units*120;
}

long dispatch_period(long divisor)
{
    switch (divisor) {
    case 1: return 120;
    case 2: return 60;
    case 4: return 30;
    case 8: return 15;
    case 16: return 7;
    case 32: return 3;
    default: return 0;
    }
}
