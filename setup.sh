#!/bin/bash
set -e

# Variables
RESOURCE_GROUP="azure-devsecops-rg"
LOCATION="westeurope"
AKS_NAME="devsecops-aks"
ACR_NAME="devsecopsacr$RANDOM"
STORAGE_ACCOUNT="tfstate$RANDOM"
CONTAINER_NAME="tfstate"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Azure DevSecOps Project Setup ===${NC}"

# Check Azure CLI installation
if ! command -v az &> /dev/null
then
    echo -e "${RED}Azure CLI not found. Please install it first.${NC}"
    exit 1
fi

# Check Terraform installation
if ! command -v terraform &> /dev/null
then
    echo -e "${RED}Terraform not found. Please install it first.${NC}"
    exit 1
fi

# Check kubectl installation
if ! command -v kubectl &> /dev/null
then
    echo -e "${RED}kubectl not found. Please install it first.${NC}"
    exit 1
fi

# Login to Azure
echo -e "${BLUE}Logging in to Azure...${NC}"
az login

# Create Resource Group for Terraform State
echo -e "${BLUE}Creating Resource Group for Terraform state...${NC}"
az group create --name terraform-state-rg --location $LOCATION

# Create Storage Account for Terraform State
echo -e "${BLUE}Creating Storage Account for Terraform state...${NC}"
az storage account create --resource-group terraform-state-rg --name $STORAGE_ACCOUNT --sku Standard_LRS --encryption-services blob

# Get Storage Account Key
echo -e "${BLUE}Getting Storage Account Key...${NC}"
ACCOUNT_KEY=$(az storage account keys list --resource-group terraform-state-rg --account-name $STORAGE_ACCOUNT --query '[0].value' -o tsv)

# Create Blob Container
echo -e "${BLUE}Creating Blob Container for Terraform state...${NC}"
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT --account-key $ACCOUNT_KEY

echo -e "${GREEN}Terraform backend storage created successfully!${NC}"
echo -e "${BLUE}Storage Account: ${GREEN}$STORAGE_ACCOUNT${NC}"
echo -e "${BLUE}Container: ${GREEN}$CONTAINER_NAME${NC}"

# Update providers.tf with the correct values
echo -e "${BLUE}Updating providers.tf with the correct values...${NC}"
sed -i "s/terraformstate20250519/$STORAGE_ACCOUNT/g" terraform/providers.tf

# Create a Service Principal for GitHub Actions
echo -e "${BLUE}Creating a Service Principal for GitHub Actions...${NC}"
SP=$(az ad sp create-for-rbac --name "azure-devsecops-github" --role contributor --scopes /subscriptions/$(az account show --query id -o tsv) --sdk-auth)

echo -e "${GREEN}Service Principal created successfully!${NC}"
echo -e "${BLUE}Please add the following as a secret named AZURE_CREDENTIALS in your GitHub repository:${NC}"
echo $SP

echo -e "${BLUE}Creating GitHub Action secrets...${NC}"
echo "ACR_NAME: $ACR_NAME"
echo "CLUSTER_NAME: $AKS_NAME"
echo "RESOURCE_GROUP: $RESOURCE_GROUP"
echo "AZURE_CLIENT_ID: $(echo $SP | jq -r .clientId)"
echo "AZURE_CLIENT_SECRET: $(echo $SP | jq -r .clientSecret)"
echo "AZURE_TENANT_ID: $(echo $SP | jq -r .tenantId)"
echo "AZURE_SUBSCRIPTION_ID: $(echo $SP | jq -r .subscriptionId)"

echo -e "${BLUE}Initializing Terraform...${NC}"
cd terraform
terraform init

echo -e "${GREEN}Project setup completed successfully!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Add the GitHub secrets mentioned above to your repository"
echo -e "2. Run 'terraform plan' and 'terraform apply' to create the infrastructure"
echo -e "3. Push your code to the GitHub repository to trigger the CI/CD pipeline"
echo -e "4. Access your application through the frontend service external IP address"
echo -e "5. Access Grafana dashboards through the grafana service external IP address"

# Provide a helper script to get cluster credentials after infrastructure is created
cat << 'HELPERSCRIPT' > get-credentials.sh
#!/bin/bash
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
AKS_NAME=$(terraform output -raw cluster_name)

# Get AKS credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing

# Show services
echo "Kubernetes services:"
kubectl get services --all-namespaces

# Show pods
echo "Kubernetes pods:"
kubectl get pods --all-namespaces

# Get the frontend service IP
FRONTEND_IP=$(kubectl get service frontend -n app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Your application should be accessible at: http://$FRONTEND_IP"

# Get the Grafana service IP
GRAFANA_IP=$(kubectl get service grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Grafana dashboards should be accessible at: http://$GRAFANA_IP:3000"
echo "Default credentials: admin / StrongP@ssword123!"
HELPERSCRIPT

chmod +x get-credentials.sh
echo -e "${BLUE}Created get-credentials.sh script to help access your cluster after infrastructure deployment${NC}"
