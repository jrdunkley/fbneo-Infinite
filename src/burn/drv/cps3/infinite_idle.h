#ifndef INFINITE_CPS3_IDLE_H
#define INFINITE_CPS3_IDLE_H
// A scan begins at the slot-0 poll. Slot 5 is an always-runnable queue
// dispatcher; reaching its job body makes the scan active. IRQ arrival and
// IRQ entry also make it active. Reset/load starts with no completed scan.
typedef struct InfiniteCps3Idle { unsigned seen, activity; } InfiniteCps3Idle;
static void InfiniteCps3IdleReset(InfiniteCps3Idle *t) { t->seen = 0; t->activity = 1; }
static void InfiniteCps3IdleWake(InfiniteCps3Idle *t) { t->activity = 1; }
static void InfiniteCps3IdleExec(InfiniteCps3Idle *t, unsigned pc, unsigned slot)
{
    if ((pc == 0x06000CDC && slot != 5) || pc == 0x06004E24 ||
        pc == 0x06000528 || pc == 0x060004D0 || pc == 0x0600073E) t->activity = 1;
}
static int InfiniteCps3IdlePoll(InfiniteCps3Idle *t)
{
    int idle = t->seen && !t->activity;
    t->seen = 1; t->activity = 0;
    return idle;
}
#endif
