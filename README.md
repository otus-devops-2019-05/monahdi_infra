# monahdi_infra
monahdi Infra repository
## HW3
Created two hosts. The first is *bastion* host has a public ip, and the second is *someinternalhost* has no public ip.
Goinng to *someinternalhost*, need to connect VPN at bastion
``` openvpn cloud-bastion.ovpn ```
and then connecting to *someinternalhost* 
``` ssh -i ~/.ssh/<username> <username>@< IP someinternalhost> ```

Connecting data: 
``` bastion_IP = 34.77.141.228
someinternalhost_IP = 10.132.0.3 ```
