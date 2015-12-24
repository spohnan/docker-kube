#### Scripts intended to automate the following guide

https://github.com/kubernetes/kubernetes/blob/release-1.1/docs/getting-started-guides/docker.md


#### Usage example

Start everything

```
./centos-7/kube-up.sh
...
service "kube-ui" exposed
Client Version: version.Info{Major:"1", Minor:"1", GitVersion:"v1.1.3", GitCommit:"6a81b50c7e97bbe0ade075de55ab4fa34f049dc2", GitTreeState:"clean"}
Server Version: version.Info{Major:"1", Minor:"1", GitVersion:"v1.1.3", GitCommit:"6a81b50c7e97bbe0ade075de55ab4fa34f049dc2", GitTreeState:"clean"}
View the UI at: http://localhost:8080/api/v1/proxy/namespaces/default/services/kube-ui/
```

Add the suggested alias

```
alias k8='~/dev/workspace/docker-kube/centos-7/bin/kubectl'
```

Test using kubectl client

```
$ k8 get nodes
NAME        LABELS                             STATUS    AGE
127.0.0.1   kubernetes.io/hostname=127.0.0.1   Ready     3m
```

Tear down when you're done

```
./centos-7/kube-down.sh
```