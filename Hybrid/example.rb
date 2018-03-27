#!/usr/bin/env ruby

require 'azure_mgmt_resources'

LOCAL = 'local'
GROUP_NAME = 'azure-sample-group'

# Manage resources and resource groups - create, update and delete a resource group, deploy a solution into a resource
#   group, export an ARM template. Create, read, update and delete a resource
#
# This script expects that the following environment vars are set:
#
# AZURE_TENANT_ID: with your Azure Active Directory tenant id or domain
# AZURE_CLIENT_ID: with your Azure Active Directory Application Client ID
# AZURE_CLIENT_SECRET: with your Azure Active Directory Application Secret
# AZURE_SUBSCRIPTION_ID: with your Azure Subscription Id
#
def run_example
  #
  # Create the Resource Manager Client with an Application (service principal) token provider
  #
  subscription_id = ENV['AZURE_SUBSCRIPTION_ID'] || '11111111-1111-1111-1111-111111111111'
  active_directory_settings = get_active_directory_settings(ENV['ARM_ENDPOINT'])
   # your Azure Subscription Id
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

  #
  # Managing resource groups
  #
  resource_group_params = client.model_classes.resource_group.new.tap do |rg|
    rg.location = LOCAL
  end

  # List Resource Groups
  puts 'List Resource Groups'
  client.resource_groups.list.each{ |group| print_item(group) }

  # Create Resource group
  puts 'Create Resource Group'
  print_item client.resource_groups.create_or_update(GROUP_NAME, resource_group_params)

  # Modify the Resource group
  puts 'Modify Resource Group'
  resource_group_params.tags = { hello: 'world' }
  print_item client.resource_groups.create_or_update(GROUP_NAME, resource_group_params)

  # Create a Key Vault in the Resource Group
  puts 'Create a Key Vault via a Generic Resource Put'
  key_vault_params = client.model_classes.generic_resource.new.tap do |rg|
    rg.location = LOCAL
    rg.properties = {
        sku: { family: 'A', name: 'standard' },
        tenantId: ENV['AZURE_TENANT_ID'],
        accessPolicies: [],
        enabledForDeployment: true,
        enabledForTemplateDeployment: true,
        enabledForDiskEncryption: true
    }
  end
  postfix = rand(1000)
  vault_name = "azureSampleVault#{postfix}"
  puts JSON.pretty_generate(client.resources.create_or_update(GROUP_NAME,
                                         'Microsoft.KeyVault',
                                         '',
                                         'vaults',
                                         vault_name,
                                         '2015-06-01',
                                         key_vault_params).properties)  + "\n\n"

  # List Resources within the group
  puts 'List all of the resources within the group'
  client.resource_groups.list.each{ |resource| print_item(resource) }

  # Export the Resource group template
  puts 'Export Resource Group Template'
  export_params = client.model_classes.export_template_request.new.tap do |rg|
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
  puts "\tProperties:"
  props.instance_variables.sort.each do |ivar|
    str = ivar.to_s.gsub /^@/, ''
    if props.respond_to? str.to_sym
      puts "\t\t#{str}: #{props.send(str.to_sym)}"
    end
  end
  puts "\n\n"
end

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



if $0 == __FILE__
  run_example
end


