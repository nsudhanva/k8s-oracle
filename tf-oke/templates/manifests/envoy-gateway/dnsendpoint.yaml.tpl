apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: gateway-dns
  namespace: envoy-gateway-system
spec:
  endpoints:
    - dnsName: cd.${domain_name}
      recordType: A
      targets:
        - "${load_balancer_ip}"
      providerSpecific:
        - name: cloudflare-proxied
          value: "false"
