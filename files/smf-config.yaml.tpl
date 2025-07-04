apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-smf-config
  labels:
    epc-mode: smf
data:
  smf.yaml: |
    logger:
        file: /var/log/open5gs/smf.log

    parameter:
        no_ipv6: true

    smf:
        sbi:     
        - addr: 0.0.0.0
          advertise: {{ .Release.Name }}-smf
        pfcp:
           dev: {{ .Values.smf.N4Int }}
        gtpc:
           dev: {{ .Values.smf.N4Int }}
        gtpu:
           dev: {{ .Values.smf.N4Int }}
        subnet:
         - addr: ${smf_subnet}
           dnn: {{ .Values.dnn }}
        dns:
          - 8.8.8.8
          - 8.8.4.4
        mtu: 1400

    nrf:
     sbi:
      name: {{ .Release.Name }}-nrf

    upf:
      pfcp:
        - addr: {{ .Values.smf.upfPublicIP }}
          dnn: {{ .Values.dnn }}