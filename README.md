# OpenShift GitOps

## Installation

```sh
cd operators/gitops
kustomize build | oc apply -f -
```

The installation of this operator will create implicitly a new namespace `openshift-gitops` where control plane workload would be instantiated. 
It may be necessary to check if pods are running properly. 


```sh
watch -n10 oc get pods -n openshift-gitops

NAME                                                         READY   STATUS    RESTARTS   AGE
cluster-5674764c48-rcspm                                     1/1     Running   0          7m48s
kam-6fc74d89bc-dr4bk                                         1/1     Running   0          7m48s
openshift-gitops-application-controller-0                    1/1     Running   0          7m47s
openshift-gitops-applicationset-controller-85c8f65f4-jjmxw   1/1     Running   0          7m46s
openshift-gitops-dex-server-7c89cc59c4-cj6jd                 1/1     Running   0          7m46s
openshift-gitops-redis-7cb8cb9688-6v6xz                      1/1     Running   0          7m47s
openshift-gitops-repo-server-5df857bdc8-9g9mq                1/1     Running   0          7m47s
openshift-gitops-server-78496878bd-cqt8k                     1/1     Running   0          7m47s
```


# Pre-requis Day2

Manifests located into day2 folder set up the following features: 
- Swicthing of control plane workloads on infra nodes
- RBAC for eazytraining-admin users group