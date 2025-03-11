resource_group_name               = "rg-mfolabs-micsi24"
environment                       = "form"
location_short_name               = "fc"
students_security_group_object_id = "0bb3fe55-ebb0-4fc7-9c16-92e64bb60372"
vnet_address_space                = ["10.0.0.0/16"]
vms_subnet_address_prefixes       = ["10.0.0.0/24"]
appgw_subnet_address_prefixes     = ["10.0.3.0/24"]
gw_subnet_address_prefixes        = ["10.0.2.0/24"]
fw_subnet_address_prefixes        = ["10.0.1.0/24"]
bastion_subnet_address_prefixes   = ["10.0.4.64/26"]
vm_admin_username                 = "matthieu"
vm_admin_password                 = "P@ssw0rd2025!"
vm_size                           = "Standard_B2s_v2"

#################
# Students VNet for Peering
#################

virtual_networks = {
  student1 = {
    vnet_name           = "vnetstudent101"
    resource_group_name = "rg-micsi242-student1"
  }
  #   student2 = {
  #     vnet_name           = "vnet-fc-02"
  #     resource_group_name = "rg-micsi242-student2"
  #   }
  #   student3 = {
  #     vnet_name           = "vnet-fc-03"
  #     resource_group_name = "rg-micsi242-student3"
  #   }
  #   student4 = {
  #     vnet_name           = "vnet-fc-04"
  #     resource_group_name = "rg-micsi242-student4"
  #   }
  #   student5 = {
  #     vnet_name           = "vnet-fc-05"
  #     resource_group_name = "rg-micsi242-student5"
  #   }
  student6 = {
    vnet_name           = "vnetstudent601"
    resource_group_name = "rg-micsi242-student6"
  }
  student7 = {
    vnet_name           = "vnetmda01"
    resource_group_name = "rg-micsi242-student7"
  }
  #   student8 = {
  #     vnet_name           = "vnet-fc-08"
  #     resource_group_name = "rg-micsi242-student8"
  #   }
  #   student9 = {
  #     vnet_name           = "vnet-fc-09"
  #     resource_group_name = "rg-micsi242-student9"
  #   }
  #   student10 = {
  #     vnet_name           = "vnet-fc-10"
  #     resource_group_name = "rg-micsi242-student10"
  #   }
  student11 = {
    vnet_name           = "vnetstudent1101"
    resource_group_name = "rg-micsi242-student11"
  }
}
