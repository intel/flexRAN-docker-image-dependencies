# 1. FlexRAN™ software reference stack

Intel provides a vRAN reference architecture in the form of the FlexRAN™ software reference stack,
which demonstrates how to optimize VDU software implementations using Intel® C++ class libraries,
leveraging the Intel® Advanced Vector Extensions 512 (Intel® AVX-512) instruction set.
The multi-threaded design allows a single VDU software implementation to scale to meet the requirements of multiple deployment scenarios,
scaling from single small cells deployments, optimized D-RAN deployments or servicing large number of 5G cells in C-RAN pooled deployments.
As a SW implementation, it is also capable of supporting LTE, 5G narrow band and 5G massive MIMO deployments all from the same SW stack using the O-RAN 7.2x split.
The FlexRAN™ software reference solution framework by Intel is shown in below diagram:  

![image](https://user-images.githubusercontent.com/94888960/199504629-afdf2518-f328-403d-8155-c38364d1d593.png)

# 2. FlexRAN™ docker image

Since 2022, intel FlexRAN team is publishing docker image to docker hub. The purpose is to make more and more potential users can easily enter the door and play the game.
The docker image include only binaries, runtime dependency libraries, configure files and several typical cases. If downloader had already been a NDA customer of Intel,
They can get corresponding source code, more test cases and supports from Intel FlexRAN team.
If you are new entry users and just want to do a quick try, please follow below guides. if you have further intention, please contact Intel FlexRAN Marketing team.  

# 3. User Guide

## 3.1. HW list

|   Category   |                                            Icelake – SP                                            |
| :----------: | :------------------------------------------------------------------------------------------------: |
|    Board     |                                  Intel Server Board M50CYP2SBSTD                                   |
|     CPU      |                              1x Intel® Xeon® Gold 6338N CPU @2.20 GHz                              |
|    Memory    |                                   8x16GB DDR4 3200 MHz (Samsung)                                   |
|   Storage    |                                     960 Gb SSD M.2 SATA 6Gb/s                                      |
|   Chassis    |                                   2 U Rackmount Server Enclosure                                   |
|     NIC1     |                             1x Fortville NIC X722 Base-T(LoM to CPU-0)                             |
|     NIC2     | 1× Fortville 40 Gbe Ethernet PCIe XL710-QDA2 Dual Port QSFP+<br>(PCIe Add-in-card direct to CPU-0) |
| Baseband dev |      Mount Bryce Card (acc100) to CPU-0,<br> Optional, use software mode only if not present       |

## 3.2. SW list


|  Category   |        Components        |                     Details                     |
| :---------: | :----------------------: | :---------------------------------------------: |
|  Firmware   |           IFWI           |    Includes BIOS, BMC, ME as well as FRUSDR.    |
|             |     Fortville XL710      |            8.20 0x8000a051 1.2879.0             |
|     OS      |       Ubuntu 22.04       | Ubuntu Server 22.04 Realtime kernel 5.15.0-1009 |
|   Drivers   |   i40e for x700 series   |      Use the version comes with rt-5.15.0       |
| Cloudnative |        kubernetes        |                     1.22.1                      |
|             |    Container runtime     |                  Docker 0.19.0                  |
|   FlexRAN   |  FlexRAN 22.07 pacakge   |                      22.07                      |
|  Toolchain  | Intel oneAPI Base Tookit |                  2022.1.2.146                   |
|    DPDK     |       DPDK release       |                      22.11                      |


## 3.3. Prequisition

### 3.3.1. BIOS configuration

below listed the main configuration items of BIOS. 
please note: different server even different BIOS version have different Items. so below configuration is just for reference.


|      Category           |    Items                |           setting            |
| :---------------------: | :---------------------: | :--------------------------: | 
| Processor configuration |  Hyper-Threading        |           enable             |    
|                         |     LLC prefetch        |           enable             |            
|                         |    Extended APIC        |           enable             |                  
| CPU p-state control     | Boot Performance Mode   |       Max. Performance       |                                
|                         | Energy Efficient Turbo  |           Disable            |
|                         |      GPSS timer         |             0us              |
|                         |      Turbo Mode         |            enable            |
|HardWare PM state Control|    HW P-state           |            disable           |
|                         |    EPP enable           |            diable            |
|  CPU C-state Control    |  Enable Monitor Mwait   |            enable            |
|                         |ProcessorC6/CPU C6 report|            enable            |
|                         |Enhanced Halt State(C1E) |            disable           |
| Package C-state Control |    Package C State      |            C0/C1             |
|      Intel VT-d         |       Intel VT-d        |            disable           |


### 3.3.1. RT kernel configuration

Install TuneD:

```shell
$ apt install tuned
$ ln -s /boot/grub/grub.cfg /etc/grub2.cfg
$ vim /etc/grub.d/00_tuned
```

Add following line to the end of this file

```shell
echo "export tuned_params"
```

Edit /etc/tuned/realtime-variables.conf to add isolated_cores=1-27, 29-55:

```shell
isolated_cores=1-27,29-55
```

Edit /usr/lib/tuned/realtime/tuned.conf to add nohz and rcu related parameters:

```shell
cmdline_realtime=+isolcpus=${managed_irq}${isolated_cores} intel_pstate=disable nosoftlockup tsc=nowatchdog nohz=on nohz_full=${isolated_cores} rcu_nocbs=${isolated_cores}
```

Activate Real-Time Profile:

```shell
$ tuned-adm profile realtime
```

Check tuned_params:

```shell
$ grep tuned_params= /boot/grub/grub.cfg
set tuned_params="skew_tick=1 isolcpus=1-27,29-55 intel_pstate=disable nosoftlockup tsc=nowatchdog nohz=on nohz_full=1-27,29-55 rcu_nocbs=1-27,29-55 rcu_nocb_poll"
```

The other parameters of this set of best known configuration can be simply added in /etc/defaut/grub as below:

```shell
GRUB_CMDLINE_LINUX="intel_iommu=on iommu=pt usbcore.autosuspend=-1 selinux=0 enforcing=0 nmi_watchdog=0 crashkernel=auto softlockup_panic=0 audit=0 cgroup_disable=memory mce=off hugepagesz=1G hugepages=60 hugepagesz=2M hugepages=0 default_hugepagesz=1G kthread_cpus=0,28 irqaffinity=0,28 "
```

Apply the changes by update the grub configuration file.

```shell
$ sudo update-grub
$ sudo reboot
```

Reboot the server, and check the kernel parameter, which should look like:

```shell
$ cat /proc/cmdline
BOOT_IMAGE=/vmlinuz-5.15.0-1009-realtime root=/dev/mapper/ubuntu--vg-ubuntu--lv ro intel_iommu=on iommu=pt usbcore.autosuspend=-1 selinux=0 enforcing=0 nmi_watchdog=0 crashkernel=auto softlockup_panic=0 audit=0 cgroup_disable=memory mce=off hugepagesz=1G hugepages=60 hugepagesz=2M hugepages=0 default_hugepagesz=1G kthread_cpus=0,28 irqaffinity=0,28 skew_tick=1 isolcpus=1-27,29-55 intel_pstate=disable nosoftlockup tsc=nowatchdog nohz=on nohz_full=1-27,29-55 rcu_nocbs=1-27,29-55 rcu_nocb_poll
```

### 3.3.2. Configure the CPU Frequency and cstate

Further improve the deterministic and power efficiency

```shell
$ apt install msr-tools
$ cpupower frequency-set -g performance
```

Set cpu core frequency to 2.5Ghz

```shell
$ wrmsr -a 0x199 0x1900
```

Set cpu uncore to fixed – maximum allowed. Disable c6 and c1e

```shell
$ wrmsr -p a 0x620 0x1e1e
$ cpupower idle-set -d 3
$ cpupower idle-set -d 2
```

### 3.3.3. Kubernetes and docker installation

Make sure specific version of kubernetes and docker had been installed.
Usally we use kubeadm install and initialize kubernetes, please follow the steps listed in below link:  
<https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/>
#### 3.3.3.1. Configure operating system
- turn off swap 
  ```shell
  $ swapoff -a
  ```
#### 3.3.3.1. Install docker
  ```shell
  $ apt-get install -y ca-certificates curl gnupg lsb-release
  $ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  $ echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  $ apt-get update -y
  $ apt-get install -y docker-ce=5:20.10.13~3-0~ubuntu-jammy docker-ce-cli=5:20.10.13~3-0~ubuntu-jammy containerd.io
  $ mkdir /etc/docker
  $ cat > /etc/docker/daemon.json <<EOF
  {
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
      "max-size": "100m"
    },
    "storage-driver": "overlay2",
    "storage-opts": [
      "overlay2.override_kernel_check=true"
    ]
  }
  EOF
  $ systemctl enable docker
  $ systemctl daemon-reload
  $ systemctl restart docker
  ```

#### 3.3.3.1. Install kubernetes - thru kubeadm
  Install kubernetes with below command: 
  
  ```shell
  $ curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
  $ echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list
  $ apt update
  $ apt install -y kubectl=1.22.1-00 kubeadm=1.22.1-00 kubelet=1.22.1-00 --allow-downgrades
  $ systemctl enable --now kubelet
  $ systemctl start kubelet
  # Note: If it is the first time that you run this enable command and it reported "containerd.io: command not found" and
  # "Failed to start kubele.service: Unit kubele.service not found", you need to execute from
  # " apt install -y kubectl=1.22.1-00 kubeadm=1.22.1-00 kubelet=1.22.1-00 --allow-downgrades" once again, then it will work.
  $ cat <<EOF > /etc/sysctl.d/k8s.conf
  net.bridge.bridge-nf-call-ip6tables = 1
  net.bridge.bridge-nf-call-iptables = 1
  EOF
  $ sysctl --system
  ```
  
#### 3.3.3.1. configure docker and kubernetes to run behind proxy 

  add below environmental variables to ~/bashrc file for proxy setting: 
  
  ```shell
  $ export http_proxy=<proxy_url>
  $ export https_proxy=<proxy_url>
  $ export no_proxy=localhost,127.0.0.1,10.244.0.0/16,10.96.0.0/12,<host_ip>                                    
  ```
  configure proxy for docker: (add below setting to /etc/systemd/system/docker.service.d/http-proxy.conf)
  
  ```shell
  [Service]
  Environment="HTTP_PROXY=<proxy_url>"
  [Service]
  Environment="HTTPS_PROXY=<proxy_url>"
  ```
  reset docker 
  
  ```shell
  $ systemctl daemon-reload
  $ systemctl restart docker
  ```
  
#### 3.3.3.1. kubernetes initialization
  use below command to initialize kubernetes cluster (master node)
  
  ```shell
  $ kubeadm init --kubernetes-version=v1.22.1 --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=<host_ip> --token-ttl 0 --ignore-preflight-errors=SystemVerification
  $ mkdir -p $HOME/.kube
  $ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  $ sudo chown $(id -u):$(id -g) $HOME/.kube/config
  $ export KUBECONFIG=/etc/kubernetes/admin.conf
  ```
  
  join worker node to cluster
  
  ```shell
  $ kubeadm join <master-ip>:<master-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>
  ```
  
  if worker is the same server as master, ignore the above join procedure. and use below command on master to mitigate the taint 
  
  ```shell
  $ kubectl taint nodes --all node-role.kubernetes.io/master-
  ```

### 3.3.4. Kubernetes plugins installation

Except for kubernetes and docker, below plugin is required (install from master):

- multus:
  - follow multus GitHub - <https://github.com/intel/multus-cni>
  below is the command for installation:
  ```shell
  $ cd /root
  $ git clone https://github.com/intel/multus-cni
  $ cd /root/multus-cni/images
  $ git checkout v3.3
  $ kubectl create -f multus-daemonset.yml
  ```
- calico:
  - follow calico instruction on offical website -  <http://docs.projectcalico.org>
  below is the command for installation: 
  ```shell
  $ wget https://docs.projectcalico.org/v3.18/manifests/calico.yaml --no-check-certificate
  $ kubectl apply -f calico.yaml
  ```
- SRIOV (cni and network device plugin):
  - follow SRIOV instruction on SRIOV GitHub - <https://github.com/intel/sriov-network-deviceplugin>.
  below is the command for installation:
  ```shell
  $ cd /root
  $ git clone https://github.com/intel/sriov-network-device-plugin
  $ docker pull nfvpe/sriov-device-plugin
  ```
  - SRIOV DP configuration  
  below is an example to cofigure SRIOV DP configure map:  

      ```shell
      $ cd sriov-network-device-plugin 
      $ cat <<EOF > deployments/configMap.yaml
      apiVersion: v1  
      kind: ConfigMap  
      metadata:  
        name: sriovdp-config  
        namespace: kube-system  
      data:  
        config.json: |  
          {  
              "resourceList": [  
                  {  
                    "resourceName": "intel_fec_5g",  
                      "deviceType": "accelerator",  
                      "selectors": {  
                          "vendors": ["8086"],  
                          "devices": ["0d5d"]  
                      }  
                  },  
                  {  
                    "resourceName": "intel_sriov_odu",  
                      "selectors": {  
                          "vendors": ["8086"],  
                          "devices": ["154c"],  
                          "drivers": ["vfio-pci"],  
                          "pfNames": ["ens9f1"]  
                      }  
                  },  
                  {  
                    "resourceName": "intel_sriov_oru",  
                      "selectors": {  
                          "vendors": ["8086"],  
                          "devices": ["154c"],  
                          "drivers": ["vfio-pci"],  
                          "pfNames": ["ens9f0"]  
                      }  
                  }  
              ]  
          }  
      EOF  
      $ kubectl create -f deployments/configMap.yaml  
      $ kubectl create -f deployments/k8s-v1.16/sriovdp-daemonset.yaml  
      $ kubectl get node <your-k8s-worker> -o json | jq '.status.allocatable' 
      {  
      "cpu": "28",  
      "ephemeral-storage": "143494008185",  
      "hugepages-1Gi": "48Gi",  
      "intel.com/intel_sriov_dpdk": "4",  
      "intel.com/intel_sriov_netdevice": "4",  
      "memory": "48012416Ki",  
      "pods": "110"  
      }
      ```

  - Native CPU Manager 

  enable this plugin by following below link:  

  - <https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/>  
  - <https://kubernetes.io/docs/tasks/administer-cluster/topology-manager/> 

## 3.4. Prepare env

### 3.4.1. DPDK pakage

Download DPDK

```shell
$ cd /opt/  
$ wget http://static.dpdk.org/rel/dpdk-21.11.tar.xz  
$ tar xf /opt/dpdk-21.11.tar.xz
```

install meson

```shell
$ apt install meson
$ sudo apt-get install python3 python3-pip
$ pip3 install pyelftools
```

Build and install DPDK

```shell
$ cd /opt/dpdk-21.11
$ meson build
$ cd build
$ ninja
$ ninja install
```

Build igb_uio

```shell
$ cd /opt
$ git clone http://dpdk.org/git/dpdk-kmods
$ cd dpdk-kmods/linux/igb_uio
$ make
```

Configure FEC and FVL SRIOV (example as below)

```shell
$ modprobe vfio-pci
$ modprobe uio
$ insmod /opt/dpdk-kmods/linux/igb_uio/igb_uio.ko
$ lspci | grep 0d5c

$ /opt/dpdk-21.11/usertools/dpdk-devbind.py -b igb_uio 0000:b1:00.0
$ echo 0 > /sys/bus/pci/devices/0000:b1:00.0/max_vfs
$ echo 2 > /sys/bus/pci/devices/0000:b1:00.0/max_vfs
$ /opt/dpdk-21.11/usertools/dpdk-devbind.py -b vfio-pci 0000:b2:00.0
$ cd /opt/pf-bb-config
$ ./pf_bb_config ACC100 -c acc100/acc100_config_vf_5g.cfg

$ echo 0 > /sys/bus/pci/devices/0000:4b:00.0/sriov_numvfs
$ echo 4 > /sys/bus/pci/devices/0000:4b:00.0/sriov_numvfs
$ ip link set ens9f0 vf 0 mac 00:11:22:33:00:00
$ ip link set ens9f0 vf 1 mac 00:11:22:33:00:10
$ ip link set ens9f0 vf 2 mac 00:11:22:33:00:20
$ ip link set ens9f0 vf 3 mac 00:11:22:33:00:30
$ /opt/dpdk-21.11/usertools/dpdk-devbind.py -s
$ /opt/dpdk-21.11/usertools/dpdk-devbind.py -b vfio-pci 0000:4b:02.0 0000:4b:02.1
$ /opt/dpdk-21.11/usertools/dpdk-devbind.py -b vfio-pci 0000:4b:02.2 0000:4b:02.3
$ echo 0 > /sys/bus/pci/devices/0000:4b:00.1/sriov_numvfs
$ echo 4 > /sys/bus/pci/devices/0000:4b:00.1/sriov_numvfs
$ modprobe vfio-pci
$ ip link set ens9f1 vf 2 mac 00:11:22:33:00:21
$ ip link set ens9f1 vf 3 mac 00:11:22:33:00:31
$ ip link set ens9f1 vf 0 mac 00:11:22:33:00:01
$ ip link set ens9f1 vf 1 mac 00:11:22:33:00:11
$ /opt/dpdk-21.11/usertools/dpdk-devbind.py -b vfio-pci 0000:4b:0a.0 0000:4b:0a.1
$ /opt/dpdk-21.11/usertools/dpdk-devbind.py -b vfio-pci 0000:4b:0a.2 0000:4b:0a.3
```

After configuration, need to restart SRIOV docker container to make VF resource ready.

```shell
$ cat <<EOF > /opt/restart_sriov_container.sh
  #!/bin/bash
  
  docker ps | grep sriov
  docker kill `docker ps | grep sriov | head -n 1 | awk -F ' ' '{print $1}'`
  while ((`docker ps | grep sriov | wc -l` < 2 ))
  do
     sleep 3
     docker ps | grep sriov >/dev/null 2>&1
     echo "..."
  done
EOF
$chmod +x /opt/restart_sriov_container.sh; sh /opt/restart_sriov_container.sh
```

After restart sriov container, the resources can be seen thru below command:

```shell
$ sudo apt install jq 
$ kubectl get node dockerimagerel -o json | jq '.status.allocatable'
{  
  "cpu": "125",  
  "ephemeral-storage": "427010803415",  
  "hugepages-1Gi": "60Gi",  
  "hugepages-2Mi": "0",  
  "intel.com/intel_fec_5g": "1",  
  "intel.com/intel_sriov_odu": "4",  
  "intel.com/intel_sriov_oru": "4",  
  "memory": "193028Mi",  
  "pods": "110"  
}  
```

label node 

```shell
$ kubectl label node host_name testnode=worker1
```

## 3.5. deployment 

deployment diagram for timer mode test scenario: 

![image](https://github.com/intel-innersource/networking.wireless.flexran.flexran-l1-sw/assets/94888960/a784367c-8fa6-41aa-be22-d2e9342904e1)

deployment diagram for xRAN mode test scenario: 

![image](https://github.com/intel-innersource/networking.wireless.flexran.flexran-l1-sw/assets/94888960/4f55e987-cf33-4478-9257-660feb9e0355)

## 3.6. docker image prepare

login docker hub (for external user)

```shell
$ docker login 
```
input you username/password of your docker hub account 

```shell
$ docker pull intel/flexran_vdu:v22.07
```

for internal user (intel PAE), they can use another way to download docker image from internal harbor: 
login docker hub 

```shell
$ docker login amr-registry-pre.caas.intel.com
```
input your username/passward of your harbor account

```shell
$ docker pull amr-registry-pre.caas.intel.com/flexran/flexran_vdu:v22.07
```

## 3.7. Install flexRAN thru helm

Intel flexRAN provide helm chart or yaml files for a sample deployment of flexran test.
If user is NDA customer of flexRAN, they can get those helm chart or yaml files from 22.07 release package.
If user is Non-NDA customer of flexRAN, below give two examples:

### 3.7.1. Example yaml file for flexran timer mode test

```shell
$ cat <<EOF > /opt/flexran_timer_mode.yaml  
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: flexran-dockerimage_release
  name: flexran-dockerimage-release
spec:
  nodeSelector:
     testnode: worker1
  containers:
  - securityContext:
      privileged: false
      capabilities:
        add:
          - IPC_LOCK
          - SYS_NICE
    command: [ "/bin/bash", "-c", "--" ]
    args: ["sh docker_entry.sh -m timer ; cd /home/flexran/bin/nr5g/gnb/l1/; ./l1.sh -e ; top"]
    tty: true
    stdin: true
    env:
    - name: LD_LIBRARY_PATH
      value: /opt/oneapi/lib/intel64
    image: amr-registry-pre.caas.intel.com/flexran/flexran_vdu:v22.07
    name: flexran-l1app
    resources:
      requests:
        memory: "6Gi"
        intel.com/intel_fec_5g: '1'
        hugepages-1Gi: 8Gi
      limits:
        memory: "6Gi"
        intel.com/intel_fec_5g: '1'
        hugepages-1Gi: 8Gi
    volumeMounts:
    - name: hugepage
      mountPath: /hugepages
    - name: varrun
      mountPath: /var/run/dpdk
      readOnly: false
    - name: tests
      mountPath: /home/flexran/tests
      readOnly: false
  - securityContext:
      privileged: false
      capabilities:
        add:
          - IPC_LOCK
          - SYS_NICE
    command: [ "/bin/bash", "-c", "--" ]
    args: ["sleep 10; sh docker_entry.sh -m timer ; cd /home/flexran/bin/nr5g/gnb/testmac/; ./l2.sh --testfile=icelake-sp/icxsp.cfg; top"]
    tty: true
    stdin: true
    env:
    - name: LD_LIBRARY_PATH
      value: /opt/oneapi/lib/intel64
    image: amr-registry-pre.caas.intel.com/flexran/flexran_vdu:v22.07
    name: flexran-testmac
    resources:
      requests:
        memory: "6Gi"
        hugepages-1Gi: 4Gi
      limits:
        memory: "6Gi"
        hugepages-1Gi: 4Gi
    volumeMounts:
    - name: hugepage
      mountPath: /hugepages
    - name: varrun
      mountPath: /var/run/dpdk
      readOnly: false
    - name: tests
      mountPath: /home/flexran/tests
      readOnly: false
  volumes:
  - name: hugepage
    emptyDir:
      medium: HugePages
  - name: varrun
    emptyDir: {}
  - name: tests
    hostPath:
      path: "/home/tmp_flexran/tests"
EOF  
  
$ kubectl create -f /opt/flexran_timer_mode.yaml
```
note: test cases of timer mode are not included into the docker image by default. if user want to run timer mode, they need contact FlexRAN account team/PAE team to get the 22.07 release package, extract it and copy the sub-folder "test" into host folder - "/home/tmp_flexran". and then execute the pod creation work. 

for timer mode, once the container created, corresponding timer mode test will be run up. And you can check POD status thru - "kubectl describe po pode-name".  
You can also check the status of RAN service thru - "kubectl logs -f pode-name -c container-name"
  
### 3.7.2. Example yaml file for xran mode test

```shell
$ cat <<EOF > /opt/flexran_xran_mode.yaml  
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: flexran-vdu
  name: flexran-vdu
spec:
  nodeSelector:
     testnode: worker1
  containers:
  - securityContext:
      privileged: false
      capabilities:
        add:
          - IPC_LOCK
          - SYS_NICE
    command: [ "/bin/bash", "-c", "--" ]
    args: ["sh docker_entry.sh -m xran ; top"]
    tty: true
    stdin: true
    env:
    - name: LD_LIBRARY_PATH
      value: /opt/oneapi/lib/intel64
    image: amr-registry-pre.caas.intel.com/flexran/flexran_vdu:v22.07
    name: flexran-vdu
    resources:
      requests:
        memory: "12Gi"
        intel.com/intel_fec_5g: '1'
        intel.com/intel_sriov_odu: '4'
        hugepages-1Gi: 16Gi
      limits:
        memory: "12Gi"
        intel.com/intel_fec_5g: '1'
        intel.com/intel_sriov_odu: '4'
        hugepages-1Gi: 16Gi
    volumeMounts:
    - name: hugepage
      mountPath: /hugepages
    - name: varrun
      mountPath: /var/run/dpdk
      readOnly: false
    - name: tests
      mountPath: /home/flexran/tests
      readOnly: false
  volumes:
  - name: hugepage
    emptyDir:
      medium: HugePages
  - name: varrun
    emptyDir: {}
  - name: tests
    hostPath:
      path: "/home/tmp_flexran/tests"
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: flexran-vru
  name: flexran-vru
spec:
  nodeSelector:
     testnode: worker1
  containers:
  - securityContext:
      privileged: false
      capabilities:
        add:
          - IPC_LOCK
          - SYS_NICE
    command: [ "/bin/bash", "-c", "--" ]
    args: ["sh docker_entry.sh -m xran ; top"]
    tty: true
    stdin: true
    env:
    - name: LD_LIBRARY_PATH
      value: /opt/oneapi/lib/intel64
    image: amr-registry-pre.caas.intel.com/flexran/flexran_vdu:v22.07
    name: flexran-oru
    resources:
      requests:
        memory: "4Gi"
        intel.com/intel_sriov_oru: '4'
        hugepages-1Gi: 6Gi
      limits:
        memory: "4Gi"
        intel.com/intel_sriov_oru: '4'
        hugepages-1Gi: 6Gi
    volumeMounts:
    - name: hugepage
      mountPath: /hugepages
    - name: varrun
      mountPath: /var/run/dpdk
      readOnly: false
    - name: tests
      mountPath: /home/flexran/tests
      readOnly: false
  volumes:
  - name: hugepage
    emptyDir:
      medium: HugePages
  - name: varrun
    emptyDir: {}
  - name: tests
    hostPath:
      path: "/home/tmp_flexran/tests"
EOF  

$ kubectl create -f /opt/flexran_xran_mode.yaml
```

For xran mode, once the container created, corresponding xran mode test will not be run up.
You need enter the pod and execute the test manually.
Below chapter give the steps to run xRAN mode test case: "sub3_mu0_20mhz_4x4"

Open a new terminal, run the following command:

```shell
$ kubectl exec -it pod-name -- bash    
$ cd flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_20mhz_4x4/gnb/  
$ ./l1.sh -oru
```
  
Open another new terminal, run the following command:

```shell
$ kubectl exec -it pod-name -- bash    
$ cd flexran/bin/nr5g/gnb/testmac  
$ ./l2.sh --testfile=testmac_clxsp_mu0_20mhz_hton_oru.cfg  

#### Open another new terminal, run the following command:
$ kubectl exec -it pod-name -- bash

$ cd flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_20mhz_4x4/oru/
$ ./run_o_ru.sh
```
note: sometime, you may find app is stucked somewhere when execute this command. at this scenario, you can run ORU with below command:  taskset -c 10 ./run_o_ru.sh

You can run the same for other two test cases.
for 2nd xRAN mode test case: "sub3_mu0_10mhz_4x4"

Open a new terminal, run the following command:

```shell
kubectl exec -it pod-name -- bash    
cd flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_10mhz_4x4/gnb/  
./l1.sh -oru
```
  
Open another new terminal, run the following command:

```shell
$ kubectl exec -it pod-name -- bash    
$ cd flexran/bin/nr5g/gnb/testmac  
$ ./l2.sh --testfile=testmac_clxsp_mu0_10mhz_hton_oru.cfg  

#### Open another new terminal, run the following command:
$ kubectl exec -it pod-name -- bash

$ cd flexran/bin/nr5g/gnb/l1/orancfg/sub3_mu0_10mhz_4x4/oru/
$ ./run_o_ru.sh
```

for 3rd xRAN mode test case: "sub6_mu1_100mhz_4x4"

Open a new terminal, run the following command:

```shell
$ kubectl exec -it pod-name -- bash    
$ cd flexran/bin/nr5g/gnb/l1/orancfg/sub6_mu1_100mhz_4x4/gnb/  
$ ./l1.sh -oru
```
  
Open another new terminal, run the following command:

```shell
$ kubectl exec -it pod-name -- bash    
$ cd flexran/bin/nr5g/gnb/testmac  
$ ./l2.sh --testfile=testmac_clxsp_mu1_100mhz_hton_oru.cfg  

#### Open another new terminal, run the following command:
$ kubectl exec -it pod-name -- bash

$ cd flexran/bin/nr5g/gnb/l1/orancfg/sub6_mu1_100mhz_4x4/oru/
$ ./run_o_ru.sh
```
  
## 3.8. Core pining

Intel docker image also provide the support of core pining feature.
In order to enable this feature, you need to make below configuration and change of yaml file.

### 3.8.1. Configuration

Enable core pining feature： 

```shell
#!/bin/bash
pathfile=/var/lib/kubelet/config.yaml
sed -i 's/cpuManagerReconcilePeriod: 0s/cpuManagerReconcilePeriod: 10s/g' $pathfile

cat >> $pathfile << EOF
cpuManagerPolicy: static
systemReserved:
  cpu: 2000m
  memory: 2000Mi
kubeReserved:
  cpu: 1000m
  memory: 1000Mi
EOF
rm -rf /var/lib/kubelet/cpu_manager_state
systemctl restart kubelet
```
copy above code line to a file and execute:

```shell
$ sh core_pining_kubelet_config.sh
```

Disable core pining feature:

```shell
#!/bin/bash

pathfile=/var/lib/kubelet/config.yaml
#pathfile=config.yaml
sed -i 's/cpuManagerReconcilePeriod: 10s/cpuManagerReconcilePeriod: 0s/g' $pathfile

sed -i 's/cpuManagerPolicy: static/ /g' $pathfile
sed -i 's/systemReserved:/ /g' $pathfile
sed -i 's/cpu: 2000m/ /g' $pathfile
sed -i 's/memory: 2000Mi/ /g' $pathfile
sed -i 's/kubeReserved:/ /g' $pathfile
sed -i 's/cpu: 1000m/ /g' $pathfile
sed -i 's/memory: 1000Mi/ /g' $pathfile
rm -rf /var/lib/kubelet/cpu_manager_state
systemctl restart kubelet
```
copy above code line into a file and execute: 

```shell
$ sh uncore_pining_kubelet_config.sh
```

### 3.8.2. Example yaml file for flexran timer mode test (with core pining)

```shell
$ cat <<EOF > /opt/flexran_timer_mode.yaml  
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: flexran-dockerimage_release
  name: flexran-dockerimage-release
spec:
  nodeSelector:
     testnode: worker1
  containers:
  - securityContext:
      privileged: false
      capabilities:
        add:
          - IPC_LOCK
          - SYS_NICE
    command: [ "/bin/bash", "-c", "--" ]
    args: ["sh docker_entry.sh -m timer ; cd /home/flexran/bin/nr5g/gnb/l1/; ./l1.sh -e ; top"]
    tty: true
    stdin: true
    env:
    - name: LD_LIBRARY_PATH
      value: /opt/oneapi/lib/intel64
    image: amr-registry-pre.caas.intel.com/flexran/flexran_vdu:v22.07
    name: flexran-l1app
    resources:
      requests:
        memory: "12Gi"
        cpu: 24
        intel.com/intel_fec_5g: '1'
        hugepages-1Gi: 16Gi
      limits:
        memory: "12Gi"
        cpu: 24
        intel.com/intel_fec_5g: '1'
        hugepages-1Gi: 16Gi
    volumeMounts:
    - name: hugepage
      mountPath: /hugepages
    - name: varrun
      mountPath: /var/run/dpdk
      readOnly: false
    - name: tests
      mountPath: /home/flexran/tests
      readOnly: false
  - securityContext:
      privileged: false
      capabilities:
        add:
          - IPC_LOCK
          - SYS_NICE
    command: [ "/bin/bash", "-c", "--" ]
    args: ["sleep 10; sh docker_entry.sh -m timer ; cd /home/flexran/bin/nr5g/gnb/testmac/; ./l2.sh --testfile=icelake-sp/icxsp.cfg; top"]
    tty: true
    stdin: true
    env:
    - name: LD_LIBRARY_PATH
      value: /opt/oneapi/lib/intel64
    image: amr-registry-pre.caas.intel.com/flexran/flexran_vdu:v22.07
    name: flexran-testmac
    resources:
      requests:
        memory: "6Gi"
        cpu: 16
        hugepages-1Gi: 4Gi
      limits:
        memory: "6Gi"
        cpu: 16
        hugepages-1Gi: 4Gi
    volumeMounts:
    - name: hugepage
      mountPath: /hugepages
    - name: varrun
      mountPath: /var/run/dpdk
      readOnly: false
    - name: tests
      mountPath: /home/flexran/tests
      readOnly: false
  volumes:
  - name: hugepage
    emptyDir:
      medium: HugePages
  - name: varrun
    emptyDir: {}
  - name: tests
    hostPath:
      path: "/home/tmp_flexran/tests"
EOF  
  
$ kubectl create -f /opt/flexran_timer_mode.yaml
```

for timer mode, once the container created, corresponding timer mode test will be run up. And you can check POD status thru - "kubectl describe po pode-name".  
You can also check the status of RAN service thru - "kubectl logs -f pode-name -c container-name"
  
### 3.8.3. Example yaml file for xran mode test (with core pining)

```shell
$ cat <<EOF > /opt/flexran_xran_mode.yaml  
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: flexran-vdu
  name: flexran-vdu
spec:
  nodeSelector:
     testnode: worker1
  containers:
  - securityContext:
      privileged: false
      capabilities:
        add:
          - IPC_LOCK
          - SYS_NICE
    command: [ "/bin/bash", "-c", "--" ]
    args: ["sh docker_entry.sh -m xran ; top"]
    tty: true
    stdin: true
    env:
    - name: LD_LIBRARY_PATH
      value: /opt/oneapi/lib/intel64
    image: amr-registry-pre.caas.intel.com/flexran/flexran_vdu:v22.07
    name: flexran-vdu
    resources:
      requests:
        memory: "24Gi"
        cpu: 24
        intel.com/intel_fec_5g: '1'
        intel.com/intel_sriov_odu: '4'
        hugepages-1Gi: 24Gi
      limits:
        memory: "24Gi"
        cpu: 24
        intel.com/intel_fec_5g: '1'
        intel.com/intel_sriov_odu: '4'
        hugepages-1Gi: 24Gi
    volumeMounts:
    - name: hugepage
      mountPath: /hugepages
    - name: varrun
      mountPath: /var/run/dpdk
      readOnly: false
    - name: tests
      mountPath: /home/flexran/tests
      readOnly: false
  volumes:
  - name: hugepage
    emptyDir:
      medium: HugePages
  - name: varrun
    emptyDir: {}
  - name: tests
    hostPath:
      path: "/home/tmp_flexran/tests"
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: flexran-vru
  name: flexran-vru
spec:
  nodeSelector:
     testnode: worker1
  containers:
  - securityContext:
      privileged: false
      capabilities:
        add:
          - IPC_LOCK
          - SYS_NICE
    command: [ "/bin/bash", "-c", "--" ]
    args: ["sh docker_entry.sh -m xran ; top"]
    tty: true
    stdin: true
    env:
    - name: LD_LIBRARY_PATH
      value: /opt/oneapi/lib/intel64
    image: amr-registry-pre.caas.intel.com/flexran/flexran_vdu:v22.07
    name: flexran-oru
    resources:
      requests:
        memory: "24Gi"
        cpu: 16
        intel.com/intel_sriov_oru: '4'
        hugepages-1Gi: 16Gi
      limits:
        memory: "24Gi"
        cpu: 16
        intel.com/intel_sriov_oru: '4'
        hugepages-1Gi: 16Gi
    volumeMounts:
    - name: hugepage
      mountPath: /hugepages
    - name: varrun
      mountPath: /var/run/dpdk
      readOnly: false
    - name: tests
      mountPath: /home/flexran/tests
      readOnly: false
  volumes:
  - name: hugepage
    emptyDir:
      medium: HugePages
  - name: varrun
    emptyDir: {}
  - name: tests
    hostPath:
      path: "/home/tmp_flexran/tests"
EOF  

$ kubectl create -f /opt/flexran_xran_mode.yaml
```

For xran mode, once the container created, corresponding xran mode test will not be run up.
You need enter the pod and execute the test manually. the steps are the same as the one without core pining 
  
## 3.9. Legal Disclaimer

For GPL/LGPL open source libs/components used by flexran docker image at run time.
User can find the used version in below git hub repo: <https://github.com/intel/flexRAN-docker-image-dependencies>
  
## 3.10. Customer Support Declare

For further support, please contact intel flexRAN marketing team and FAE/PAE team.

