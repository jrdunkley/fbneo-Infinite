// sfiii3nr1 Japan 990512 task dispatcher, original ROM 06000882-060008BE.
// Callers pass raw unsigned bytes; MOV.B sign extension does not change these
// equality guards. Every unrecognised status reaches the dispatch branch.
#ifndef INFINITE_CPS3_SCHEDULER_H
#define INFINITE_CPS3_SCHEDULER_H
static int InfiniteCps3TaskReady(unsigned state, unsigned mode, unsigned frame, unsigned mask)
{
    if (state == 0 || state == 1 || state == 5) return 0;
    if (state == 2 && (mode == 1 || (mode == 2 && (frame & mask)))) return 0;
    return 1;
}
#endif
