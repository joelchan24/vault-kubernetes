# Vault Deployment

In this readme we can find the steps to deploy vault into kubernetes using a custom helm chart

**Requirements**

- Helm
- openssl
- Kubernetes


## Hands-On

1. Generate certificates using openssl in the folder tls

    ```bash
    cd tls
    sh ./wildecard.sh
    ```

2. Create kubernetes secrets with the certificates that were previously created, one for the Primary cluster and one for the DR cluster.

    - Primary Cluster
    
    ```bash     
     kubectl create secret generic vault-primary-secrets -n vault-ns \
     --from-file=tls.crt=./tls/vault-primary.crt  \
     --from-file=tls.key=./tls/vault-primary.key \
     --from-file=tls.ca=./tls/ca.crt \
     --from-file=vault.lic=./tls/license/vault.lic 
    ```

    - DR cluster
    
    ```bash     
     kubectl create secret generic vault-primary-secrets -n vault-ns \
     --from-file=tls.crt=./tls/vault-dr.crt  \
     --from-file=tls.key=./tls/vault-dr.key \
     --from-file=tls.ca=./tls/ca.crt \
     --from-file=vault.lic=./tls/license/vault.lic 
    ```

3. Install Vault into kubernetes with helm using a custom chart with our configurations
   
    - Primary Cluster
    
    ```bash     
    helm install vault-primary hashicorp/vault --values ./charts/vault_config_primary.yml -n vault-ns
    ```

    - DR cluster
    
    ```bash     
    helm install vault-dr hashicorp/vault --values ./charts/vault_config_dr.yml -n vault-ns
    ```

4. View all the resources
   
    ```bash     
    kubectl get all -n vault-ns
    ```

5. Delete all the resources
   
    ```bash     
    helm delete vault-primary  -n vault-ns
    helm delete vault-dr  -n vault-ns
    kubectl delete secrets/vault-primary-secrets -n vault-ns
    kubectl delete secrets/vault-dr-secrets -n vault-ns
    kubectl delete csr/primary-vault -n vault-ns
    kubectl delete csr/dr-vault -n vault-ns
    kubectl delete pvc --all -n vault-ns
    ```


## appendix

- Creation namespace

  ```bash     
  kubectl create namespace vault-ns
  ```


 This another way to create The certificates, using kubernetes as certification authority

1. We need to create Certificate Signing Requests for both clusters **execute inside the folder tls**

    - Primary Cluster
    
    ```bash     
    cat - <<-EOF | kubectl apply -f -
    apiVersion: certificates.k8s.io/v1
    kind: CertificateSigningRequest
    metadata:
      name: primary-vault
      namespace: vault-ns
    spec:
      request: $(cat vault-primary.csr | base64 | tr -d "\n")
      signerName: kubernetes.io/kube-apiserver-client
      usages:
      - digital signature
      - key encipherment
      - client auth
    EOF
    ```

    - DR cluster
    
    ```bash     
    cat - <<-EOF | kubectl apply -f -
    apiVersion: certificates.k8s.io/v1
    kind: CertificateSigningRequest
    metadata:
      name: dr-vault
      namespace: vault-ns
    spec:
      request: $(cat vault-dr.csr | base64 | tr -d "\n")
      signerName: kubernetes.io/kube-apiserver-client
      usages:
      - digital signature
      - key encipherment
      - client auth
    EOF
    ```

2. This is step is approve the CSRs created in the previous step

    - Primary Cluster
    
    ```bash     
    kubectl certificate approve primary-vault
    ```

    - DR cluster
    
    ```bash     
    kubectl certificate approve dr-vault
    ```

3. Get the certificate from kubernetes **execute inside the folder tls**


    - Primary Cluster
    
    ```bash     
    kubectl get csr primary-vault -n vault-ns -o jsonpath='{.status.certificate}' \
    | base64 --decode > primary.crt
    ```

    - DR cluster
    
    ```bash     
    kubectl get csr dr-vault -n vault-ns -o jsonpath='{.status.certificate}' \
    | base64 --decode > dr.crt
    ```

4. Create kubernetes secrets with the certificates that were previously created, one for the Primary cluster and one for the DR cluster.

    - Primary Cluster
    
    ```bash     
    kubectl create secret generic vault-primary-secrets -n vault-ns \
      --from-file=tls.crt=./tls/primary.crt \
      --from-file=tls.key=./tls/vault-primary.key \
      --from-file=tls.ca=./tls/vault.ca \
      --from-file=vault.lic=./tls/license/vault.lic 
    ```

    - DR cluster
    
    ```bash     
    kubectl create secret generic vault-dr-secrets -n vault-ns \
      --from-file=tls.crt=./tls/dr.crt \
      --from-file=tls.key=./tls/vault-dr.key \
      --from-file=tls.ca=./tls/vault.ca \
      --from-file=vault.lic=./tls/license/vault.lic 
    ```