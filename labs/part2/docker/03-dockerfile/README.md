# Docker Lab 03 — Build Your Own Image with a Dockerfile

## Goal

Write a tiny `Dockerfile`, build your own image, run a container from it, and confirm that your custom content is served.

By the end of this lab, you should be able to explain:

- what a `Dockerfile` is
- how an image is built
- how your files get into the image
- how a container is started from that image


## Why this matters

In the previous labs, you ran and inspected an existing image.

Now you will create your own.

This is the step where Docker becomes useful for application packaging:

you describe the image in a `Dockerfile`,
Docker builds it,
and then anyone can run the result the same way.


## What you need

Check that Docker is installed and working:

```bash
docker version
```

Create a working directory for the lab:

```bash
mkdir -p docker-lab-03
cd docker-lab-03
```

## Step 1 — Create a simple web page

Create a file named `index.html`:

```bash
cat > index.html <<'HTML'
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>My first Docker image</title>
</head>
<body>
  <h1>Hello from my Docker image</h1>
  <p>If you can read this, nginx is serving my custom page.</p>
</body>
</html>
HTML
```

Check the file:

```bash
cat index.html
```

What to notice:

- this is your custom content
- later you will copy it into the image

## Step 2 — Create the Dockerfile

Create a file named `Dockerfile`:

```bash
cat > Dockerfile <<'DOCKERFILE'
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
DOCKERFILE
```

Check the file:

```bash
cat Dockerfile
```

What this means:

- `FROM nginx:alpine` — start from the nginx base image
- `COPY ...` — place your custom file into nginx's default web root

This is enough for a first useful image.

## Step 3 — Build the image

Build your image and tag it as `my-nginx:v1`:

```bash
docker build -t my-nginx:v1 .
```

List local images:

```bash
docker images
```

What to notice:

- Docker used the `Dockerfile` in the current directory
- the final image now exists locally
- your image has a name and tag: `my-nginx:v1`

## Step 4 — Run a container from your image

Start a container in the background:

```bash
docker run -d --name my-web -p 8081:80 my-nginx:v1
```

Check running containers:

```bash
docker ps
```

What to notice:

- the container runs from your own image
- host port `8081` is mapped to container port `80`

## Step 5 — Access your page

From the host:

```bash
curl http://localhost:8081
```

Or open in a browser:

```text
http://localhost:8081
```

What to notice:

- nginx is running inside the container
- the page content is the file you created yourself
- this proves your custom file was built into the image

## Step 6 — View logs

Show the logs of the running container:

```bash
docker logs my-web
```

Make one more request:

```bash
curl http://localhost:8081 >/dev/null
```

Then check logs again:

```bash
docker logs my-web
```

What to notice:

- Docker collects logs from the running container
- your HTTP requests appear in nginx access logs

## Step 7 — Inspect the image history

See how the image was built:

```bash
docker history my-nginx:v1
```

What to notice:

- the base image layers come from `nginx:alpine`
- your `COPY` instruction added another layer

This is one of Docker's core ideas:
images are built in layers.

## Step 8 — Stop and remove the container

Stop the container:

```bash
docker stop my-web
```

Remove it:

```bash
docker rm my-web
```

Check that it is gone:

```bash
docker ps -a
```

## Step 9 — Optional cleanup

Remove your image too:

```bash
docker rmi my-nginx:v1
```

## What you learned

In this lab:

- you created a file to be served by nginx
- you wrote a minimal `Dockerfile`
- you built your own image
- you ran a container from that image
- you confirmed that your custom content was inside the image

## Key idea

A `Dockerfile` is a recipe for building an image.

The image becomes a portable package,
and a container is a running instance of that package.

## Suggested follow-up

Try small changes and rebuild:

- change the HTML text
- add another file
- rebuild with a new tag such as `my-nginx:v2`
- run the new version and compare the result
