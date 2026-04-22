# Docker Lab 01 — Run Your First Real Container

## Goal

Run a real container, access the service it provides, view its logs, and remove it.

By the end of this lab, you should be able to explain:

- what an image is
- what a container is
- how Docker exposes a service to the host

## Why this matters

Docker gives a practical way to package and run applications consistently.

In this lab, you will:

- download an image
- start a container
- access a service running inside it
- inspect its logs
- stop and remove it

This is the first useful mental model:

- an **image** is a packaged application filesystem plus metadata
- a **container** is a running instance of that image

## What you need

Check that Docker is installed and working:

```bash
docker version
```

## Step 1 — Pull the image

Download the nginx image:

```bash
docker pull nginx:alpine
```

List local images:

```bash
docker images
```

What to notice:

- `nginx:alpine` is now available locally
- the image exists before any container is started

## Step 2 — Start a container

Run nginx in the background:

```bash
docker run -d --name web1 -p 8080:80 nginx:alpine
```

Check running containers:

```bash
docker ps
```

What to notice:

- container name: `web1`
- image: `nginx:alpine`
- port mapping: `8080 -> 80`

## Step 3 — Access the service

From the host:

```bash
curl -I http://localhost:8080
```

You can also open this in a browser:

```text
http://localhost:8080
```

What to notice:

- nginx is running inside the container
- Docker published the service on host port `8080`

---

## Step 4 — View logs

Show the logs of the running container:

```bash
docker logs web1
```

Now make one more request:

```bash
curl http://localhost:8080 >/dev/null
```

Then check logs again:

```bash
docker logs web1
```

What to notice:

- Docker captures logs written by the container
- your HTTP request appears in the nginx access log

## Step 5 — Stop the container

Stop it:

```bash
docker stop web1
```

Check all containers, including stopped ones:

```bash
docker ps -a
```

What to notice:

- the container still exists
- it is stopped, but not removed

## Step 6 — Remove the container

Remove it:

```bash
docker rm web1
```

Check again:

```bash
docker ps -a
```

What to notice:

- the container is gone
- the image still remains on the system

## Step 7 — Optional cleanup

Remove the image too:

```bash
docker rmi nginx:alpine
```

## What you learned

In this lab:

- you pulled an image
- you started a container from that image
- you accessed a service running inside it
- you viewed logs
- you stopped and removed the container

## Key idea

An image is a packaged application.

A container is a running instance of that image.
