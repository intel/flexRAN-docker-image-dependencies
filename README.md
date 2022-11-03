# FlexRAN™ software reference stack
Intel provides a vRAN reference architecture in the form of the FlexRAN™ software reference stack,
which demonstrates how to optimize VDU software implementations using Intel® C++ class libraries, 
leveraging the Intel® Advanced Vector Extensions 512 (Intel® AVX-512) instruction set. 
The multi-threaded design allows a single VDU software implementation to scale to meet the requirements of multiple deployment scenarios, 
scaling from single small cells deployments, optimized D-RAN deployments or servicing large number of 5G cells in C-RAN pooled deployments. 
As a SW implementation, it is also capable of supporting LTE, 5G narrow band and 5G massive MIMO deployments all from the same SW stack using the O-RAN 7.2x split.
The FlexRAN™ software reference solution framework by Intel is shown in below diagram: 
![image](https://user-images.githubusercontent.com/94888960/199504629-afdf2518-f328-403d-8155-c38364d1d593.png)


# FlexRAN™ docker image 
Since 2022, intel FlexRAN team is publishing docker image to docker hub. The purpose is to make more and more potential users can easily enter the door and play the game. 
the docker image include only binaries, runtime dependency libraries, configure files and several typical cases. If downloader had already been a NDA customer of Intel, 
they can get corresponding source code, more test cases and supports from Intel FlexRAN team. 
if you are new entry users and just want to do a quick try, please follow below guides. if you have further intention, please contact Intel FlexRAN Marketing team. 

# User Guide
## HW list
![image](https://user-images.githubusercontent.com/94888960/199509153-a4fcbeea-f0ff-4b81-a92a-e968b690f963.png)
## SW list
![image](https://user-images.githubusercontent.com/94888960/199515453-0f2a8478-a29a-49d1-a90e-05019bcebfbd.png)
## Prequisition
### RT kernel configuration
#### Install TuneD:
$ apt install tuned
$ ln -s /boot/grub/grub.cfg /etc/grub2.cfg
$ vim/etc/grub.d/00_tuned
#### add following line to the end of this file
echo "export tuned_params"
Edit /etc/tuned/realtime-variables.conf to add isolated_cores=1-27, 29-55:
#### Examples:
isolated_cores=1-27,29-55

Edit /usr/lib/tuned/realtime/tuned.conf to add nohz and rcu related parameters:
#### Examples:
cmdline_realtime=+isolcpus=${managed_irq}${isolated_cores} intel_pstate=disable
nosoftlockup tsc=nowatchdog nohz=on nohz_full=${isolated_cores} rcu_nocbs=${isolated_cores}
#### Activate Real-Time Profile:
$ tuned-adm profile realtime
#### Check tuned_params:
$ grep tuned_params= /boot/grub/grub.cfg
set tuned_params="skew_tick=1 isolcpus=1-27,29-55 intel_pstate=disable nosoftlockup tsc=nowatchdog nohz=on
nohz_full=1-27,29-55 rcu_nocbs=1-27,29-55 rcu_nocb_poll"
#### The other parameters of this set of best known configuration can be simply added in /etc/defaut/grub as below:
GRUB_CMDLINE_LINUX="intel_iommu=on iommu=pt usbcore.autosuspend=-1 selinux=0 enforcing=0 nmi_watchdog=0
crashkernel=auto softlockup_panic=0 audit=0 cgroup_disable=memory mce=off hugepagesz=1G hugepages=60
hugepagesz=2M hugepages=0 default_hugepagesz=1G kthread_cpus=0,28 irqaffinity=0,28 "
#### Apply the changes by update the grub configuration file.
$ sudo update-grub
$ sudo reboot
#### Reboot the server, and check the kernel parameter, which should look like:
$ cat /proc/cmdline
BOOT_IMAGE=/vmlinuz-5.15.0-1009-realtime root=/dev/mapper/ubuntu--vg-ubuntu--lv ro intel_iommu=on iommu=pt
usbcore.autosuspend=-1 selinux=0 enforcing=0 nmi_watchdog=0 crashkernel=auto softlockup_panic=0 audit=0
cgroup_disable=memory mce=off hugepagesz=1G hugepages=60 hugepagesz=2M hugepages=0 default_hugepagesz=1G
kthread_cpus=0,28 irqaffinity=0,28 skew_tick=1 isolcpus=1-27,29-55 intel_pstate=disable nosoftlockup
tsc=nowatchdog nohz=on nohz_full=1-27,29-55 rcu_nocbs=1-27,29-55 rcu_nocb_poll

### Configure the CPU Frequency and cstate
#### Further improve the deterministic and power efficiency
$ apt install msr-tools
$ cpupower frequency-set -g performance
#### set cpu core frequency to 2.5Ghz 
$ wrmsr -a 0x199 0x1900
#### set cpu uncore to fixed – maximum allowed. disable c6 and c1e
$ wrmsr -p a 0x620 0x1e1e
$ cpupower idle-set -d 3
$ cpupower idle-set -d 2

### kubernetes and docker installation 
make sure specific version of kubernetes and docker had been installed. 
usally we use kubeadm install and initialize kubernetes, please follow the steps listed in below link:
https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

### kubernetes plugins installation
except for kubernetes and docker, below plugin is required: 
#### multus 
follow multus GitHub - https://github.com/intel/multus-cni
#### calico 
follow calico instruction on offical website -  http://docs.projectcalico.org
#### SRIOV (cni and network device plugin)
follow SRIOV instruction on SRIOV GitHub - https://github.com/intel/sriov-network-deviceplugin. 

##### SRIOV DP configuration 
below is an example to cofigure SRIOV DP configure map:  
$cat <<EOF > deployments/configMap.yaml
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

#### Native CPU Management
enable this plugin by following below link:  
https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/  
https://kubernetes.io/docs/tasks/administer-cluster/topology-manager/  

## Prepare env 
### DPDK pakage
#### download DPDK 
$ cd /opt/  
$ wget http://static.dpdk.org/rel/dpdk-21.11.tar.xz  
$ tar xf /opt/dpdk-21.11.tar.xz
#### build and install DPDK
$ cd /opt/dpdk_21.11
$ meson build
$ cd build
$ ninja
$ ninja install

#### build igb_uio
$ cd /opt
$ git clone http://dpdk.org/git/dpdk-kmods
$ cd dpdk-kmods/linux/igb_uio
$ make

#### configure FEC and FVL SRIOV (example as below)
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

After configuration, need to restart SRIOV docker container to make VF resource ready. 
$ cat <<EOF > /opt/restart_sriov_container.sh
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

after restart sriov container, the resources can be seen thru below command: 
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

## install flexRAN thru helm
Intel flexRAN provide helm chart or yaml files for a sample deployment of flexran test. 
if user is NDA customer of flexRAN, they can get those helm chart or yaml files from quarter by quarter release package.
if user is not NDA customer of flexRAN, below give two examples:

### example yaml file for flexran timer mode test
$ cat <<EOF > /opt/flexran_timer_mode.yaml  
apiVersion: v1  
kind: Pod  
metadata:  
  labels:  
    app: flexran-binary-release  
  name: flexran-binary-release  
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
    args: ["sh docker_entry.sh -m timer ; top"]  
    tty: true  
    stdin: true  
    env:  
    - name: LD_LIBRARY_PATH  
      value: /opt/oneapi/lib/intel64  
    image: flexran.docker.registry/flexran_vdu:22.07  
    name: flexran-l1app  
    resources:  
      requests:  
        memory: "32Gi"  
        intel.com/intel_fec_5g: '1'  
        hugepages-1Gi: 16Gi  
      limits:  
        memory: "32Gi"  
        intel.com/intel_fec_5g: '1'  
        hugepages-1Gi: 16Gi  
    volumeMounts:  
    - name: hugepage  
      mountPath: /hugepages  
    - name: varrun  
      mountPath: /var/run/dpdk  
      readOnly: false  
    - name: tests  
      mountPath: /root/flexran/tests  
      readOnly: false  
  - securityContext:  
      privileged: false  
      capabilities:  
        add:  
          - IPC_LOCK  
          - SYS_NICE  
    command: [ "/bin/bash", "-c", "--" ]  
    args: ["sh docker_entry.sh -m timer ; top"]  
    tty: true  
    stdin: true  
    env:  
    - name: LD_LIBRARY_PATH  
      value: /opt/oneapi/lib/intel64  
    image: flexran.docker.registry/flexran_vdu:22.07  
    name: flexran-testmac  
    resources:  
      requests:  
        memory: "12Gi"  
        hugepages-1Gi: 8Gi  
      limits:  
        memory: "12Gi"  
        hugepages-1Gi: 8Gi  
    volumeMounts:  
    - name: hugepage  
      mountPath: /hugepages  
    - name: varrun  
      mountPath: /var/run/dpdk  
      readOnly: false  
    - name: tests  
      mountPath: /root/flexran/tests  
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
 






