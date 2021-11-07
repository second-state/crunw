#!/bin/bash
export KUBECONFIG=/var/run/kubernetes/admin.kubeconfig
./kubernetes/cluster/kubectl.sh &
# Check 
sudo crictl pods
export KUBERNETES_PROVIDER=local
sudo ./kubernetes/cluster/kubectl.sh run -it --rm --restart=Never wasi-demo --image=hydai/wasm-wasi-example:latest /wasi_example_main.wasm 50000000
