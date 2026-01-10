apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-gateway-to-secrets
  namespace: default
spec:
  from:
  - group: gateway.networking.k8s.io
    kind: Gateway
    namespace: envoy-gateway-system
  to:
  - group: ""
    kind: Secret
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-gateway-to-secrets
  namespace: argocd
spec:
  from:
  - group: gateway.networking.k8s.io
    kind: Gateway
    namespace: envoy-gateway-system
  to:
  - group: ""
    kind: Secret
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
  parametersRef:
    group: gateway.envoyproxy.io
    kind: EnvoyProxy
    name: custom-proxy-config
    namespace: envoy-gateway-system
---
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyProxy
metadata:
  name: custom-proxy-config
  namespace: envoy-gateway-system
spec:
  provider:
    type: Kubernetes
    kubernetes:
      envoyService:
        type: ClusterIP
      useListenerPortAsContainerPort: true
      envoyDeployment:
        pod:
          nodeSelector:
            role: ingress
          tolerations:
            - effect: NoSchedule
              key: node-role.kubernetes.io/control-plane
              operator: Exists
          securityContext:
            runAsUser: 0
            runAsGroup: 0
            runAsNonRoot: false
        container:
          securityContext:
            runAsUser: 0
            runAsGroup: 0
            runAsNonRoot: false
            capabilities:
              add:
                - NET_BIND_SERVICE
        patch:
          type: StrategicMerge
          value:
            spec:
              template:
                spec:
                  containers:
                    - name: envoy
                      ports:
                        - containerPort: 80
                          hostPort: 80
                          name: http
                          protocol: TCP
                        - containerPort: 443
                          hostPort: 443
                          name: https
                          protocol: TCP
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: public-gateway
  namespace: envoy-gateway-system
spec:
  gatewayClassName: eg
  listeners:
    - name: http
      port: 80
      protocol: HTTP
      allowedRoutes:
        namespaces:
          from: All
    - name: https-docs
      port: 443
      protocol: HTTPS
      hostname: "${domain_name}"
      allowedRoutes:
        namespaces:
          from: All
      tls:
        mode: Terminate
        certificateRefs:
          - name: docs-tls
            namespace: default
    - name: https-argocd
      port: 443
      protocol: HTTPS
      hostname: "cd.${domain_name}"
      allowedRoutes:
        namespaces:
          from: All
      tls:
        mode: Terminate
        certificateRefs:
          - name: argocd-tls
            namespace: argocd
