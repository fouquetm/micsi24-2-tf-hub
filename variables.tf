variable "resource_group_name" {
  type        = string
  description = "Nom du groupe de ressources"
}

variable "environment" {
  type        = string
  description = "Nom de l'environnement."
}

variable "location_short_name" {
  type        = string
  description = "Nom court de la région Azure."
}

variable "students_security_group_object_id" {
  type        = string
  description = "ObjectId du groupe de sécurité Entra ID des étudiants."
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Adresse IP du réseau virtuel."
}

variable "vms_subnet_address_prefixes" {
  type        = list(string)
  description = "Adresse IP du sous-réseau des machines virtuelles."
}

variable "appgw_subnet_address_prefixes" {
  type        = list(string)
  description = "Adresse IP du sous-réseau de l'App Gateway."
}

variable "gw_subnet_address_prefixes" {
  type        = list(string)
  description = "Adresse IP du sous-réseau de la passerelle."
}

variable "fw_subnet_address_prefixes" {
  type        = list(string)
  description = "Adresse IP du sous-réseau du pare-feu."
}

variable "bastion_subnet_address_prefixes" {
  type        = list(string)
  description = "Adresse IP du sous-réseau du bastion."
}

variable "vm_admin_username" {
  type        = string
  description = "Nom d'utilisateur de l'administrateur des machines virtuelles."
  sensitive   = true
}

variable "vm_admin_password" {
  type        = string
  description = "Mot de passe de l'administrateur des machines virtuelles."
  sensitive   = true
}

variable "vm_size" {
  type        = string
  description = "Taille de la machine virtuelle."
}

variable "virtual_networks" {
  type = map(object({
    vnet_name           = string
    resource_group_name = string
  }))
  description = "Liste des réseaux virtuels."
}

variable "private_network_dns_zone_name" {
  type        = string
  description = "Nom de la zone DNS privée."
}