# HTTP Socket App

In this example, we:
- build one http client wasm executable (optional)
- build one http server wasm executable (optional)
- create a http_client docker hub image (purely from the compiled `http_client.wasm` executable) (optional)
- create a http_server docker hub image (purely from the compiled `http_server.wasm` executable) (optional)
- push the http_client docker hub image to docker hub for future use (optional)
- push the http_server docker hub image to docker hub forfuture use (optional)
- install crunw
- pull and run containers
- run http server example
- run http client example

## Fetch Wasi socket example source code (optional)


```bash
cd ~
git clone https://github.com/second-state/wasmedge_wasi_socket.git
```

### Client (optional)

Create Wasm executable for [HTTP client example](https://github.com/second-state/wasmedge_wasi_socket/tree/main/examples/http_client)

```bash
cd ~/wasmedge_wasi_socket/examples/http_client/
cargo build --target wasm32-wasi --release
```

### Server (optional)

Create Wasm executable from [HTTP server example](https://github.com/second-state/wasmedge_wasi_socket/tree/main/examples/http_server)

```bash
cd ~/wasmedge_wasi_socket/examples/http_server/
cargo build --target wasm32-wasi --release

```

---


## Build and publish a Docker Hub image for the two wasm examples (optional)

Please note, you can just skip this section and use our Docker images that we created for this example (no need to build and hold your own docker hub images, unless you want to). For example, perhaps you have custom rust/wasm code that you want to run.

### Log into Docker (optional)

You may need to set up a Docker account i.e. visit [hub.docker.com](https://hub.docker.com/).

```bash
docker login -u 
```

### Client (optional)

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

### Server(optional)

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

---


## Install crunw

```bash
cd ~
wget https://raw.githubusercontent.com/second-state/crunw/main/crunw_install.sh
sudo chmod a+x crunw_install.sh
./crunw_install.sh
```

## Pull and run containers

If you skipped the optional section above and just want to use our docker hub containers, please run the following code snippet.

Alternatively, if you built and pushed your own unique custom containers above, in the **(OPTIONAL) Build and publish a Docker Hub image for the two wasm examples section** then you will need to update the following code snippet so that it fetches your unique containers from your own docker hub account.

```bash
wget https://raw.githubusercontent.com/second-state/crunw/main/http_socket_application.sh
sudo chmod a+x http_socket_application.sh
./http_socket_application.sh
```

## Manage WebAssembly programs and Docker containers side by side in Kubernetes

The running_wasm_in_kubernetes.sh installs and starts the Kubernetes cluster.

```bash
wget https://raw.githubusercontent.com/second-state/crunw/main/running_wasm_in_kubernetes.sh
sudo chmod a+x running_wasm_in_kubernetes.sh
./running_wasm_in_kubernetes.sh
```

Once this runs, please **DO NOT close the terminal**. You will need to open a new terminal to perform the rest of this demonstration.

## Open a new terminal

Please go ahead and run the following in a new terminal

```bash
wget https://raw.githubusercontent.com/second-state/crunw/main/running_http_socket_in_kubernetes.sh
sudo chmod a+x running_http_socket_in_kubernetes.sh
./running_http_socket_in_kubernetes.sh
```

## Check what services are running

```bash
sudo ./kubernetes/cluster/kubectl.sh get svc
```

The output will be similar to the following

```bash
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.0.0.1     <none>        443/TCP   15m
```

## Run the http_server

We now want to expose the http_server so that the client can interact with it. Note the `--expose --port=1234` below.

```bash
sudo ./kubernetes/cluster/kubectl.sh run --expose --port=1234 -it --rm --restart=Never server-demo --image=tpmccallum/http_server:latest /http_server.wasm
```

## Check what services are running - after expose flag

If we run the above `sudo ./kubernetes/cluster/kubectl.sh get svc` code again, we will see this new service running on port `1234`

```bash
NAME          TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
kubernetes    ClusterIP   10.0.0.1     <none>        443/TCP    20m
server-demo   ClusterIP   10.0.0.129   <none>        1234/TCP   2m10s
```

**Once a service is exposed, it can be addressed by its namespace**

Let's go a little deeper anyway and describe the server-demo name which has been exposed in the default namespace

```bash
sudo ./kubernetes/cluster/kubectl.sh describe service/server-demo
Name:              server-demo
Namespace:         default
Labels:            <none>
Annotations:       <none>
Selector:          run=server-demo
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.0.0.129
IPs:               10.0.0.129
Port:              <unset>  1234/TCP
TargetPort:        1234/TCP
Endpoints:         10.85.0.5:1234
Session Affinity:  None
Events:            <none>
```

We can see that the endpoint is `10.85.0.5:1234`

We can also confirm with the following command that the server-demo is in the default namespace.

```bash
sudo ./kubernetes/cluster/kubectl.sh get all --namespace=default
```

```bash
NAME              READY   STATUS    RESTARTS   AGE
pod/server-demo   1/1     Running   0          39m

NAME                  TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
service/kubernetes    ClusterIP   10.0.0.1     <none>        443/TCP    57m
service/server-demo   ClusterIP   10.0.0.129   <none>        1234/TCP   39m
```

## Run the http_client

We must specifying the namespace via the `--namespace` flag when executing the http_client function

```bash
sudo ./kubernetes/cluster/kubectl.sh run -it --namespace=default --rm --restart=Never client-demo --image=tpmccallum/http_client:latest /http_client.wasm hello
```


## TODO
We must adjust the Rust Wasm to use the name of the service as apposed to 127.0.0.1



