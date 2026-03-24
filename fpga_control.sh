#!/bin/bash
# fpga_control.sh - FPGA service manager (No Logging Version)

LOGFILE=/dev/null
START_SCRIPT=/home/admin/start_fpga.sh
MAX_RETRIES=3
RETRY_DELAY=5
START_WAIT=15
LOCKFILE=/var/run/fpga_control.lock

# Log function is redirected to /dev/null to save resources
log() { :; }

acquire_lock() {
    if [ -f "$LOCKFILE" ]; then
        EXISTING_PID=$(cat "$LOCKFILE" 2>/dev/null)
        if [ -n "$EXISTING_PID" ] && [ -d "/proc/$EXISTING_PID" ]; then
            return 1
        else
            rm -f "$LOCKFILE"
        fi
    fi
    echo $$ > "$LOCKFILE"
    return 0
}

release_lock() {
    [ -f "$LOCKFILE" ] && [ "$(cat "$LOCKFILE" 2>/dev/null)" = "$$" ] && rm -f "$LOCKFILE"
}

status() {
    echo "Checking FPGA services status..."
    pidof grpccore > /dev/null 2>&1 && echo "grpccore:    RUNNING" || echo "grpccore:    STOPPED"
    pidof fpga_driver > /dev/null 2>&1 && echo "fpga_driver: RUNNING" || echo "fpga_driver: STOPPED"
}

stop() {
    echo "Stopping FPGA services..."
    killall grpccore fpga_driver 2>/dev/null
    sleep 1
    killall -9 grpccore fpga_driver 2>/dev/null
    return 0
}

_do_start() {
    [ ! -x "$START_SCRIPT" ] && return 1
    "$START_SCRIPT" > /dev/null 2>&1 &
    sleep $START_WAIT
    pidof grpccore > /dev/null 2>&1 && pidof fpga_driver > /dev/null 2>&1 && return 0
    return 1
}

start() {
    if pidof fpga_driver > /dev/null 2>&1 || pidof grpccore > /dev/null 2>&1; then
        echo "Services already running."
        status
        return 0
    fi
    acquire_lock || return 1
    trap 'release_lock' EXIT
    for ATTEMPT in $(seq 1 $MAX_RETRIES); do
        echo "Attempt $ATTEMPT / $MAX_RETRIES..."
        if _do_start; then
            echo "Success!"
            status
            return 0
        fi
        [ $ATTEMPT -lt $MAX_RETRIES ] && sleep $RETRY_DELAY
    done
    echo "Failed to start services."
    return 1
}

case "$1" in
    start)   start   ;;
    stop)    stop    ;;
    status)  status  ;;
    restart) stop; sleep 2; start ;;
    *) echo "Usage: $0 {start|stop|status|restart}"; exit 1 ;;
esac
