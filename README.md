---
services: azure-resource-manager
platforms: ruby
author: allclark
---

# Managing Azure Resource and Resource Groups with Ruby

This sample explains how to use Azure Resource Manager to manage your Resource and Resource Groups in Azure using the
Azure Ruby SDK.

*TODO: Introduction to Resource and Resource Groups*

## Run this sample

You will need to create an Azure service principal either through Azure CLI, PowerShell or the portal. You should gather
each the Tenant Id, Client Id and Client Secret from
[creating the Service Principal](https://azure.microsoft.com/en-us/documentation/articles/resource-group-authenticate-service-principal/#authenticate-with-password---azure-cli)
for use below.

```
git clone https://github.com/Azure-Samples/resource-manager-ruby-template-deployment.git
cd resource-manager-ruby-template-deployment
bundle install
export AZURE_TENANT_ID={your tenant id}
export AZURE_CLIENT_ID={your client id}
export AZURE_CLIENT_SECRET={your client secret}
bundle exec ruby example.rb
```

## What is this example.rb doing?

The sample walks you through several resource and resource group management operations.
It starts by setting up a ResourceManagementClient object using your subscription and credentials.

```ruby
subscription_id = ENV['AZURE_SUBSCRIPTION_ID'] ||
    '11111111-1111-1111-1111-111111111111' # your Azure Subscription Id
provider = MsRestAzure::ApplicationTokenProvider.new(
    ENV['AZURE_TENANT_ID'],
    ENV['AZURE_CLIENT_ID'],
    ENV['AZURE_CLIENT_SECRET'])
credentials = MsRest::TokenCredentials.new(provider)
client = Azure::ARM::Resources::ResourceManagementClient.new(credentials)
client.subscription_id = subscription_id
```

It also sets up a ResourceGroup object (resource_group_params) to be used as a parameter in some of the API calls.
*Why the ResourceGroup location set to WEST_US in this sample?*

```ruby
resource_group_params = Azure::ARM::Resources::Models::ResourceGroup.new.tap do |rg|
    rg.location = `westus`
end
```

There are a couple of supporting functions (`print_group` and `print_properties`) that print a resource group and it's properties.
With that set up, the sample lists all resource groups for your subscription, it performs these operations.

## List resource groups

List the resource groups in your subscription.

```ruby
  client.resource_groups.list.value!.body.value.each do |group|
    print_group(group)
  end
```

## Create a resource group

```ruby
client.resource_groups.create_or_update('azure-sample-group', resource_group_params)
```

## Update a resource group

The sample adds a tag to the resource group.

```ruby
resource_group_params.tags = { hello: 'world' }
client.resource_groups.create_or_update('azure-sample-group', resource_group_params)
```

## Delete a resource group

```ruby
client.resource_groups.delete('azure-sample-group')
```
