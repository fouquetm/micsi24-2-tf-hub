output "agw_pip_fqdn" {
  value       = azurerm_public_ip.pip_agw.fqdn
  description = "Application Gateway Public IP FQDN"
}

output "tm_fqdn" {
  value       = azurerm_traffic_manager_profile.main.fqdn
  description = "Traffic Manager FQDN"
}

output "dns_zone_name_servers" {
  value       = azurerm_dns_zone.mfolabs.name_servers
  description = "Nameservers for the DNS Zone"
}