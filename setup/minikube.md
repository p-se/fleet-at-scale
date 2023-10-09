# Kubernetes on a VM

There are multiple options for running Kubernetes locally: `kind`, `minikube`, `k3d`, etc. However, not all of them work the same on every machine (Linux vs. macOS, or ARM vs. Intel CPUs).
Also, not every setup allows limiting the amount of resources to be used, so using a dedicated virtual machine can help with that.

## Running Colima

[colima](https://github.com/abiosoft/colima) is a high-level layer over [Lima](https://lima-vm.io), which allows using QEMU and macOS Virtualization.Framework to run lightweight virtual machines on Linux and macOS.
Please refer to the [project's instructions for installing it](https://github.com/abiosoft/colima#installation).

```shell
colima start --cpu=8 --memory=8 --runtime docker --vm-type vz --vz-rosetta
```
> NOTE: `--vm-type vz` is only available on macOS, use `qemu` on Linux

This should start a new virtual machine running a Docker daemon, and configure your local Docker client to use it.

## Running Minikube

Minikube was one of the earliest options to easily run Kubernetes locally. Nowadays, there are many other smaller solutions that may get you a similar experience.
However, for certain cases, we may still want to get a more complete setup, so Minikube remains a valuable alternative.
Please refer to the [project's instructions for installing it](https://minikube.sigs.k8s.io/docs/start/).

```shell
minikube addons disable metrics-server
minikube start --driver=docker --cpus=7 --memory=7g --container-runtime=containerd \
         --bootstrapper=kubeadm --extra-config=kubelet.authentication-token-webhook=true --extra-config=kubelet.authorization-mode=Webhook --extra-config=scheduler.bind-address=0.0.0.0 --extra-config=controller-manager.bind-address=0.0.0.0
```

This should create a minikube cluster inside the previously created Docker daemon.
The additional options added are [recommended by the Kube Prometheus docs](https://github.com/prometheus-operator/kube-prometheus/#minikube).
