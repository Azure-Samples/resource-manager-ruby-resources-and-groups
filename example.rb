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
  client.resource_groups.list.value!.body.value.each do |group|
    print_group(group)
  end

  # Create Resource group
  puts 'Create Resource Group'
  print_group client.resource_groups.create_or_update(GROUP_NAME, resource_group_params).value!.body

  # Modify the Resource group
  puts 'Modify Resource Group'
  resource_group_params.tags = { hello: 'world' }
  print_group client.resource_groups.create_or_update(GROUP_NAME, resource_group_params).value!.body

  # Delete Resource group
  puts 'Delete Resource Group'
  client.resource_groups.delete(GROUP_NAME).value!
  puts "\nDeleted: #{GROUP_NAME}"

end

def print_group(group)
  puts "\tName: #{group.name}"
  puts "\tId: #{group.id}"
  puts "\tName: #{group.name}"
  puts "\tLocation: #{group.location}"
  puts "\tTags: #{group.tags}"
  print_properties(group.properties)
end

def print_properties(props)
  puts "\tProperties:"
  puts "\t\tProvisioning State: #{props.provisioning_state}\n\n"
end

if $0 == __FILE__
  run_example
end


