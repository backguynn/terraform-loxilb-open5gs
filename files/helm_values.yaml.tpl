# Default values for open5gs-epc-helm.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

open5gs:
  image:
    repository: registry.gitlab.com/infinitydon/registry/open5gs-aio
    pullPolicy: IfNotPresent
    tag: v2.5.6

webui:
  image:
    repository: registry.gitlab.com/infinitydon/registry/open5gs-webui
    pullPolicy: IfNotPresent
    tag: "v2.5.6"

ueImport:
  image:
    repository: free5gmano/nextepc-mongodb
    pullPolicy: IfNotPresent
    tag: "latest"

simulator:  
   ue1:
     imsi: "208930000000031"
     imei: "356938035643803"
     imeiSv: "4370816125816151"
     op: "63bfa50ee6523365ff14c1f45f88737d"
     secKey: "0C0A34601D4F07677303652C0462535B"
     sst: "1"
     sd: "1"
   ue2:
     imsi: "208930000000032"
     imei: "356938035643803"
     imeiSv: "4370816125816151"
     op: "63bfa50ee6523365ff14c1f45f88737d"
     secKey: "0C0A34601D4F07677303652C0462535B"
     sst: "1"
     sd: "1"     

dnn: internet

k8swait:
  repository: groundnuty/k8s-wait-for
  tag: v1.6
  pullPolicy: IfNotPresent  

k8s:
  interface: eth0

amf:
  mcc: 208
  mnc: 93
  tac: 7
  networkName: Open5GS
  ngapInt: eth0

smf:
  N4Int: eth0
  upfPublicIP: ${upf_public_ip}

nssf:
  sst: "1"
  sd: "1"  

prometheus:
  nodeExporter:
     repository: quay.io/prometheus/node-exporter
     tag: v1.3.1
     pullPolicy: IfNotPresent