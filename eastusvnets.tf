resource "azurerm_resource_group" "rg-customer-vnets-eus2" {
  name     = "rg-customer-vnets-eus2"
  location = "eastus2"
}

## Red Vnets

resource "azurerm_virtual_network" "spoke1_vnet" {
    resource_group_name = azurerm_resource_group.rg-customer-vnets-eus2.name
    location            = azurerm_resource_group.rg-customer-vnets-eus2.location
    name                = "vnet-spoke1-eus2"
    address_space       = ["10.83.0.0/24"]
}

resource "azurerm_subnet" "spoke1_vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.rg-customer-vnets-eus2.name
  virtual_network_name = azurerm_virtual_network.spoke1_vnet.name
  address_prefixes     = ["10.83.0.0/26"]
}

resource "azurerm_virtual_network" "redspoke2_vnet" {
    resource_group_name = azurerm_resource_group.rg-customer-vnets-eus2.name
    location            = azurerm_resource_group.rg-customer-vnets-eus2.location
    name                = "vnet-red2-eus2"
    address_space       = ["10.83.1.0/24"]
}

resource "azurerm_subnet" "redspoke2_vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.rg-customer-vnets-eus2.name
  virtual_network_name = azurerm_virtual_network.redspoke2_vnet.name
  address_prefixes     = ["10.83.1.0/26"]
}

## Red Vnet VM

resource "azurerm_network_interface" "spoke1_nic" {
  name                = "nic-spoke1-vm"
  location           = azurerm_resource_group.rg-customer-vnets-eus2.location
  resource_group_name = azurerm_resource_group.rg-customer-vnets-eus2.name

  ip_configuration {
    name                          = "ipconfig-spoke1-vm"
    subnet_id                     = azurerm_subnet.spoke1_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  
}

resource "azurerm_virtual_machine" "spoke1" {
  name                  = "redspoke1-vm"
  resource_group_name   = azurerm_resource_group.rg-customer-vnets-eus2.name
  location              = azurerm_resource_group.rg-customer-vnets-eus2.location
  network_interface_ids = [azurerm_network_interface.spoke1_nic.id]
  vm_size               = "Standard_B1ms"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "red-spoke1-vm-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "red-spoke1-vm"
    admin_username = "mrojas"
    admin_password = "FreyiaRojas123!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }  
}

resource "azurerm_network_interface" "red2spoke_nic" {
  name                = "nic-red2spoke-vm"
  location           = azurerm_resource_group.rg-customer-vnets-eus2.location
  resource_group_name = azurerm_resource_group.rg-customer-vnets-eus2.name

  ip_configuration {
    name                          = "ipconfig-red2spoke-vm"
    subnet_id                     = azurerm_subnet.redspoke2_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  
}

resource "azurerm_virtual_machine" "red2spoke" {
  name                  = "red2spoke-vm"
  resource_group_name   = azurerm_resource_group.rg-customer-vnets-eus2.name
  location              = azurerm_resource_group.rg-customer-vnets-eus2.location
  network_interface_ids = [azurerm_network_interface.red2spoke_nic.id]
  vm_size               = "Standard_B1ms"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "red2spoke"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "red2spoke-vm"
    admin_username = "mrojas"
    admin_password = "FreyiaRojas123!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }  
}



#FW Vnet
resource "azurerm_virtual_network" "spoke2_fw-vnet" {
  resource_group_name = azurerm_resource_group.rg-customer-vnets-eus2.name
  location            = azurerm_resource_group.rg-customer-vnets-eus2.location
  name                = "vnet-spoke2fw-eus2"
  address_space       = ["10.80.0.0/24"]
}

resource "azurerm_subnet" "spoke2fw_vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.rg-customer-vnets-eus2.name
  virtual_network_name = azurerm_virtual_network.spoke2_fw-vnet.name
  address_prefixes     = ["10.80.0.0/26"]
}

resource "azurerm_subnet" "fw_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg-customer-vnets-eus2.name
  virtual_network_name = azurerm_virtual_network.spoke2_fw-vnet.name
  address_prefixes     = ["10.80.0.128/26"]
}

module "fw_public_ip" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = ">=0.1.0"
  # insert the 3 required variables here
  name                = "pip-fw"
  location            = azurerm_resource_group.rg-customer-vnets-eus2.location
  resource_group_name = azurerm_resource_group.rg-customer-vnets-eus2.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    deployment = "terraform"
  }
  zones = ["1", "2", "3"]
}

module "azfw" {
  source              = "Azure/avm-res-network-azurefirewall/azurerm"
  version             = ">=0.1.0"
  location            = azurerm_resource_group.rg-customer-vnets-eus2.location
  resource_group_name = azurerm_resource_group.rg-customer-vnets-eus2.name
  name                = "azfw-eus2"
  firewall_sku_name   = "AZFW_VNet"
  firewall_sku_tier   = "Premium"
  firewall_zones      = ["1", "2", "3"]
  firewall_policy_id  = module.firewall_policy.resource.id
  firewall_ip_configuration = [
    {
      name                 = "ipconfig_fw"
      subnet_id            = azurerm_subnet.fw_subnet.id
      public_ip_address_id = module.fw_public_ip.public_ip_id
    }
  ]
}

module "firewall_policy" {
  source              = "Azure/avm-res-network-firewallpolicy/azurerm"
  version             = ">=0.1.3"
  name                = "fw-policy-terraform"
  location            = azurerm_resource_group.rg-customer-vnets-eus2.location
  resource_group_name = azurerm_resource_group.rg-customer-vnets-eus2.name
  firewall_policy_sku = "Premium"
  firewall_policy_dns = {
    proxy_enabled = true
  }
  firewall_policy_threat_intelligence_mode = "Alert"
  tags = {
    deployment = "terraform"
  }
}

## Azure Firewall VM

resource "azurerm_network_interface" "spokefw_nic" {
  name                = "nic-spokefw-nic"
  location           = azurerm_resource_group.rg-customer-vnets-eus2.location
  resource_group_name = azurerm_resource_group.rg-customer-vnets-eus2.name

  ip_configuration {
    name                          = "ipconfig-spokefw-vm"
    subnet_id                     = azurerm_subnet.spoke2fw_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  
}

resource "azurerm_virtual_machine" "spokefw-vm" {
  name                  = "spokefw-vm"
  resource_group_name   = azurerm_resource_group.rg-customer-vnets-eus2.name
  location              = azurerm_resource_group.rg-customer-vnets-eus2.location
  network_interface_ids = [azurerm_network_interface.spokefw_nic.id]
  vm_size               = "Standard_B1ms"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk-spoke-vm2"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "spokefirewall-vm"
    admin_username = "mrojas"
    admin_password = "FreyiaRojas123!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }  
}


#blue vnets

resource "azurerm_virtual_network" "blue-vnet-1_vnet" {
    resource_group_name = azurerm_resource_group.rg-customer-vnets-eus2.name
    location            = azurerm_resource_group.rg-customer-vnets-eus2.location
    name                = "vnet-blue-vnet-1-eus2"
    address_space       = ["10.70.0.0/24"]
}

resource "azurerm_subnet" "blue-vnet-1_vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.rg-customer-vnets-eus2.name
  virtual_network_name = azurerm_virtual_network.blue-vnet-1_vnet.name
  address_prefixes     = ["10.70.0.0/26"]
}

## Blue Vnet VM

resource "azurerm_network_interface" "blue-vnet-1_nic" {
  name                = "nic-blue-vnet-1-vm"
  location           = azurerm_resource_group.rg-customer-vnets-eus2.location
  resource_group_name = azurerm_resource_group.rg-customer-vnets-eus2.name

  ip_configuration {
    name                          = "ipconfig-blue-vnet-1-vm"
    subnet_id                     = azurerm_subnet.blue-vnet-1_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  
}

resource "azurerm_virtual_machine" "blue-vnet-1" {
  name                  = "blue-vnet-1-vm"
  resource_group_name   = azurerm_resource_group.rg-customer-vnets-eus2.name
  location              = azurerm_resource_group.rg-customer-vnets-eus2.location
  network_interface_ids = [azurerm_network_interface.blue-vnet-1_nic.id]
  vm_size               = "Standard_B1ms"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk-blue-vnet-1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "blue-vnet-1-vm"
    admin_username = "mrojas"
    admin_password = "FreyiaRojas123!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }  
}

#Blue Vnet 2 VM and Vnet

resource "azurerm_virtual_network" "blue-vnet-2_vnet" {
    resource_group_name = azurerm_resource_group.rg-customer-vnets-eus2.name
    location            = azurerm_resource_group.rg-customer-vnets-eus2.location
    name                = "vnet-blue-vnet-2-eus2"
    address_space       = ["10.70.1.0/24"]
}

resource "azurerm_subnet" "blue-vnet-2_vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.rg-customer-vnets-eus2.name
  virtual_network_name = azurerm_virtual_network.blue-vnet-2_vnet.name
  address_prefixes     = ["10.70.1.0/26"]
}

## Blue Vnet VM

resource "azurerm_network_interface" "blue-vnet-2_nic" {
  name                = "nic-blue-vnet-2-vm"
  location           = azurerm_resource_group.rg-customer-vnets-eus2.location
  resource_group_name = azurerm_resource_group.rg-customer-vnets-eus2.name

  ip_configuration {
    name                          = "ipconfig-blue-vnet-2-vm"
    subnet_id                     = azurerm_subnet.blue-vnet-2_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  
}

resource "azurerm_virtual_machine" "blue-vnet-2" {
  name                  = "blue-vnet-2-vm"
  resource_group_name   = azurerm_resource_group.rg-customer-vnets-eus2.name
  location              = azurerm_resource_group.rg-customer-vnets-eus2.location
  network_interface_ids = [azurerm_network_interface.blue-vnet-2_nic.id]
  vm_size               = "Standard_B1ms"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk-blue-vnet-2"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "blue-vnet-2-vm"
    admin_username = "mrojas"
    admin_password = "FreyiaRojas123!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }  
}


