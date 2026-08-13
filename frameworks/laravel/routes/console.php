<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Liveness heartbeat for the scheduler container's healthcheck: refreshes a file
// every minute so docker/healthcheck.sh can detect a hung scheduler (a stale
// file). Harmless in the AIO container, whose healthcheck uses HTTP /up instead.
Schedule::call(fn () => @touch('/tmp/scheduler-heartbeat'))->everyMinute();
