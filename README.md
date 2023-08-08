## thermondo sigsci container

Run the [Signal Sciences WAF](https://www.signalsciences.com/) ("sigsci") agent in
[reverse proxy mode](https://docs.fastly.com/signalsciences/install-guides/reverse-proxy/) alongside your app in the
same container.

```shell
docker pull ghcr.io/thermondo/sigsci
```

### Why?

Signal Sciences offers [several integration options](https://docs.fastly.com/signalsciences/install-guides/) including
a [containerized option](https://docs.fastly.com/signalsciences/install-guides/kubernetes/kubernetes-intro/), but it
assumes that you're using Kubernetes.

The recommended way to run the SigSci agent would be with a separate container while using Kubernetes, Docker
Compose, etc., however there are cases where you really want to do everything in one container (such as when you're
running in Heroku, which has limited Docker support).

This container image is especially developed for Heroku, though it can be used in probably any context.

### General Info

This is meant to be used as a base image for your own containers. When you base your container on this image, you can
configure the sigsci agent to filter all incoming HTTP requests through the WAF before they get to your application.

This container comes in two variants:

* `sigsci`: A general-purpose base image that should work for any tech stack (Python, JVM, etc.). It is based
    on the [official Ubuntu image](https://hub.docker.com/_/ubuntu).
* `sigsci:python-X.XX`: An image that is more ideal for a Python tech stack, based on the
    [official Python image](https://hub.docker.com/_/python)

It should be trivial to create other similar "flavors" of the image, including a JVM variant.

### Configuration

The sigsci agent can be configured via environment variables. The most notable ones:

**sigsci auth settings**

* `SIGSCI_ACCESSKEYID`: access key ID
* `SIGSCI_SECRETACCESSKEY`: the secret portion of the access key

_these settings are best configured in Heroku, not hard-coded_

**port settings**

* `PORT`: (this is set automatically by Heroku) -- the port number the sigsci agent should listen on
* `APP_PORT`: the port that YOUR application should listen on. the sigsci agent will forward traffic to this port.

The `PORT` and `APP_PORT` values must be different. Keep in mind that Heroku assigns a random number to the `PORT`
variable at runtime, in the range of 3000 - 60000 for common runtime apps. So it's best to hard-code your `APP_PORT` in
your Dockerfile (recommended anywhere between 1025 and 2999). This will guarantee you don't have any port conflicts
when Heroku tries to set the `PORT` variable at runtime.

**startup settings**

The container will only start the sigsci agent after your app is ready. It knows your app is ready when it
responds with a non-error response on a configured HTTP endpoint.

* `SIGSCI_WAIT_ENDPOINT`: the endpoint that indicates your service is running and healthy. you could set this
    to something like `ht` or `version`, or any endpoint that returns a success response when the service is
    healthy. the default value is an empty string, so the sigsci agent will just ping `http://127.0.0.1:${APP_PORT}/`
    if you don't configure it at all.
* `SIGSCI_WAIT_TIMEOUT`: (optional) defaults to 60 seconds. if your app's "wait endpoint" doesn't respond
    within this time, the container will stop with an error code.

Example Python Dockerfile:

```dockerfile
FROM ghcr.io/thermondo/sigsci:python-3.11
ARG DEBIAN_FRONTEND=noninteractive

# Configure All The Things here as usual

ENV APP_PORT=2000
ENV SIGSCI_WAIT_ENDPOINT=ht
CMD [ "poetry", "run", "python", "runserver.py", "0:${APP_PORT}" ]
```

#### Important Notes

* The base image uses an [`ENTRYPOINT`](https://docs.docker.com/engine/reference/builder/#entrypoint) script to launch
    the sigsci agent after your app is up and running. This means you should not use `ENTRYPOINT` in your own
    Dockerfile unless you know what you're doing. If you use [CMD](https://docs.docker.com/engine/reference/builder/#cmd)
    instead, the base image's entrypoint script will execute that command for you.
