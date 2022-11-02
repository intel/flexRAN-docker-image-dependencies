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

#### SRIOV DP configuration 
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

