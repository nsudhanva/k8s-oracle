apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: k3s-docs-route
  namespace: default
spec:
  parentRefs:
  - name: public-gateway
    namespace: envoy-gateway-system
    sectionName: https-k3s-docs
  hostnames:
  - "k3s.sudhanva.me"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: k3s-docs
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: k3s-docs-redirect
  namespace: default
spec:
  parentRefs:
  - name: public-gateway
    namespace: envoy-gateway-system
    sectionName: http
  hostnames:
  - "k3s.sudhanva.me"
  rules:
  - filters:
    - type: RequestRedirect
      requestRedirect:
        scheme: https
        statusCode: 301
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: k3s-docs-tls
  namespace: default
spec:
  secretName: k3s-docs-tls
  issuerRef:
    name: cloudflare-issuer
    kind: ClusterIssuer
  commonName: "k3s.sudhanva.me"
  dnsNames:
  - "k3s.sudhanva.me"
