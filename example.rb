#!/usr/bin/env ruby

require 'azure_mgmt_resources'
require 'dotenv'

Dotenv.load!(File.join(__dir__, './.env'))

WEST_US = 'westus'
GROUP_NAME = 'azure-sample-group'

# This script expects that the following environment vars are set:
#
# Manage resources and resource groups - create, update and delete a resource group, deploy a solution into a resource
#   group, export an ARM template. Create, read, update and delete a resource
#
# AZURE_TENANT_ID: with your Azure Active Directory tenant id or domain
# AZURE_CLIENT_ID: with your Azure Active Directory Application Client ID
# AZURE_CLIENT_SECRET: with your Azure Active Directory Application Secret
# AZURE_SUBSCRIPTION_ID: with your Azure Subscription Id
def run_example
  #
  # Create the Resource Manager Client with an Application (service principal) token provider
  #
  subscription_id = ENV['AZURE_SUBSCRIPTION_ID'] || '11111111-1111-1111-1111-111111111111' # your Azure Subscription Id
  provider = MsRestAzure::ApplicationTokenProvider.new(
      ENV['AZURE_TENANT_ID'],
      ENV['AZURE_CLIENT_ID'],
      ENV['AZURE_CLIENT_SECRET'])
  credentials = MsRest::TokenCredentials.new(provider)
  client = Azure::ARM::Resources::ResourceManagementClient.new(credentials)
  client.subscription_id = subscription_id

  #
  # Managing resource groups
  #
  resource_group_params = Azure::ARM::Resources::Models::ResourceGroup.new.tap do |rg|
    rg.location = WEST_US
  end

  # List Resource Groups
  puts 'List Resource Groups'
  client.resource_groups.list.value.each{ |group| print_item(group) }

  # Create Resource group
  puts 'Create Resource Group'
  print_item client.resource_groups.create_or_update(GROUP_NAME, resource_group_params)

  # Modify the Resource group
  puts 'Modify Resource Group'
  resource_group_params.tags = { hello: 'world' }
  print_item client.resource_groups.create_or_update(GROUP_NAME, resource_group_params)

  # Create a Key Vault in the Resource Group
  puts 'Create a Key Vault via a Generic Resource Put'
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
  puts JSON.pretty_generate(client.resources.create_or_update(GROUP_NAME,
                                         'Microsoft.KeyVault',
                                         '',
                                         'vaults',
                                         'azureSampleVault',
                                         '2015-06-01',
                                         key_vault_params).properties)  + "\n\n"

  # List Resources within the group
  puts 'List all of the resources within the group'
  client.resource_groups.list_resources(GROUP_NAME).value.each{ |resource| print_item(resource) }

  # Export the Resource group template
  puts 'Export Resource Group Template'
  export_params = Azure::ARM::Resources::Models::ExportTemplateRequest.new.tap do |rg|
    rg.resources = ['*']
  end
  puts JSON.pretty_generate(client.resource_groups.export_template(GROUP_NAME, export_params).template) + "\n\n"

  # Delete Resource group and everything in it
  puts 'Delete Resource Group'
  client.resource_groups.delete(GROUP_NAME)
  puts "\nDeleted: #{GROUP_NAME}"

end

def print_item(group)
  puts "\tName: #{group.name}"
  puts "\tId: #{group.id}"
  puts "\tLocation: #{group.location}"
  puts "\tTags: #{group.tags}"
  print_properties(group.properties)
end

def print_properties(props)
  if props.respond_to? :provisioning_state
    puts "\tProperties:"
    puts "\t\tProvisioning State: #{props.provisioning_state}"
  end
  puts "\n\n"
end

if $0 == __FILE__
  run_example
end


