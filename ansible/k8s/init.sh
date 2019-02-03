#!/bin/bash
###########env####################
DOCKER_PKGS_DIR=/root/docker_pkgs

###########hosts###########
grep 'kube-master' /etc/hosts || echo '192.168.1.118  kube-master
192.168.1.119  kube-node1
192.168.1.120  kube-node2
192.168.1.121  kube-normal' >> /etc/hosts
###########selinux###########
setenforce 0

###########iptables###########
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl -p

###########docker_install###########
if [ ! -d $DOCKER_PKGS_DIR ];then 
	echo "$DOCKER_PKGS_DIR doesn't exists!"
	exit 1
fi
cd $DOCKER_PKGS_DIR && yum -y install ./*.rpm &>/dev/null
[ $? -eq 0 ]  && systemctl restart docker
###########docker_conf###########
docker version | grep -i version
#sed -i '/proxy=http:\/\/127.0.0.1:8118/d' /etc/yum.conf
#mkdir -p /usr/lib/systemd/system/docker.service.d
#echo '[Service]
#Environment="HTTP_PROXY=http://127.0.0.1:8118" "NO_PROXY=localhost,172.16.0.0/16,127.0.0.1,10.244.0.0/16"' > /usr/lib/systemd/system/docker.service.d/http-proxy.conf
#echo '[Service]
#Environment="HTTPS_PROXY=http://127.0.0.1:8118" "NO_PROXY=localhost,172.16.0.0/16,127.0.0.1,10.244.0.0/16"' > /usr/lib/systemd/system/docker.service.d/https-proxy.conf
cat <<EOF >/etc/docker/daemon.json
{
 "registry-mirrors": ["https://registry.docker-cn.com"]
}
EOF
systemctl daemon-reload \
&& systemctl restart docker \
&& systemctl enable docker
if [ $? -ne 0 ]; then 
	echo "docker restart err"
	exit 2
fi

###########k8s_yum_conf###########
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
###########kube_install###########
yum -y install kubelet kubeadm kubectl \
&& systemctl enable kubelet \
&& systemctl start kubelet &>/dev/null
[ $? -eq 0 ] && echo "kube_install ok" || exit 3
