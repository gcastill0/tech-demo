In the Kubernetes environment, we want to expose a frontend Web application via an Ingress controller. This method is preferred to manage multiple services behind a single external IP and route traffic.

### Install NGINX Ingress Controller using Helm

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx
```

### Manage the EKS cluster 

```bash
aws eks --region us-east-1 update-kubeconfig --name wiz-eks-cluster
```