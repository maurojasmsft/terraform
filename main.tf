resource "azurerm_resource_group" "customer" {
  name     = "customer-resources"
  location = "East US"
}

resource "azurerm_virtual_wan" "customer-vwan" {
  name                = "customer-vwan"
  resource_group_name = azurerm_resource_group.customer.name
  location            = azurerm_resource_group.customer.location
}

resource "azurerm_virtual_hub" "eus-vhub" {
  name                = "vhub-eus-vhub"
  resource_group_name = azurerm_resource_group.customer.name
  location            = azurerm_resource_group.customer.location
  virtual_wan_id      = azurerm_virtual_wan.customer-vwan.id
  address_prefix      = "192.168.0.0/24"
}

resource "azurerm_firewall" "customer" {
  name                = "customer-fw"
  location            = azurerm_resource_group.customer.location
  resource_group_name = azurerm_resource_group.customer.name
  sku_name            = "AZFW_Hub"
  sku_tier            = "Standard"
  firewall_policy_id = azurerm_firewall_policy.firewall-policy.id

  virtual_hub {
    virtual_hub_id  = azurerm_virtual_hub.eus-vhub.id
    public_ip_count = 1
  }
}

resource "azurerm_firewall_policy" "firewall-policy" {
  name                = "example-firewall-policy"
  resource_group_name = azurerm_resource_group.rg-customer-vnets-eus2.name
  location            = azurerm_resource_group.rg-customer-vnets-eus2.location
  sku = "Standard"
}


#east US connections
resource "azurerm_virtual_hub_connection" "eus2_vnet_connection_spoke1" {
  name                      = "eus2_vnet_connection_spoke1"
  virtual_hub_id            = azurerm_virtual_hub.eus-vhub.id
  remote_virtual_network_id = azurerm_virtual_network.spoke1_vnet.id
  
 routing {
   associated_route_table_id = azurerm_virtual_hub_route_table.RT_Red.id   
   }
   internet_security_enabled = "true"
 }


#Red2 Connection

resource "azurerm_virtual_hub_connection" "eus2_vnet_connection_red2spoke" {
  name                      = "eus2_vnet_connection_red2spoke"
  virtual_hub_id            = azurerm_virtual_hub.eus-vhub.id
  remote_virtual_network_id = azurerm_virtual_network.redspoke2_vnet.id
  routing {
   associated_route_table_id = azurerm_virtual_hub_route_table.RT_Red.id   
   }
    internet_security_enabled = "true"
}


resource "azurerm_virtual_hub_connection" "eus2_vnet_connection_spoke2fw" {
  name                      = "eus2_vnet_connection_spoke2fw"
  virtual_hub_id            = azurerm_virtual_hub.eus-vhub.id
  remote_virtual_network_id = azurerm_virtual_network.spoke2_fw-vnet.id
  routing {
    associated_route_table_id = azurerm_virtual_hub_route_table.RT_NVA.id
    propagated_route_table {
         labels = []
     route_table_ids = [azurerm_virtual_hub_route_table.RT_Blue.id]
    }
  #remove if it doesn't work
      static_vnet_route {
    name = "default"
    address_prefixes = ["0.0.0.0/0"]
    next_hop_ip_address = "10.80.0.132"
   }
   #remove if it doesn't work
    static_vnet_route {
    name = "RT_V2B"
    address_prefixes = ["10.201.0.0/24"]
    next_hop_ip_address = "10.80.0.132"
   }
   static_vnet_route {
    name = "RT_B2V"
    address_prefixes = ["10.70.0.0/16"]
    next_hop_ip_address = "10.80.0.132"
   }
  }
   internet_security_enabled = "true"
}

resource "azurerm_virtual_hub_connection" "eus2_vnet_connection_blue-vnet-1" {
  name                      = "eus2_vnet_connection_blue-vnet-1"
  virtual_hub_id            = azurerm_virtual_hub.eus-vhub.id
  remote_virtual_network_id = azurerm_virtual_network.blue-vnet-1_vnet.id
    routing {
   associated_route_table_id = azurerm_virtual_hub_route_table.RT_Blue.id 
   propagated_route_table {
     labels = []
     route_table_ids = [azurerm_virtual_hub_route_table.RT_Blue.id,azurerm_virtual_hub_route_table.RT_NVA.id]  
   }  
}
   internet_security_enabled = "true"
}


resource "azurerm_virtual_hub_connection" "eus2_vnet_connection_blue-vnet-2" {
  name                      = "eus2_vnet_connection_blue-vnet-2"
  virtual_hub_id            = azurerm_virtual_hub.eus-vhub.id
  remote_virtual_network_id = azurerm_virtual_network.blue-vnet-2_vnet.id
   routing {
   associated_route_table_id = azurerm_virtual_hub_route_table.RT_Blue.id 
   propagated_route_table {
     labels = []
     route_table_ids = [azurerm_virtual_hub_route_table.RT_Blue.id,azurerm_virtual_hub_route_table.RT_NVA.id]  
   }  
   
   }
    internet_security_enabled = "true"
}

#Route Table

resource "azurerm_virtual_hub_route_table" "RT_Red" {
  name           = "RT_Red"
  virtual_hub_id = azurerm_virtual_hub.eus-vhub.id
  labels         = []

  route {
  name              = "default"
  destinations_type = "CIDR"
  destinations      = ["0.0.0.0/0"]
  next_hop          = azurerm_firewall.customer.id
}

  route {
  name              = "red-spokes"
  destinations_type = "CIDR"
  destinations      = ["10.83.0.0/16"]
  next_hop          = azurerm_firewall.customer.id
}

  route {
  name              = "to-blue-spokes"
  destinations_type = "CIDR"
  destinations      = ["10.70.0.0/16"]
  next_hop          = azurerm_firewall.customer.id
}

  route {
  name              = "to-branch"
  destinations_type = "CIDR"
  destinations      = ["10.201.0.0/24"]
  next_hop          = azurerm_firewall.customer.id
}
}

#blue RT
resource "azurerm_virtual_hub_route_table" "RT_Blue" {
  name           = "RT_Blue"
  virtual_hub_id = azurerm_virtual_hub.eus-vhub.id
  labels         = []

 
 
 # route {
  #name              = "red-spokes"
  #destinations_type = "CIDR"
  #destinations      = ["10.83.0.0/16"]
  #next_hop          = azurerm_firewall.customer.id
}

#add a route table with next hop 10.201.0.0/16 to Spoke 2 connection manually

####May Remove if it doesn't work

resource "azurerm_virtual_hub_route_table_route" "default"{
route_table_id = azurerm_virtual_hub_route_table.RT_Blue.id
  name              = "default"
  destinations_type = "CIDR"
  destinations      = ["0.0.0.0/0"]
  next_hop_type     = "ResourceId"
  next_hop          = azurerm_virtual_hub_connection.eus2_vnet_connection_spoke2fw.id
}
####May Remove if it doesn't work

resource "azurerm_virtual_hub_route_table_route" "V2B"{
route_table_id = azurerm_virtual_hub_route_table.RT_Blue.id
  name              = "V2B"
  destinations_type = "CIDR"
  destinations      = ["10.201.0.0/24"]
  next_hop_type     = "ResourceId"
  next_hop          = azurerm_virtual_hub_connection.eus2_vnet_connection_spoke2fw.id
}

resource "azurerm_virtual_hub_route_table_route" "RedtoBlue" {
  route_table_id = azurerm_virtual_hub_route_table.RT_Blue.id
  name              = "RedtoBlue"
  destinations_type = "CIDR"
  destinations      = ["10.83.0.0/16"]
  next_hop_type     = "ResourceId"
  next_hop          = azurerm_firewall.customer.id
}


#RT NVA

resource "azurerm_virtual_hub_route_table" "RT_NVA" {
  name           = "RT_NVA"
  virtual_hub_id = azurerm_virtual_hub.eus-vhub.id
  labels         = []
}

#Express Route

#resource "azurerm_express_route_gateway" "expressRoute1" {
 # name                = "expressRoute1"
  #location            = azurerm_resource_group.customer.location
  #resource_group_name = azurerm_resource_group.customer.name
  #virtual_hub_id      = azurerm_virtual_hub.eus-vhub.id
  #scale_units         = 1
#}

resource "azurerm_vpn_gateway" "vwan-gateway" {
    name                = "eus-hub-vng"
   resource_group_name   = azurerm_resource_group.customer.name
   location              = azurerm_resource_group.customer.location
    virtual_hub_id      = azurerm_virtual_hub.eus-vhub.id
    timeouts {
      create = "4h"
      update = "4h"
      read = "10m"
      delete = "4h"
    }
  }

