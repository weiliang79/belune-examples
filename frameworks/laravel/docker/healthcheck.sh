#!/bin/sh
# Role-aware container healthcheck. Dispatches on the same PROCESS variable the
# entrypoint uses — Belune injects it as a container env var, so it's visible to
# the healthcheck shell (unlike VIEW_COMPILED_PATH, which the entrypoint exports
# only to PID 1).
case "${PROCESS:-all}" in
    web|all)
        # Web + AIO serve HTTP — probe Laravel's built-in /up route.
        exec curl -fsS http://localhost:8080/up
        ;;
    reverb)
        # Reverb listens on 8081; any HTTP response means it's accepting
        # connections. No -f, since Reverb may answer non-2xx to a plain GET.
        exec curl -s -o /dev/null --max-time 5 http://localhost:8081
        ;;
    scheduler)
        # schedule:work refreshes /tmp/scheduler-heartbeat every minute (see
        # routes/console.php). Fail if it goes stale — catches a hung scheduler.
        [ -n "$(find /tmp/scheduler-heartbeat -mmin -2 2>/dev/null)" ] || exit 1
        ;;
    queue)
        # queue:work has no clean heartbeat hook; rely on crash -> container exit
        # -> restart. Use Laravel Horizon if you need real worker-health here.
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
