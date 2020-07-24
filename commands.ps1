# Setup the environment
# Build Docker container
docker build Dockerfile -t k8s.gcr.io/hpa-example
docker push k8s.gcr.io/hpa-example

# Create an AKS cluster and a resource group
$aksRg="aks-demo"
$aksName="aks-demo"
#create a Resource Group
az group create -n $aksRg -l westeurope
# Create an AKS cluster with 2 nodes
az aks create -g $aksRg `
  -n $aksName `
  --node-count 2
# Connect to the AKS cluster
az aks get-credentials -g $aksRg -n $aksName

# Deploy the app into Kubernetes
kubectl apply -f deploy-svc.yaml

# Note 1 single Pod is deployed as per Deployment/Replicas
kubectl get pods

# Manually scale Pods
kubectl scale --replicas=2 deployment/php-apache

# Note 2 Pods are now deployed as per Deployment/Replicas
kubectl get pods

# Create the HorizontalPodAutoscaler (HPA)
kubectl apply -f hpa.yaml

# Note 3 Pods are now deployed as per HPA minReplicas
kubectl get pods

# Check the current status of autoscaler
kubectl get hpa

# Run 10 instances of busybox to increase load on the app
kubectl apply -f load-generator-deploy.yaml

# Few seconds later..
# Check the current status of autoscaler, note the higher CPU
kubectl get hpa

# Get the deployed Pods
kubectl get Pods

# AKS cluster scaling
# Manually scale AKS cluster nodes
az aks scale `
  --resource-group $aksRg `
  --name $aksName `
  --node-count 3

# Check the number of Nodes
kubectl get nodes

# 2.2	Cluster node auto-scalability

# Edit replicas to 100
kubectl apply -f load-generator-deploy.yaml

# Edit maxReplicas to 1000
kubectl apply -f hpa.yaml

kubectl top nodes
kubectl get hpa
kubectl get pods

# Enable and configure AKS autoscaler
az aks nodepool update `
  --resource-group $aksRg `
  --cluster-name $aksName `
  --name agentpool `
  --enable-cluster-autoscaler `
  --min-count 3 `
  --max-count 10

# After few (5) minutes
kubectl get nodes
kubectl get hpa

# Update AKS cluster autoscaling
az aks update `
  --resource-group $aksRg `
  --name $aksName `
  --update-cluster-autoscaler `
  --min-count 1 `
  --max-count 10

# Disable AKS autoscaler
az aks nodepool update `
  --resource-group $aksRg `
  --cluster-name $aksName `
  --name agentpool `
  --disable-cluster-autoscaler

# Cleanup resources
kubectl delete -f deploy-svc.yaml
kubectl delete -f hpa.yaml