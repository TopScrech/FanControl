#include "FanTimerSignal.h"
#include <signal.h>
#include <stddef.h>

static volatile sig_atomic_t received_signal = 0;
static const int timer_signals[] = { SIGINT, SIGTERM, SIGHUP };
static struct sigaction previous_actions[3];

static void receive_signal(int value) {
    received_signal = value;
}

int fan_timer_signal_start(void) {
    received_signal = 0;
    struct sigaction action = {0};
    action.sa_handler = receive_signal;
    sigemptyset(&action.sa_mask);

    for (size_t index = 0; index < 3; index++) {
        if (sigaction(timer_signals[index], &action, &previous_actions[index]) != 0) {
            while (index > 0) {
                index--;
                sigaction(timer_signals[index], &previous_actions[index], NULL);
            }
            return -1;
        }
    }
    return 0;
}

int fan_timer_signal_received(void) {
    return received_signal;
}

void fan_timer_signal_stop(void) {
    for (size_t index = 0; index < 3; index++) {
        sigaction(timer_signals[index], &previous_actions[index], NULL);
    }
}
