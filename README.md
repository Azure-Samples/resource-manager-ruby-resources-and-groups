---
services: azure-resource-manager
platforms: ruby
author: devigned
---

# Managing Azure Resource and Resource Groups with Ruby

This sample explains how to use Azure Resource Manager to manage your Resource and Resource Groups in Azure using the
Azure Ruby SDK.

## TODO: Introduction to Resource and Resource Groups

### To run this sample, do the following:

You will need to create an Azure service principal either through Azure CLI, PowerShell or the portal. You should gather
each the Tenant Id, Client Id and Client Secret from creating the Service Principal for use below.

- [Create a Service Principal](https://azure.microsoft.com/en-us/documentation/articles/resource-group-authenticate-service-principal/#authenticate-with-password---azure-cli)
- `git clone https://github.com/Azure-Samples/resource-manager-ruby-template-deployment.git`
- `cd resource-manager-ruby-template-deployment`
- `bundle install`
- `export AZURE_TENANT_ID={your tenant id}`
- `export AZURE_CLIENT_ID={your client id}`
- `export AZURE_CLIENT_SECRET={your client secret}`
- `export AZURE_SUBSCRIPTION_ID={your subscription id}`
- `bundle exec ruby example.rb`

### What is this example.rb doing?

The entry point for this sample is [example.rb](https://github.com/azure-samples/resource-manager-ruby-resources-and-groups/blob/master/example.rb).
*Note: you must set each of the below environment variables (AZURE_TENANT_ID, AZURE_CLIENT_ID and AZURE_CLIENT_SECRET
AZURE_SUBSCRIPTION_ID) prior to running the script.*
