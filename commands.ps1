az login
az account set -s '<subscription id or name>'

$RG = '<resource group name>'

az group create --resource-group $RG --location westeurope

az deployment group validate `
  --resource-group $RG `
  --template-file main.bicep

 az deployment group what-if `
  --resource-group $RG `
  --template-file main.bicep `
  --parameters aspName=asp-webinar-bicep `
               aspSku=B1 `
               webAppNamePrefix=webinar-bicep

az deployment group create `
  --resource-group $RG `
  --template-file main.bicep `
  --parameters parameters.json

az ts create `
  --resource-group rg-templatespecs `
  --name WebAppWithASP `
  --location westeurope `
  --display-name "Web App with ASP" `
  --description "This template spec an App Service Plan and Web App hosted on it." `
  --version 2022-04-23 `
  --template-file main.bicep
