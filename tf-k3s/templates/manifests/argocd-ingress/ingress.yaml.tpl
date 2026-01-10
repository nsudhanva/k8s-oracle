apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: argocd-route
  namespace: argocd
spec:
  parentRefs:
  - name: public-gateway
    namespace: envoy-gateway-system
  hostnames:
  - "cd.${domain_name}"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: argocd-server
      port: 80
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: argocd-tls
  namespace: argocd
spec:
  secretName: argocd-tls
  issuerRef:
    name: cloudflare-issuer
    kind: ClusterIssuer
    group: cert-manager.io
  commonName: "cd.${domain_name}"
  dnsNames:
  - "cd.${domain_name}"
