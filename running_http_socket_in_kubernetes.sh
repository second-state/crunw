#!/bin/bash
export KUBERNETES_PROVIDER=local
sudo ./kubernetes/cluster/kubectl.sh config set-cluster local --server=https://localhost:6443 --certificate-authority=/var/run/kubernetes/server-ca.crt
sudo ./kubernetes/cluster/kubectl.sh config set-credentials myself --client-key=/var/run/kubernetes/client-admin.key --client-certificate=/var/run/kubernetes/client-admin.crt
sudo ./kubernetes/cluster/kubectl.sh config set-context local --cluster=local --user=myself
sudo ./kubernetes/cluster/kubectl.sh config use-context local
sudo ./kubernetes/cluster/kubectl.sh
sudo crictl pods
sudo ./kubernetes/cluster/kubectl.sh cluster-info
