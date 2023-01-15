#!/bin/bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor \
  -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg \
  https://packages.cloud.google.com/apt/doc/apt-key.gpg
# Add Kubernetes apt repository
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates
set +e sudo apt-get remove -y docker docker-engine \
  docker.io containerd runc
sudo apt-get install -y docker-ce docker-ce-cli containerd.io kubeadm kubectl kubelet=1.22.0-00
# Configure docker to use overlay2 storage and systemd
sudo mkdir -p /etc/docker
cat <<POF | sudo tee /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {"max-size": "100m"},
    "storage-driver": "overlay2"
}
POF
# Restart docker to load new configuration
sudo systemctl restart docker
# Add docker to start up programs
sudo systemctl enable docker
# Allow current user access to docker command line
sudo usermod -aG docker $USER
# Prevent them from being updated automatically
sudo apt-mark hold kubelet kubeadm kubectl
# See if swap is enabled
swapon --show
# Turn off swap
sudo swapoff -a
# Disable swap completely
sudo sed -i -e '/swap/d' /etc/fstab
rm /etc/containerd/config.toml
systemctl restart containerd
