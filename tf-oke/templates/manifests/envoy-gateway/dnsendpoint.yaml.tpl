apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: gateway-dns
  namespace: envoy-gateway-system
spec:
  endpoints:
    - dnsName: ${domain_name}
      recordType: A
      targets:
        - "${load_balancer_ip}"
      providerSpecific:
        - name: cloudflare-proxied
          value: "false"
    - dnsName: cd.${domain_name}
      recordType: A
      targets:
        - "${load_balancer_ip}"
      providerSpecific:
        - name: cloudflare-proxied
          value: "false"
    - dnsName: k3s.sudhanva.me
      recordType: A
      targets:
        - "${load_balancer_ip}"
      providerSpecific:
        - name: cloudflare-proxied
          value: "false"
    - dnsName: gemma.${domain_name}
      recordType: A
      targets:
        - "${load_balancer_ip}"
      providerSpecific:
        - name: cloudflare-proxied
          value: "false"
