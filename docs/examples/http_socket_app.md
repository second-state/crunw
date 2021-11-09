# HTTP Socket App

In this example, we:
- build one http client wasm executable
- build one http server wasm executable
- create a http_client docker hub image (purely from the compiled `http_client.wasm` executable)
- create a http_server docker hub image (purely from the compiled `http_server.wasm` executable)
- push the http_client docker hub image to docker hub for future use
- push the http_server docker hub image to docker hub forfuture use
- install crunw

## Fetch Wasi socket example code


```bash
cd ~
git clone https://github.com/second-state/wasmedge_wasi_socket.git
```

### Client

Create Wasm executable for [HTTP client example](https://github.com/second-state/wasmedge_wasi_socket/tree/main/examples/http_client)

```bash
cd ~/wasmedge_wasi_socket/examples/http_client/
cargo build --target wasm32-wasi --release
```

### Server

Create Wasm executable from [HTTP server example](https://github.com/second-state/wasmedge_wasi_socket/tree/main/examples/http_server)

```bash
cd ~/wasmedge_wasi_socket/examples/http_server/
cargo build --target wasm32-wasi --release

```

## (OPTIONAL) Build and publish a Docker Hub image for the two wasm examples

Please note, you can just skip this section and use our Docker images that we created for this example (no need to build and hold your own docker hub images, unless you want to). For example, perhaps you have custom rust/wasm code that you want to run.

### Log into Docker

You may need to set up a Docker account i.e. visit [hub.docker.com](https://hub.docker.com/).

```bash
docker login -u 
```

### Client

```bash
cd ~/wasmedge_wasi_socket/examples/http_client/target/wasm32-wasi/release
```

Create a new file called `Dockerfile` and paste the following code snipped into it

```bash
# syntax=docker/dockerfile:1
FROM scratch
ADD http_client.wasm .
CMD ["http_client.wasm"]
```

Once the `Dockerfile` is saved and closed, then run the following commands

```bash
docker build -f Dockerfile -t tpmccallum/http_client:latest .
docker push tpmccallum/http_client:latest
```

### Server

```bash
cd ~/wasmedge_wasi_socket/examples/http_server/target/wasm32-wasi/release
```

Create a new file called `Dockerfile` and insert the following code snippet into it

```bash
# syntax=docker/dockerfile:1
FROM scratch
ADD http_server.wasm .
CMD ["http_server.wasm"]
```

Once the `Dockerfile` is saved and closed, then run the following commands

```bash
docker build -f Dockerfile -t tpmccallum/http_server:latest .
docker push tpmccallum/http_server:latest
```

## Install crunw

```bash
cd ~
wget https://raw.githubusercontent.com/second-state/crunw/main/crunw_install.sh
sudo chmod a+x crunw_install.sh
./crunw_install.sh
```


