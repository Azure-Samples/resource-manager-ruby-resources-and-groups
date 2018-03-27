---
services: azure-resource-manager
platforms: ruby
author: viananth
---

# Manage Azure resources and resource groups with Ruby

This sample explains how to manage your
[resources and resource groups in Azure](https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-key-features#resource-groups)
using the Azure Ruby SDK.

**On this page**

- [Run this sample](#run)
- [What is example.rb doing?](#example)
    - [List resource groups](#list-groups)
    - [Create a resource group](#create-group)
    - [Update a resource group](#update-group)
    - [Create a key vault in the resource group](#create-resource)
    - [List resources within the group](#list-resources)
    - [Export the resource group template](#export)
    - [Delete a resource group](#delete-group)

<a id="run"></a>
## Run this sample

1. If you don't already have it, [install Ruby and the Ruby DevKit](https://www.ruby-lang.org/en/documentation/installation/).

1. If you don't have bundler, install it.

    ```
    gem install bundler
    ```

1. Clone the repository.

    ```
    git clone https://github.com/Azure-Samples/resource-manager-ruby-resources-and-groups.git
    ```

1. Install the dependencies using bundle.

    ```
    cd resource-manager-ruby-resources-and-groups\Hybrid\
    bundle install
    ```

1. 	If not available, 
    [create a subscription](https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-subscribe-plan-provision-vm) 
    and save the subscription ID to be used later.  

1. Create a [service principal](https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-create-service-principals) to work against AzureStack. Make sure your service principal has [contributor/owner role](https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-create-service-principals#assign-role-to-service-principal) on your subscription.
    

1. Set the following environment variables using the information from the service principal that you created.

    ```
    export AZURE_TENANT_ID={your tenant id}
    export AZURE_CLIENT_ID={your client id}
    export AZURE_CLIENT_SECRET={your client secret}
    export AZURE_SUBSCRIPTION_ID={your subscription id}
    export ARM_ENDPOINT={your AzureStack Resource manager url}
    ```

    > [AZURE.NOTE] On Windows, use `set` instead of `export`.

1. To target Azure Stack environment, API-Version Profile V2017:03:09 should be used to create the resource client.

    Example:
    ```ruby
    client = Azure::Resources::Profiles::V2017_03_09::Mgmt::Client.new(options)
    ```

1. To authenticate the Service Principal against Azure Stack environment, the endpoints should be defined using ```get_active_directory_settings()```. This method uses the ARM_Endpoint environment variable that was set using step 7.


    ```ruby
    # Get Authentication endpoints using Arm Metadata Endpoints
    def get_active_directory_settings(armEndpoint)
        settings = MsRestAzure::ActiveDirectoryServiceSettings.new
        response = Net::HTTP.get_response(URI("#{armEndpoint}/metadata/endpoints?api-version=1.0"))
        status_code = response.code
        response_content = response.body
        unless status_code == "200"
            error_model = JSON.load(response_content)
            fail MsRestAzure::AzureOperationError.new("Getting Azure Stack Metadata Endpoints", response, error_model)
        end

        result = JSON.load(response_content)
        settings.authentication_endpoint = result['authentication']['loginEndpoint'] unless result['authentication']['loginEndpoint'].nil?
        settings.token_audience = result['authentication']['audiences'][0] unless result['authentication']['audiences'][0].nil?
        settings
    end
    ```

1. Run the sample.

    ```
    bundle exec ruby example.rb
    ```

<a id="example"></a>
## What is example.rb doing?

The sample walks you through several resource and resource group management operations.
It starts by setting up a ResourceManagementClient object using your subscription and credentials.

```ruby
subscription_id = ENV['AZURE_SUBSCRIPTION_ID'] || '11111111-1111-1111-1111-111111111111'

active_directory_settings = get_active_directory_settings(ENV['ARM_ENDPOINT'])

provider = MsRestAzure::ApplicationTokenProvider.new(
	ENV['AZURE_TENANT_ID'],
	ENV['AZURE_CLIENT_ID'],
	ENV['AZURE_CLIENT_SECRET'],
	active_directory_settings
)

credentials = MsRest::TokenCredentials.new(provider)
options = {
	credentials: credentials,
	subscription_id: subscription_id,
	active_directory_settings: active_directory_settings,
	base_url: ENV['ARM_ENDPOINT']
}

client = Azure::Resources::Profiles::V2017_03_09::Mgmt::Client.new(options)

```

It also sets up a ResourceGroup object (resource_group_params) to be used as a parameter in some of the API calls.

```ruby
resource_group_params = Azure::ARM::Resources::Models::ResourceGroup.new.tap do |rg|
    rg.location = `local`
end
```

There are a couple of supporting functions (`print_item` and `print_properties`) that print a resource group and it's properties.
With that set up, the sample lists all resource groups for your subscription, it performs these operations.

<a id="list-groups"></a>
### List resource groups

List the resource groups in your subscription.

```ruby
 client.resource_groups.list.value.each{ |group| print_item(group) }
```

<a id="create-group"></a>
### Create a resource group

```ruby
client.resource_groups.create_or_update('azure-sample-group', resource_group_params)
```

<a id="update-group"></a>
### Update a resource group

The sample adds a tag to the resource group.

```ruby
resource_group_params.tags = { hello: 'world' }
client.resource_groups.create_or_update('azure-sample-group', resource_group_params)
```

<a id="create-resource"></a>
### Create a key vault in the resource group

```ruby
key_vault_params = Azure::ARM::Resources::Models::GenericResource.new.tap do |rg|
    rg.location = WEST_US
    rg.properties = {
        sku: { family: 'A', name: 'standard' },
        tenantId: ENV['AZURE_TENANT_ID'],
        accessPolicies: [],
        enabledForDeployment: true,
        enabledForTemplateDeployment: true,
        enabledForDiskEncryption: true
    }
  end
  client.resources.create_or_update(GROUP_NAME,
                                    'Microsoft.KeyVault',
                                    '',
                                    'vaults',
                                    'azureSampleVault',
                                    '2015-06-01',
                                    key_vault_params)
```

<a id="list-resources"></a>
### List resources within the group

```ruby
client.resource_groups.list_resources(GROUP_NAME).value.each{ |resource| print_item(resource) }
```

<a id="export"></a>
### Export the resource group template

You can export the resource group as a template and then use that
to [deploy your resources to Azure](https://azure.microsoft.com/documentation/samples/resource-manager-ruby-template-deployment/).

```ruby
export_params = Azure::ARM::Resources::Models::ExportTemplateRequest.new.tap do |rg|
    rg.resources = ['*']
end
client.resource_groups.export_template(GROUP_NAME, export_params)
```

<a id="delete-group"></a>
### Delete a resource group

```ruby
client.resource_groups.delete('azure-sample-group')
```
