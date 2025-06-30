apiVersion: apps/v1
kind: Deployment
metadata:
  name: kube-loxilb
  namespace: kube-system
  labels:
    app: kube-loxilb-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kube-loxilb-app
  template:
    metadata:
      labels:
        app: kube-loxilb-app
    spec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      tolerations:
        # Mark the pod as a critical add-on for rescheduling.
        - key: CriticalAddonsOnly
          operator: Exists
      priorityClassName: system-node-critical
      serviceAccountName: kube-loxilb
      terminationGracePeriodSeconds: 0
      containers:
      - name: kube-loxilb
        image: ghcr.io/loxilb-io/kube-loxilb:latest
        imagePullPolicy: Always
        command:
        - /bin/kube-loxilb
        args:
        - --loxiURL=http://${loxilb_ip}:11111
        - --cidrPools=defaultPool=${loxilb_ip}/32
        - --setLBMode=1
        - --appendEPs
        resources:
          requests:
            cpu: "100m"
            memory: "50Mi"
          limits:
            cpu: "100m"
            memory: "50Mi"
        securityContext:
          privileged: true
          capabilities:
            add: ["NET_ADMIN", "NET_RAW"]
