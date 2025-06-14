#!/bin/sh

helm template \
    cilium \
    cilium/cilium \
    --version 1.17.4 \
    --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=true \
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set cgroup.autoMount.enabled=false \
    --set cgroup.hostRoot=/sys/fs/cgroup \
    --set k8sServiceHost=localhost \
    --set k8sServicePort=7445 \
    --set bpf.masquerade=true \
    --set egressGateway.enabled=true \
    --set kubeProxyReplacementHealthzBindAddr="0.0.0.0:10256" \
    --set encryption.enabled=true \
    --set encryption.nodeEncryption=true \
    --set encryption.type=wireguard \
    --set bpf.lbExternalClusterIP=true \
    --set operator.prometheus.serviceMonitor.enabled=true \
    --set prometheus.serviceMonitor.enabled=true \
    --set envoy.prometheus.serviceMonitor.enabled=true \
    --set prometheus.serviceMonitor.trustCRDsExist=true | kubectl apply -f -
