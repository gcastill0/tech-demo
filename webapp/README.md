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

Ideally we want to set the `externalTrafficPolicy=Local` to ensure that external IP addresses are preserved and routed correctly through the Internet Gateway.

```bash
helm upgrade nginx-ingress ingress-nginx/ingress-nginx \
  --set controller.service.externalTrafficPolicy=Local
```

This means including addittional annotations to the `nginx-ingress` service as follows:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-frontend-ingress
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
    service.beta.kubernetes.io/aws-load-balancer-internal: "false"  # Ensure it's an external Load Balancer
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local  # Preserve external IP addresses
  ports:
    - name: http
      port: 80
      targetPort: 80
    - name: https
      port: 443
      targetPort: 443
  selector:
    app: webapp-frontend
```