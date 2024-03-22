# Process Management

This is a [multi-service container](https://docs.docker.com/config/containers/multi-service_container/)
for various reasons (which we won't get into here). It runs at least two processes:

1. your application
2. the sigsci agent

If not done correctly, this could cause issues with stopping the container, handling crashes, etc.

There are two main scenarios we need to handle:

## Crashing apps

If your application, or the sigsci agent crashes, we need to go ahead and kill the container. This
is an easy problem to solve in `entrypoint.sh`: at the end of the script just use `wait -n` to
wait for a single process to end, and then `exit` the script.

## Handling signals

By default when you use a bash script (like our `entrypoint.sh` script) to launch subprocesses, any
signals that the container receives will go to bash. Unfortunately bash doesn't handle signals at
all, much less forward them on to its child processes. You can fix this using `trap` in your
script, however that adds a bit more complexity and room for bugs.

This is why we use [tini](https://github.com/krallin/tini) as a [process supervisor](https://en.wikipedia.org/wiki/Process_supervision).
It is configured to be our `ENTRYPOINT` so it will be PID 1 inside the container. It is also
configured to forward signals to ALL subprocesses that are spawned underneath it, not just the first
child subprocess (which is `bash` in this case).

That means when the container gets a SIGTERM, SIGINT, etc., that signal is passed to `tini`, which
then forwards the signal to ALL of:

* bash (which does nothing)
* your app
* the sigsci agent

If this signal causes ANY of these child processes to exit, that will cause bash to exit, which will
cause `tini` to exit, and that is ultimately what stops the container.
