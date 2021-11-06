**CRUNW** is a OCI compatible runtime for running WASI enabled WebAssembly files inside a container envrionment. It is based on the [crun](https://github.com/containers/crun) runtime, and is extended to support the [WasmEdge](https://github.com/WasmEdge/WasmEdge) WebAssembly runtime.

* [Manage WebAssembly programs as container images](#manage-webAssembly-programs-as-container-images) | [Video demo](https://youtu.be/lr4LsOnqaLY)
* [Manage WebAssembly programs and Docker containers side by side in Kubernetes](#manage-webAssembly-programs-and-docker-containers-side-by-side-in-kubernetes)

# Manage WebAssembly programs as container images

## Prerequisite

---

**Before you proceed**: Please note that you can fast-track the installation and get right up to the [**Simple Wasi Application**](https://github.com/second-state/crunw#simple-wasi-application) **section** if you use the following [crunw_install.sh](https://github.com/second-state/crunw/blob/main/crunw_install.sh) script. The installation script can be used like this ...

First fetch the script from [here](https://raw.githubusercontent.com/second-state/crunw/main/crunw_install.sh) and save it on your system as `crunw_install.sh`.

Then make the script executable.

```bash
sudo chmod a+x crunw_install.sh
```

Then run it.

```bash
./crunw_install.sh
```
Otherwise, please continue on with the following manual steps.

---

Please install the following tools for container management.

* [cri-o](https://cri-o.io/)
* [crictl](https://github.com/kubernetes-sigs/cri-tools)
* [containernetworking-plugins](https://github.com/containernetworking/plugins)
* Optional [buildah](https://github.com/containers/buildah) or [docker](https://github.com/docker/cli) for building container image

### Install required dependencies

The following script is based on Ubuntu 20.04:

You may need to use `sudo` to modify the system files.

```bash
# Install CRI-O
export OS="xUbuntu_20.04"
export VERSION="1.21"
apt update
apt install -y libseccomp2 || sudo apt update -y libseccomp2
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | apt-key add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | apt-key add -

apt-get update
apt-get install criu libyajl2
apt-get install cri-o cri-o-runc cri-tools containernetworking-plugins
systemctl start crio

# Instal WasmEdge

wget -q https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh
bash install.sh --path="/usr/local"
```


## Use pre-built crunw

### Get pre-built crunw from the release page

#### Use deb (Recommanded)
```bash
# Install CRUNW

wget https://github.com/second-state/crunw/releases/download/1.0-wasmedge/crunw_1.0-wasmedge+dfsg-1_amd64.deb
dpkg -i crunw_1.0-wasmedge+dfsg-1_amd64.deb
```

#### Use tarball (You will need take care of the dependencies by yourself)

```bash
# Install CRUNW

export TMP_DIR="crunw-tmp-folder"
mkdir -p $TMP_DIR
cd $TMP_DIR
wget https://github.com/second-state/crunw/releases/download/1.0-wasmedge/crunw_1.0-wasmedge+dfsg-1_amd64.tar.xz
tar -xf crunw_1.0-wasmedge+dfsg-1_amd64.tar.xz
cp usr/bin/crun /usr/bin/crun
cp usr/lib/x86_64-linux-gnu/libcrun.a /usr/lib/x86_64-linux-gnu/libcrun.a
cd ..
rm -rf $TMP_DIR
```

> If you are not on Ubuntu 20.04, you will need to build your own CRUNW binary. Follow instructions in the appendix.


## Configure your CRI-O settings

### crio.conf

The path of `crio.conf` should be `/etc/crio/crio.conf`.

We use the default `crio.conf` with little changes to switch the default runtime to our `crunw`.

```toml
[crio.runtime]
default_runtime = "crunw"
```

We also provide the full `crio.conf` in the appendix.

### 01-crio-runc.conf

The path of `01-crio-runc.conf` should be `/etc/crio/crio.conf.d/01-crio-runc.conf`.

Also, add the same name of the runtime configuration in the `01-crio-runc.conf`

```toml
[crio.runtime.runtimes.runc]
runtime_path = "/usr/lib/cri-o-runc/sbin/runc"
runtime_type = "oci"
runtime_root = "/run/runc"
# The above is the original content

# Add our crunw runtime here
[crio.runtime.runtimes.crunw]
runtime_path = "/usr/bin/crun"
runtime_type = "oci"
runtime_root = "/run/crunw"
```

## Restart cri-o to apply the configuration

```bash
systemctl restart crio
```

## Simple Wasi Application

---

**Before you proceed**: Please note the following demo (including downloading the docker image, creating the pod, running and checking the logs) is all automated using a script called [simple_wasi_application.sh](https://raw.githubusercontent.com/second-state/crunw/main/simple_wasi_application.sh). You can use it like this.

```bash
wget https://raw.githubusercontent.com/second-state/crunw/main/simple_wasi_application.sh
sudo chmod a+x simple_wasi_application.sh
./simple_wasi_application.sh
```

Otherwise, please continue with the following manual steps.

---

In this example, we would like to demostrate how to create a simple rust application to get program arguments, retrieve environment variables, generate random number, print string to stdout, and create a file.

For creating the container image and application details, please refer to [Simple Wasi Application](docs/examples/simple_wasi_app.md).

[Demo video on YouTube](https://youtu.be/lr4LsOnqaLY)

### Download wasi-main docker image

We've created a docker image called `wasi-main` which is a very light docker image with the `wasi_example_main.wasm` file.

```bash
crictl pull docker.io/hydai/wasm-wasi-example
```

### Create container config

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
    "/wasi_example_main.wasm", "50000000"
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

### Create sandbox configuration file

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

### Create cri-o POD

```bash
# Create the POD. Output will be different from example.
sudo crictl runp sandbox_config.json
7992e75df00cc1cf4bff8bff660718139e3ad973c7180baceb9c84d074b516a4
# Set a helper variable for later use.
POD_ID=7992e75df00cc1cf4bff8bff660718139e3ad973c7180baceb9c84d074b516a4
```

### Create Container

```bash
# Create the container instance. Output will be different from example.
sudo crictl create $POD_ID container_wasi.json sandbox_config.json
1d056e4a8a168f0c76af122d42c98510670255b16242e81f8e8bce8bd3a4476f
```

### Start Container

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

# Manage WebAssembly programs and Docker containers side by side in Kubernetes

## Requirements

1. Install CRI-O and setup with crunw
2. Install go >= 1.17
3. Install etcd

## Environment

### Setup k8s for local environment

```bash
# Install go
wget https://golang.org/dl/go1.17.1.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.17.1.linux-amd64.tar.gz

# Clone k8s
git clone https://github.com/kubernetes/kubernetes.git
git checkout v1.22.2

# Install etcd with hack script in k8s
sudo CGROUP_DRIVER=systemd CONTAINER_RUNTIME=remote CONTAINER_RUNTIME_ENDPOINT='unix:///var/run/crio/crio.sock' ./hack/install-etcd.sh
sudo cp third_party/etcd/etcd* /usr/local/bin/
# After run the above command, you can find the following files: /usr/local/bin/etcd  /usr/local/bin/etcdctl  /usr/local/bin/etcdutl

# Build and run k8s with CRI-O
sudo CGROUP_DRIVER=systemd CONTAINER_RUNTIME=remote CONTAINER_RUNTIME_ENDPOINT='unix:///var/run/crio/crio.sock' ./hack/local-up-cluster.sh
# Expected output
kubelet ( 29926 ) is running.
wait kubelet ready
No resources found
No resources found
No resources found
127.0.0.1   NotReady   <none>   1s    v1.22.2
2021/10/20 12:27:08 [INFO] generate received request
2021/10/20 12:27:08 [INFO] received CSR
2021/10/20 12:27:08 [INFO] generating key: rsa-2048
2021/10/20 12:27:08 [INFO] encoded CSR
2021/10/20 12:27:08 [INFO] signed certificate with serial number 567797943134773150527871001345021853200115760092
Create default storage class for
storageclass.storage.k8s.io/standard created
Local Kubernetes cluster is running. Press Ctrl-C to shut it down.

Logs:
  /tmp/kube-apiserver.log
  /tmp/kube-controller-manager.log

  /tmp/kube-proxy.log
  /tmp/kube-scheduler.log
  /tmp/kubelet.log

To start using your cluster, you can open up another terminal/tab and run:

  export KUBECONFIG=/var/run/kubernetes/admin.kubeconfig
  cluster/kubectl.sh

Alternatively, you can write to the default kubeconfig:

  export KUBERNETES_PROVIDER=local

  cluster/kubectl.sh config set-cluster local --server=https://localhost:6443 --certificate-authority=/var/run/kubernetes/server-ca.crt
  cluster/kubectl.sh config set-credentials myself --client-key=/var/run/kubernetes/client-admin.key --client-certificate=/var/run/kubernetes/client-admin.crt
  cluster/kubectl.sh config set-context local --cluster=local --user=myself
  cluster/kubectl.sh config use-context local
  cluster/kubectl.sh
```

### Check the pods in another terminal

```bash
sudo crictl pods
# Expected output
POD ID              CREATED             STATE               NAME                       NAMESPACE           ATTEMPT             RUNTIME
3ee37ea90c85d       7 seconds ago       Ready               coredns-755cd654d4-qnvsp   kube-system         0                   (default)
```

### Check cluster info in another terminal

```bash
export KUBERNETES_PROVIDER=local

sudo cluster/kubectl.sh config set-cluster local --server=https://localhost:6443 --certificate-authority=/var/run/kubernetes/server-ca.crt
sudo cluster/kubectl.sh config set-credentials myself --client-key=/var/run/kubernetes/client-admin.key --client-certificate=/var/run/kubernetes/client-admin.crt
sudo cluster/kubectl.sh config set-context local --cluster=local --user=myself
sudo cluster/kubectl.sh config use-context local
sudo cluster/kubectl.sh cluster-info

# Expected output
Cluster "local" set.
User "myself" set.
Context "local" created.
Switched to context "local".
Kubernetes control plane is running at https://localhost:6443
CoreDNS is running at https://localhost:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

### Run wasm program from k8s

```bash
sudo cluster/kubectl.sh run -it --rm --restart=Never wasi-demo --image=hydai/wasm-wasi-example:latest /wasi_example_main.wasm 50000000
Random number: 401583443
Random bytes: [192, 226, 162, 92, 129, 17, 186, 164, 239, 84, 98, 255, 209, 79, 51, 227, 103, 83, 253, 31, 78, 239, 33, 218, 68, 208, 91, 56, 37, 200, 32, 12, 106, 101, 241, 78, 161, 16, 240, 158, 42, 24, 29, 121, 78, 19, 157, 185, 32, 162, 95, 214, 175, 46, 170, 100, 212, 33, 27, 190, 139, 121, 121, 222, 230, 125, 251, 21, 210, 246, 215, 127, 176, 224, 38, 184, 201, 74, 76, 133, 233, 129, 48, 239, 106, 164, 190, 29, 118, 71, 79, 203, 92, 71, 68, 96, 33, 240, 228, 62, 45, 196, 149, 21, 23, 143, 169, 163, 136, 206, 214, 244, 26, 194, 25, 101, 8, 236, 247, 5, 164, 117, 40, 220, 52, 217, 92, 179]
Printed from wasi: This is from a main function
This is from a main function
The env vars are as follows.
The args are as follows.
/wasi_example_main.wasm
50000000
File content is This is in a file
pod "wasi-demo-2" deleted
```

# Appendix: Build from source

## Get Source Code

```bash
git clone git@github.com:second-state/crunw.git
cd crunw
```

## Prepare the environment

### Use our docker image

Our docker image use `ubuntu 20.04` as the base.

```bash
docker pull secondstate/crunw
```

### Or setup the environment manually

```bash
# Tools and libraries
sudo apt install -y \
        software-properties-common \
        cmake \
        libboost-all-dev \
        libsystemd-dev

# And you will need to install llvm
sudo apt install -y \
        llvm-10-dev \
        liblld-10-dev

# RUNW supports both clang++ and g++ compilers
# You can choose one of them for building this project
sudo apt install -y gcc g++
sudo apt install -y clang
```

## Build CRUNW

```bash
# After pulling our runw docker image
docker run -it --rm \
    -v <path/to/your/runw/source/folder>:/root/crunw \
    secondstate/crunw:latest
(docker)$ cd /root/crunw
(docker)$ mkdir -p build && cd build
(docker)$ cmake -DCMAKE_BUILD_TYPE=Release .. && make -j
(docker)$ exit
```

# Appendix: crio.conf

```toml
# The CRI-O configuration file specifies all of the available configuration
# options and command-line flags for the crio(8) OCI Kubernetes Container Runtime
# daemon, but in a TOML format that can be more easily modified and versioned.
#
# Please refer to crio.conf(5) for details of all configuration options.

[crio]

# The default log directory where all logs will go unless directly specified by
# the kubelet. The log directory specified must be an absolute directory.
log_dir = "/var/log/crio/pods"

# Location for CRI-O to lay down the temporary version file.
# It is used to check if crio wipe should wipe containers, which should
# always happen on a node reboot
version_file = "/var/run/crio/version"

# Location for CRI-O to lay down the persistent version file.
# It is used to check if crio wipe should wipe images, which should
# only happen when CRI-O has been upgraded
version_file_persist = "/var/lib/crio/version"

# The crio.api table contains settings for the kubelet/gRPC interface.
[crio.api]

# Path to AF_LOCAL socket on which CRI-O will listen.
listen = "/var/run/crio/crio.sock"

# IP address on which the stream server will listen.
stream_address = "127.0.0.1"

# The port on which the stream server will listen. If the port is set to "0", then
# CRI-O will allocate a random free port number.
stream_port = "0"

# Enable encrypted TLS transport of the stream server.
stream_enable_tls = false

# Path to the x509 certificate file used to serve the encrypted stream. This
# file can change, and CRI-O will automatically pick up the changes within 5
# minutes.
stream_tls_cert = ""

# Path to the key file used to serve the encrypted stream. This file can
# change and CRI-O will automatically pick up the changes within 5 minutes.
stream_tls_key = ""

# Path to the x509 CA(s) file used to verify and authenticate client
# communication with the encrypted stream. This file can change and CRI-O will
# automatically pick up the changes within 5 minutes.
stream_tls_ca = ""

# Maximum grpc send message size in bytes. If not set or <=0, then CRI-O will default to 16 * 1024 * 1024.
grpc_max_send_msg_size = 16777216

# Maximum grpc receive message size. If not set or <= 0, then CRI-O will default to 16 * 1024 * 1024.
grpc_max_recv_msg_size = 16777216

# The crio.runtime table contains settings pertaining to the OCI runtime used
# and options for how to set up and manage the OCI runtime.
[crio.runtime]

# A list of ulimits to be set in containers by default, specified as
# "<ulimit name>=<soft limit>:<hard limit>", for example:
# "nofile=1024:2048"
# If nothing is set here, settings will be inherited from the CRI-O daemon
#default_ulimits = [
#]

# default_runtime is the _name_ of the OCI runtime to be used as the default.
# The name is matched against the runtimes map below.
default_runtime = "crunw"

# If true, the runtime will not use pivot_root, but instead use MS_MOVE.
no_pivot = false

# decryption_keys_path is the path where the keys required for
# image decryption are stored. This option supports live configuration reload.
decryption_keys_path = "/etc/crio/keys/"

# Path to the conmon binary, used for monitoring the OCI runtime.
# Will be searched for using $PATH if empty.
conmon = ""

# Cgroup setting for conmon
conmon_cgroup = "system.slice"

# Environment variable list for the conmon process, used for passing necessary
# environment variables to conmon or the runtime.
conmon_env = [
	"PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
]

# Additional environment variables to set for all the
# containers. These are overridden if set in the
# container image spec or in the container runtime configuration.
default_env = [
]

# If true, SELinux will be used for pod separation on the host.
selinux = false

# Path to the seccomp.json profile which is used as the default seccomp profile
# for the runtime. If not specified, then the internal default seccomp profile
# will be used. This option supports live configuration reload.
seccomp_profile = ""

# Used to change the name of the default AppArmor profile of CRI-O. The default
# profile name is "crio-default". This profile only takes effect if the user
# does not specify a profile via the Kubernetes Pod's metadata annotation. If
# the profile is set to "unconfined", then this equals to disabling AppArmor.
# This option supports live configuration reload.
apparmor_profile = "crio-default"

# Cgroup management implementation used for the runtime.
cgroup_manager = "systemd"

# List of default capabilities for containers. If it is empty or commented out,
# only the capabilities defined in the containers json file by the user/kube
# will be added.
default_capabilities = [
	"CHOWN",
	"DAC_OVERRIDE",
	"FSETID",
	"FOWNER",
	"SETGID",
	"SETUID",
	"SETPCAP",
	"NET_BIND_SERVICE",
	"KILL",
]

# List of default sysctls. If it is empty or commented out, only the sysctls
# defined in the container json file by the user/kube will be added.
default_sysctls = [
]

# List of additional devices. specified as
# "<device-on-host>:<device-on-container>:<permissions>", for example: "--device=/dev/sdc:/dev/xvdc:rwm".
#If it is empty or commented out, only the devices
# defined in the container json file by the user/kube will be added.
additional_devices = [
]

# Path to OCI hooks directories for automatically executed hooks. If one of the
# directories does not exist, then CRI-O will automatically skip them.
hooks_dir = [
	"/usr/share/containers/oci/hooks.d",
]

# List of default mounts for each container. **Deprecated:** this option will
# be removed in future versions in favor of default_mounts_file.
default_mounts = [
]

# Path to the file specifying the defaults mounts for each container. The
# format of the config is /SRC:/DST, one mount per line. Notice that CRI-O reads
# its default mounts from the following two files:
#
#   1) /etc/containers/mounts.conf (i.e., default_mounts_file): This is the
#      override file, where users can either add in their own default mounts, or
#      override the default mounts shipped with the package.
#
#   2) /usr/share/containers/mounts.conf: This is the default file read for
#      mounts. If you want CRI-O to read from a different, specific mounts file,
#      you can change the default_mounts_file. Note, if this is done, CRI-O will
#      only add mounts it finds in this file.
#
#default_mounts_file = ""

# Maximum number of processes allowed in a container.
pids_limit = 1024

# Maximum sized allowed for the container log file. Negative numbers indicate
# that no size limit is imposed. If it is positive, it must be >= 8192 to
# match/exceed conmon's read buffer. The file is truncated and re-opened so the
# limit is never exceeded.
log_size_max = -1

# Whether container output should be logged to journald in addition to the kuberentes log file
log_to_journald = false

# Path to directory in which container exit files are written to by conmon.
container_exits_dir = "/var/run/crio/exits"

# Path to directory for container attach sockets.
container_attach_socket_dir = "/var/run/crio"

# The prefix to use for the source of the bind mounts.
bind_mount_prefix = ""

# If set to true, all containers will run in read-only mode.
read_only = false

# Changes the verbosity of the logs based on the level it is set to. Options
# are fatal, panic, error, warn, info, debug and trace. This option supports
# live configuration reload.
log_level = "info"

# Filter the log messages by the provided regular expression.
# This option supports live configuration reload.
log_filter = ""

# The UID mappings for the user namespace of each container. A range is
# specified in the form containerUID:HostUID:Size. Multiple ranges must be
# separated by comma.
uid_mappings = ""

# The GID mappings for the user namespace of each container. A range is
# specified in the form containerGID:HostGID:Size. Multiple ranges must be
# separated by comma.
gid_mappings = ""

# The minimal amount of time in seconds to wait before issuing a timeout
# regarding the proper termination of the container. The lowest possible
# value is 30s, whereas lower values are not considered by CRI-O.
ctr_stop_timeout = 30

# **DEPRECATED** this option is being replaced by manage_ns_lifecycle, which is described below.
# manage_network_ns_lifecycle = false

# manage_ns_lifecycle determines whether we pin and remove namespaces
# and manage their lifecycle
manage_ns_lifecycle = false

# The directory where the state of the managed namespaces gets tracked.
# Only used when manage_ns_lifecycle is true.
namespaces_dir = "/var/run"

# pinns_path is the path to find the pinns binary, which is needed to manage namespace lifecycle
pinns_path = ""

# The "crio.runtime.runtimes" table defines a list of OCI compatible runtimes.
# The runtime to use is picked based on the runtime_handler provided by the CRI.
# If no runtime_handler is provided, the runtime will be picked based on the level
# of trust of the workload. Each entry in the table should follow the format:
#
#[crio.runtime.runtimes.runtime-handler]
#  runtime_path = "/path/to/the/executable"
#  runtime_type = "oci"
#  runtime_root = "/path/to/the/root"
#
# Where:
# - runtime-handler: name used to identify the runtime
# - runtime_path (optional, string): absolute path to the runtime executable in
#   the host filesystem. If omitted, the runtime-handler identifier should match
#   the runtime executable name, and the runtime executable should be placed
#   in $PATH.
# - runtime_type (optional, string): type of runtime, one of: "oci", "vm". If
#   omitted, an "oci" runtime is assumed.
# - runtime_root (optional, string): root directory for storage of containers
#   state.


[crio.runtime.runtimes.runc]
runtime_path = ""
runtime_type = "oci"
runtime_root = "/run/runc"


# The crio.image table contains settings pertaining to the management of OCI images.
#
# CRI-O reads its configured registries defaults from the system wide
# containers-registries.conf(5) located in /etc/containers/registries.conf. If
# you want to modify just CRI-O, you can change the registries configuration in
# this file. Otherwise, leave insecure_registries and registries commented out to
# use the system's defaults from /etc/containers/registries.conf.
[crio.image]

# Default transport for pulling images from a remote container storage.
default_transport = "docker://"

# The path to a file containing credentials necessary for pulling images from
# secure registries. The file is similar to that of /var/lib/kubelet/config.json
global_auth_file = ""

# The image used to instantiate infra containers.
# This option supports live configuration reload.
pause_image = "k8s.gcr.io/pause:3.6"

# The path to a file containing credentials specific for pulling the pause_image from
# above. The file is similar to that of /var/lib/kubelet/config.json
# This option supports live configuration reload.
pause_image_auth_file = ""

# The command to run to have a container stay in the paused state.
# When explicitly set to "", it will fallback to the entrypoint and command
# specified in the pause image. When commented out, it will fallback to the
# default: "/pause". This option supports live configuration reload.
pause_command = "/pause"

# Path to the file which decides what sort of policy we use when deciding
# whether or not to trust an image that we've pulled. It is not recommended that
# this option be used, as the default behavior of using the system-wide default
# policy (i.e., /etc/containers/policy.json) is most often preferred. Please
# refer to containers-policy.json(5) for more details.
signature_policy = ""

# Controls how image volumes are handled. The valid values are mkdir, bind and
# ignore; the latter will ignore volumes entirely.
image_volumes = "mkdir"

# The crio.network table containers settings pertaining to the management of
# CNI plugins.
[crio.network]

# Path to the directory where CNI configuration files are located.
network_dir = "/etc/cni/net.d/"

# Paths to directories where CNI plugin binaries are located.
plugin_dirs = [
	"/opt/cni/bin/",
]

# A necessary configuration for Prometheus based metrics retrieval
[crio.metrics]

# Globally enable or disable metrics support.
enable_metrics = false

# The port on which the metrics server will listen.
metrics_port = 9090
```
