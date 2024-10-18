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

---

Ideally we want to set the `externalTrafficPolicy=Local` to ensur that external IP addresses are preserved and routed correctly through the Internet Gateway.

```bash
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.externalTrafficPolicy=Local
```

This means including addittional annotations to the `nginx-ingress` service as follows:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-ingress
  namespace: ingress-nginx
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb  # Or 'classic'
    service.beta.kubernetes.io/aws-load-balancer-internal: "false"  # Ensure it's an external Load Balancer
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  selector:
    app: nginx-ingress

```