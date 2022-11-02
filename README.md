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



