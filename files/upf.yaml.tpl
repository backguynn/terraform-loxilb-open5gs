logger:
  file:
    path: /var/log/open5gs/upf.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

upf:
  pfcp:
    server:
      - address: ${upf_pfcp_address}
    client:
#      smf:     #  UPF PFCP Client try to associate SMF PFCP Server
#        - address: 127.0.0.4
  gtpu:
    server:
      - address: ${upf_gtpu_address}
  session:
    - subnet: ${upf_ipv4_subnet}
      gateway: ${upf_ipv4_gateway}
    - subnet: ${upf_ipv6_subnet}
      gateway: ${upf_ipv6_gateway}
  metrics:
    server:
      - address: 127.0.0.7
        port: 9090