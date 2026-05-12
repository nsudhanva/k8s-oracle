apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: oci-vault
spec:
  provider:
    oracle:
      vault: ${vault_ocid}
      region: ${oci_region}
      principalType: InstancePrincipal
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: regcred-sync
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: oci-vault
    kind: ClusterSecretStore
  target:
    name: regcred
    creationPolicy: Owner
    template:
      type: kubernetes.io/dockerconfigjson
      data:
        .dockerconfigjson: |
          {
            "auths": {
              "ghcr.io": {
                "username": "${git_username}",
                "password": "{{ .github_pat }}",
                "email": "${git_email}",
                "auth": "{{ printf "%s:%s" "${git_username}" .github_pat | b64enc }}"
              }
            }
          }
  data:
    - secretKey: github_pat
      remoteRef:
        key: github-pat
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: repo-creds-sync
  namespace: argocd
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: oci-vault
    kind: ClusterSecretStore
  target:
    name: repo-creds
    creationPolicy: Merge
    template:
      metadata:
        labels:
          argocd.argoproj.io/secret-type: repository
      data:
        url: "${git_repo_url}"
        username: "${git_username}"
        password: "{{ .github_pat }}"
  data:
    - secretKey: github_pat
      remoteRef:
        key: github-pat
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: argocd-admin-password-sync
  namespace: argocd
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: oci-vault
    kind: ClusterSecretStore
  target:
    name: argocd-secret
    creationPolicy: Merge
    template:
      data:
        admin.password: "{{ .password_hash }}"
        admin.passwordMtime: "{{ now | date \"2006-01-02T15:04:05Z\" }}"
  data:
    - secretKey: password_hash
      remoteRef:
        key: argocd-admin-password-hash
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: cloudflare-api-token-sync
  namespace: external-dns
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: oci-vault
    kind: ClusterSecretStore
  target:
    name: cloudflare-api-token-secret
    creationPolicy: Owner
  data:
    - secretKey: api-token
      remoteRef:
        key: cloudflare-api-token
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: cert-manager-cloudflare-sync
  namespace: cert-manager
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: oci-vault
    kind: ClusterSecretStore
  target:
    name: cloudflare-api-token-secret
    creationPolicy: Owner
  data:
    - secretKey: api-token
      remoteRef:
        key: cloudflare-api-token
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: openclaw-secrets-sync
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: oci-vault
    kind: ClusterSecretStore
  target:
    name: openclaw-secrets
    creationPolicy: Owner
  data:
    - secretKey: gateway-token
      remoteRef:
        key: openclaw-gateway-token
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: telegram-bot-token-sync
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: oci-vault
    kind: ClusterSecretStore
  target:
    name: telegram-bot-token
    creationPolicy: Owner
  data:
    - secretKey: telegram-bot-token
      remoteRef:
        key: telegram-bot-token
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: gemini-api-key-sync
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: oci-vault
    kind: ClusterSecretStore
  target:
    name: gemini-api-key
    creationPolicy: Owner
  data:
    - secretKey: api-key
      remoteRef:
        key: gemini-api-key
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: google-places-api-key-sync
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: oci-vault
    kind: ClusterSecretStore
  target:
    name: google-places-api-key
    creationPolicy: Owner
  data:
    - secretKey: api-key
      remoteRef:
        key: google-places-api-key
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: gog-keyring-password-sync
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: oci-vault
    kind: ClusterSecretStore
  target:
    name: gog-keyring-password
    creationPolicy: Owner
  data:
    - secretKey: password
      remoteRef:
        key: gog-keyring-password
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: github-pat-sync
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: oci-vault
    kind: ClusterSecretStore
  target:
    name: github-pat
    creationPolicy: Owner
  data:
    - secretKey: github-pat
      remoteRef:
        key: github-pat
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: alphavantage-api-key-sync
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: oci-vault
    kind: ClusterSecretStore
  target:
    name: alphavantage-api-key
    creationPolicy: Owner
  data:
    - secretKey: api-key
      remoteRef:
        key: alphavantage-api-key
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: bw-credentials-sync
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: oci-vault
    kind: ClusterSecretStore
  target:
    name: bw-credentials
    creationPolicy: Owner
  data:
    - secretKey: client-id
      remoteRef:
        key: bw-client-id
    - secretKey: client-secret
      remoteRef:
        key: bw-client-secret
    - secretKey: master-password
      remoteRef:
        key: bw-master-password
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: nvidia-api-key-sync
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: oci-vault
    kind: ClusterSecretStore
  target:
    name: nvidia-api-key
    creationPolicy: Owner
  data:
    - secretKey: api-key
      remoteRef:
        key: nvidia-api-key
