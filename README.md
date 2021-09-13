**CRUNW** is a OCI compatible runtime for running WASI enabled WebAssembly files inside a container envrionment. It is based on the [crun](https://github.com/containers/crun) runtime, and is extended to support the [WasmEdge](https://github.com/WasmEdge/WasmEdge) WebAssembly runtime.

# CRI-O: Manage WebAssembly programs as container images

## Prerequisite

Please install the following tools for container management.

* [cri-o](https://cri-o.io/)
* [crictl](https://github.com/kubernetes-sigs/cri-tools)
* [containernetworking-plugins](https://github.com/containernetworking/plugins)
* Optional [buildah](https://github.com/containers/buildah) or [docker](https://github.com/docker/cli) for building container image

## Use pre-built crunw

### Environment

Our pre-built binary is based on `ubuntu 20.04` with the following dependencies:

* libLLVM-10

You need to install the dependencies with:

```bash
sudo apt install -y \
        llvm-10-dev \
        liblld-10-dev
```

### Get pre-built runw from the release page

```bash
wget https://github.com/second-state/runw/releases/download/0.1.0/crunw
```

> If you are not on Ubuntu 20.04, you will need to build your own CRUNW binary. Follow instructions in the appendix.


## Install crunw into cri-o

```bash
# Get the wasm-pause utility
sudo crictl pull docker.io/beststeve/wasm-pause

# Install crunw into cri-o
sudo cp -v crunw /usr/lib/cri-o-runc/sbin/crunw
sudo chmod +x /usr/lib/cri-o-runc/sbin/crunw
sudo sed -i -e 's@default_runtime = "runc"@default_runtime = "crunw"@' /etc/crio/crio.conf
sudo sed -i -e 's@pause_image = "k8s.gcr.io/pause:3.2"@pause_image = "docker.io/beststeve/wasm-pause"@' /etc/crio/crio.conf
sudo sed -i -e 's@pause_command = "/pause"@pause_command = "pause.wasm"@' /etc/crio/crio.conf
sudo tee -a /etc/crio/crio.conf.d/01-crio-runc.conf <<EOF
[crio.runtime.runtimes.crunw]
runtime_path = "/usr/lib/cri-o-runc/sbin/crunw"
runtime_type = "oci"
runtime_root = "/run/crunw"
EOF
```

## Restart cri-o

```bash
sudo systemctl restart crio
```

## Simple Wasi Application

In this example, we would like to demostrate how to create a simple rust application to get program arguments, retrieve environment variables, generate random number, print string to stdout, and create a file.

For creating the container image and application details, please refer to [Simple Wasi Application](docs/examples/simple_wasi_app.md).

## Download wasi-main docker image

We've created a docker image called `wasi-main` which is a very light docker image with the `wasi_example_main.wasm` file.

```bash
sudo crictl pull docker.io/hydai/wasm-wasi-example
```

## Create container config

Create a file called `container_wasi.json` with the following content:

```json
{
  "metadata": {
    "name": "podsandbox1-wasm-wasi"
  },
  "image": {
    "image": "hydai/wasm-wasi-example:latest"
  },
  "args": [
    "wasi_example_main.wasm", "50000000"
  ],
  "working_dir": "/",
  "envs": [],
  "labels": {
    "tier": "backend"
  },
  "annotations": {
    "pod": "podsandbox1"
  },
  "log_path": "",
  "stdin": false,
  "stdin_once": false,
  "tty": false,
  "linux": {
    "resources": {
      "memory_limit_in_bytes": 209715200,
      "cpu_period": 10000,
      "cpu_quota": 20000,
      "cpu_shares": 512,
      "oom_score_adj": 30,
      "cpuset_cpus": "0",
      "cpuset_mems": "0"
    },
    "security_context": {
      "namespace_options": {
        "pid": 1
      },
      "readonly_rootfs": false,
      "capabilities": {
        "add_capabilities": [
          "sys_admin"
        ]
      }
    }
  }
}
```

## Create sandbox configuration file

Create a file called `sandbox_config.json` with the following content:

```json
{
  "metadata": {
    "name": "podsandbox12",
    "uid": "redhat-test-crio",
    "namespace": "redhat.test.crio",
    "attempt": 1
  },
  "hostname": "crictl_host",
  "log_directory": "",
  "dns_config": {
    "searches": [
      "8.8.8.8"
    ]
  },
  "port_mappings": [],
  "resources": {
    "cpu": {
      "limits": 3,
      "requests": 2
    },
    "memory": {
      "limits": 50000000,
      "requests": 2000000
    }
  },
  "labels": {
    "group": "test"
  },
  "annotations": {
    "owner": "hmeng",
    "security.alpha.kubernetes.io/seccomp/pod": "unconfined"
  },
  "linux": {
    "cgroup_parent": "pod_123-456.slice",
    "security_context": {
      "namespace_options": {
        "network": 0,
        "pid": 1,
        "ipc": 0
      },
      "selinux_options": {
        "user": "system_u",
        "role": "system_r",
        "type": "svirt_lxc_net_t",
        "level": "s0:c4,c5"
      }
    }
  }
}
```

## Create cri-o POD

```bash
# Create the POD. Output will be different from example.
sudo crictl runp sandbox_config.json
7992e75df00cc1cf4bff8bff660718139e3ad973c7180baceb9c84d074b516a4
# Set a helper variable for later use.
POD_ID=7992e75df00cc1cf4bff8bff660718139e3ad973c7180baceb9c84d074b516a4
```

## Create Container

```bash
# Create the container instance. Output will be different from example.
sudo crictl create $POD_ID container_wasi.json sandbox_config.json
1d056e4a8a168f0c76af122d42c98510670255b16242e81f8e8bce8bd3a4476f
```

## Start Container

```bash
# List the container, the state should be `Created`
sudo crictl ps -a

CONTAINER           IMAGE                           CREATED              STATE               NAME                     ATTEMPT             POD ID
1d056e4a8a168       hydai/wasm-wasi-example:latest   About a minute ago   Created             podsandbox1-wasm-wasi   0                   7992e75df00cc

# Start the container
sudo crictl start 1d056e4a8a168f0c76af122d42c98510670255b16242e81f8e8bce8bd3a4476f
1d056e4a8a168f0c76af122d42c98510670255b16242e81f8e8bce8bd3a4476f

# Check the container status again.
# If the container is not finishing its job, you will see the Running state
# Because this example is very tiny. You may see Exited at this moment.
sudo crictl ps -a
CONTAINER           IMAGE                           CREATED              STATE               NAME                     ATTEMPT             POD ID
1d056e4a8a168       hydai/wasm-wasi-example:latest   About a minute ago   Running             podsandbox1-wasm-wasi   0                   7992e75df00cc

# When the container is finished. You can see the state becomes Exited.
sudo crictl ps -a
CONTAINER           IMAGE                           CREATED              STATE               NAME                     ATTEMPT             POD ID
1d056e4a8a168       hydai/wasm-wasi-example:latest   About a minute ago   Exited              podsandbox1-wasm-wasi   0                   7992e75df00cc

# Check the container's logs
sudo crictl logs 1d056e4a8a168f0c76af122d42c98510670255b16242e81f8e8bce8bd3a4476f

Test 1: Print Random Number
Random number: 960251471

Test 2: Print Random Bytes
Random bytes: [50, 222, 62, 128, 120, 26, 64, 42, 210, 137, 176, 90, 60, 24, 183, 56, 150, 35, 209, 211, 141, 146, 2, 61, 215, 167, 194, 1, 15, 44, 156, 27, 179, 23, 241, 138, 71, 32, 173, 159, 180, 21, 198, 197, 247, 80, 35, 75, 245, 31, 6, 246, 23, 54, 9, 192, 3, 103, 72, 186, 39, 182, 248, 80, 146, 70, 244, 28, 166, 197, 17, 42, 109, 245, 83, 35, 106, 130, 233, 143, 90, 78, 155, 29, 230, 34, 58, 49, 234, 230, 145, 119, 83, 44, 111, 57, 164, 82, 120, 183, 194, 201, 133, 106, 3, 73, 164, 155, 224, 218, 73, 31, 54, 28, 124, 2, 38, 253, 114, 222, 217, 202, 59, 138, 155, 71, 178, 113]

Test 3: Call an echo function
Printed from wasi: This is from a main function
This is from a main function

Test 4: Print Environment Variables
The env vars are as follows.
PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
TERM: xterm
HOSTNAME: crictl_host
PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
The args are as follows.
/var/lib/containers/storage/overlay/006e7cf16e82dc7052994232c436991f429109edea14a8437e74f601b5ee1e83/merged/wasi_example_main.wasm
50000000

Test 5: Create a file `/tmp.txt` with content `This is in a file`

Test 6: Read the content from the previous file
File content is This is in a file

Test 7: Delete the previous file
```

# Kubernetes: Manage WebAssembly programs and Docker containers side by side

TBD

# Appendix: Build from source

## Get Source Code

```bash
$ git clone git@github.com:second-state/crunw.git
$ cd crunw
$ git checkout 0.1.0
```

## Prepare the environment

### Use our docker image

Our docker image use `ubuntu 20.04` as the base.

```bash
$ docker pull secondstate/crunw
```

### Or setup the environment manually

```bash
# Tools and libraries
$ sudo apt install -y \
        software-properties-common \
        cmake \
        libboost-all-dev \
        libsystemd-dev

# And you will need to install llvm
$ sudo apt install -y \
        llvm-10-dev \
        liblld-10-dev

# RUNW supports both clang++ and g++ compilers
# You can choose one of them for building this project
$ sudo apt install -y gcc g++
$ sudo apt install -y clang
```

## Build CRUNW

```bash
# After pulling our runw docker image
$ docker run -it --rm \
    -v <path/to/your/runw/source/folder>:/root/crunw \
    secondstate/crunw:latest
(docker)$ cd /root/crunw
(docker)$ mkdir -p build && cd build
(docker)$ cmake -DCMAKE_BUILD_TYPE=Release .. && make -j
(docker)$ exit
```

