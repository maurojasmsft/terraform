resource "azurerm_virtual_hub_routing_intent" "customer-routingintent" {
  name           = "customer-routingintent"
  virtual_hub_id = azurerm_virtual_hub.customer-vhub.id

  routing_policy {
    name         = "InternetTrafficPolicy"
    destinations = ["Internet"]
    next_hop     = azurerm_firewall.customer.id
  }
}

resource "azurerm_vpn_gateway" "vwan-gateway" {
    name                = "eus-hub-vng"
    location            = azurerm_resource_group.customer.location
    resource_group_name = azurerm_resource_group.customer.name
    virtual_hub_id      = azurerm_virtual_hub.eus-vhub.id
    timeouts {
      create = "4h"
      update = "4h"
      read = "10m"
      delete = "4h"
    }
  }


resource "azurerm_public_ip" "pip-fw" {

  # insert the 3 required variables here
  name                = "pip-fw"
  location            = azurerm_resource_group.rg-customer-vnets-eus2.location
  resource_group_name = azurerm_resource_group.rg-customer-vnets-eus2.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones = ["1", "2", "3"]
}


resource "azurerm_firewall" "example" {
  name                = "spoke-firewall"
  location            = azurerm_resource_group.rg-customer-vnets-eus2.location
  resource_group_name = azurerm_resource_group.rg-customer-vnets-eus2.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.fw_subnet.id
    public_ip_address_id = azurerm_public_ip.pip-fw.id
  }
}

route_table_ids = [replace(azurerm_virtual_hub.eus-vhub.default_route_table_id, "defaultRouteTable", "noneRouteTable")]