mcc: '208'          # Mobile Country Code value
mnc: '93'           # Mobile Network Code value (2 or 3 digits)

nci: '0x000000001'  # NR Cell Identity (36-bit)
idLength: 32        # NR gNB ID length in bits [22...32]
tac: 7              # Tracking Area Code

linkIp: ${gnb_address}   # gNB's local IP address for Radio Link Simulation (Usually same with local IP)
ngapIp: ${gnb_address}  # gNB's local IP address for N2 Interface (Usually same with local IP)
gtpIp: ${gnb_address}    # gNB's local IP address for N3 Interface (Usually same with local IP)

# List of AMF address information
amfConfigs:
  - address: ${amf_service_ip}
    port: 38412

# List of supported S-NSSAIs by this gNB
slices:
  - sst: 1
    sd: 1

# Indicates whether or not SCTP stream number errors should be ignored.
ignoreStreamIds: true