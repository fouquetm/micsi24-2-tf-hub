locals {
  resources_name_static_values         = "${var.environment}-${var.location_short_name}"
  resources_name_without_special_chars = lower(replace(local.resources_name_static_values, "-", ""))
  tags = {
    environment = var.environment
    location    = var.location_short_name
  }
}

resource "azurerm_role_assignment" "students_reader_rg" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Reader"
  principal_id         = var.students_security_group_object_id
}

#################
# Virtual Network
#################

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.resources_name_static_values}-01"
  address_space       = var.vnet_address_space
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_subnet" "vms_subnet" {
  name                 = "VMs"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.vms_subnet_address_prefixes
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_network_security_group" "nsg_vms" {
  name                = "nsg-vms"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "vms" {
  subnet_id                 = azurerm_subnet.vms_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg_vms.id
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = "AppGateway"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.appgw_subnet_address_prefixes
}

resource "azurerm_subnet" "gw_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.gw_subnet_address_prefixes
}

resource "azurerm_subnet" "fw_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.fw_subnet_address_prefixes
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.bastion_subnet_address_prefixes
}

#################
# Virtual Machine
#################

resource "azurerm_network_interface" "nic_vm1" {
  name                = "nic-${local.resources_name_static_values}-vm01"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vms_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "srv01" {
  name                              = "vm-${local.resources_name_static_values}-01"
  resource_group_name               = data.azurerm_resource_group.main.name
  location                          = data.azurerm_resource_group.main.location
  size                              = var.vm_size
  admin_username                    = var.vm_admin_username
  admin_password                    = var.vm_admin_password
  vm_agent_platform_updates_enabled = true
  tags                              = local.tags

  network_interface_ids = [
    azurerm_network_interface.nic_vm1.id,
  ]

  os_disk {
    name                 = "vm-${local.resources_name_static_values}-01_OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

# Install IIS web server to the virtual machine
resource "azurerm_virtual_machine_extension" "iis_install" {
  name                       = "iis-install"
  virtual_machine_id         = azurerm_windows_virtual_machine.srv01.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true
  tags                       = local.tags

  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
    }
  SETTINGS
}

# Change the default IIS start page title
resource "azurerm_virtual_machine_run_command" "iis_default_page_title" {
  name               = "iis-default-page-title"
  location           = data.azurerm_resource_group.main.location
  virtual_machine_id = azurerm_windows_virtual_machine.srv01.id
  tags               = local.tags

  source {
    script = "powershell -ExecutionPolicy Unrestricted -Command (Get-Content 'C:\\inetpub\\wwwroot\\iisstart.htm') | % {$_ -replace 'IIS Windows Server','MFOLABS'} | Set-Content 'C:\\inetpub\\wwwroot\\iisstart.htm'"
  }

  depends_on = [azurerm_virtual_machine_extension.iis_install]
}

#################
# Azure Firewall
#################

# resource "azurerm_public_ip" "pip_fw" {
#   name                = "pip-fw-${local.resources_name_static_values}-01"
#   resource_group_name = data.azurerm_resource_group.main.name
#   location            = data.azurerm_resource_group.main.location
#   allocation_method   = "Static"
#   tags                = local.tags
# }

# resource "azurerm_firewall" "main" {
#   name                = "fw-${local.resources_name_static_values}-01"
#   location            = data.azurerm_resource_group.main.location
#   resource_group_name = data.azurerm_resource_group.main.name
#   sku_name            = "AZFW_VNet"
#   sku_tier            = "Standard"
#   tags                = local.tags

#   ip_configuration {
#     name                 = "configuration"
#     subnet_id            = azurerm_subnet.fw_subnet.id
#     public_ip_address_id = azurerm_public_ip.pip_fw.id
#   }
# }

# resource "azurerm_role_assignment" "students_contributor_fw" {
#   scope                = azurerm_firewall.main.id
#   role_definition_name = "Contributor"
#   principal_id         = var.students_security_group_object_id
# }

#################
# Bastion
#################

resource "azurerm_public_ip" "pip_bastion" {
  name                = "pip-bas-${local.resources_name_static_values}-01"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  tags                = local.tags
}

resource "azurerm_bastion_host" "main" {
  name                = "bas-hub-${local.resources_name_static_values}-01"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.pip_bastion.id
  }
}

resource "azurerm_role_assignment" "students_reader_bastion" {
  scope                = azurerm_bastion_host.main.id
  role_definition_name = "Reader"
  principal_id         = var.students_security_group_object_id
}

#################
# Application Gateway
#################

resource "azurerm_public_ip" "pip_agw" {
  name                = "pip-agw-${local.resources_name_static_values}-01"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  tags                = local.tags
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_subnet.vms_subnet.name}-beap"
  frontend_port_name             = "${azurerm_subnet.vms_subnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_subnet.vms_subnet.name}-feip"
  http_setting_name              = "${azurerm_subnet.vms_subnet.name}-be-htst"
  listener_name                  = "${azurerm_subnet.vms_subnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_subnet.vms_subnet.name}-rqrt"
  redirect_configuration_name    = "${azurerm_subnet.vms_subnet.name}-rdrcfg"
}

resource "azurerm_application_gateway" "network" {
  name                = "agw-${local.resources_name_static_values}-01"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  tags                = local.tags

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "configuration"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip_agw.id
  }

  backend_address_pool {
    name         = local.backend_address_pool_name
    ip_addresses = [azurerm_network_interface.nic_vm1.private_ip_address]
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  depends_on = [azurerm_virtual_machine_extension.iis_install]
}

#################
# Peering
#################
resource "azurerm_role_assignment" "students_network_contributor_vnet" {
  scope                = azurerm_virtual_network.main.id
  role_definition_name = "Network Contributor"
  principal_id         = var.students_security_group_object_id
}

data "azurerm_virtual_network" "vnet_students" {
  for_each            = var.virtual_networks
  name                = each.value.vnet_name
  resource_group_name = each.value.resource_group_name
}

resource "azurerm_virtual_network_peering" "hub_to_spokes" {
  for_each                     = data.azurerm_virtual_network.vnet_students
  name                         = "hub-to-${each.value.name}"
  resource_group_name          = data.azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.main.name
  remote_virtual_network_id    = each.value.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

#################
# Traffic Manager
#################
resource "azurerm_traffic_manager_profile" "main" {
  name                   = "tm-${local.resources_name_static_values}-01"
  resource_group_name    = data.azurerm_resource_group.main.name
  traffic_routing_method = "Performance"
  traffic_view_enabled   = true
  tags                   = local.tags

  dns_config {
    relative_name = "tm-${local.resources_name_static_values}-01"
    ttl           = 30
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }
}

resource "azurerm_role_assignment" "students_network_contributor_tm" {
  scope                = azurerm_traffic_manager_profile.main.id
  role_definition_name = "Network Contributor"
  principal_id         = var.students_security_group_object_id
}

resource "azurerm_traffic_manager_external_endpoint" "mfolabs" {
  name              = "hub-agw"
  profile_id        = azurerm_traffic_manager_profile.main.id
  target            = trimsuffix(azurerm_dns_a_record.hub.fqdn, ".")
  priority          = 1
  endpoint_location = data.azurerm_resource_group.main.location
}

#################
# Azure Private DNS Zone
#################

resource "azurerm_private_dns_zone" "main" {
  name                = var.private_network_dns_zone_name
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_role_assignment" "students_network_contributor_private_dns_zone" {
  scope                = azurerm_private_dns_zone.main.id
  role_definition_name = "Network Contributor"
  principal_id         = var.students_security_group_object_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  name                  = "hub-vnet-link"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = true
  tags                  = local.tags
}

#################
# Azure DNS Zone
#################

resource "azurerm_dns_zone" "mfolabs" {
  name                = "students.mfolabs.me"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_role_assignment" "students_network_contributor_dns_zone" {
  scope                = azurerm_dns_zone.mfolabs.id
  role_definition_name = "Network Contributor"
  principal_id         = var.students_security_group_object_id
}

resource "azurerm_dns_cname_record" "dns_cname_tm" {
  name                = "global"
  zone_name           = azurerm_dns_zone.mfolabs.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 300
  record              = azurerm_traffic_manager_profile.main.fqdn
}

resource "azurerm_dns_a_record" "hub" {
  name                = "hub"
  zone_name           = azurerm_dns_zone.mfolabs.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 300
  records             = [azurerm_public_ip.pip_agw.ip_address]
}

#################
# Storage Account
#################
resource "random_string" "storage_name_suffix" {
  length  = 4
  special = false
  upper   = false
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

resource "azurerm_storage_account" "main" {
  name                          = "st${local.resources_name_without_special_chars}${random_string.storage_name_suffix.result}01"
  resource_group_name           = data.azurerm_resource_group.main.name
  location                      = data.azurerm_resource_group.main.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  public_network_access_enabled = false
  network_rules {
    ip_rules       = [chomp(data.http.myip.response_body)]
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
  tags = local.tags
}

resource "azurerm_storage_container" "web" {
  name                  = "web"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "container"
}

resource "azurerm_storage_blob" "blobfish" {
  name                   = "blobfish.jpg"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = azurerm_storage_container.web.name
  type                   = "Block"
  content_type           = "image/jpeg"
  source                 = "web/blobfish.jpg"
}

#################
# Private Endpoints
#################

resource "azurerm_private_endpoint" "sa_blob" {
  name                = "pe-${azurerm_storage_account.main.name}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.vms_subnet.id

  private_service_connection {
    name                           = "pe-${azurerm_storage_account.main.name}"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.sa_blob_pe.id]
  }
}

resource "azurerm_private_dns_zone" "sa_blob_pe" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "${azurerm_virtual_network.main.name}-link"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sa_blob_pe.name
  virtual_network_id    = azurerm_virtual_network.main.id
}
