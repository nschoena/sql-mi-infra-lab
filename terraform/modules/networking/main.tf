# This Terraform configuration defines the networking components for a SQL Managed Instance deployment in Azure.
# 1. The Hub VNet (Connectivity & Management)
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-dev"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.hub_cidr]
}

# 2. The Spoke VNet (Data Tier)
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-spoke-sql-dev"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.spoke_cidr]
}

# 3. The SQL MI Subnet (Now Dynamic)
resource "azurerm_subnet" "sql_mi_subnet" {
  name                 = "snet-sqlmi-dev"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  
  # cidrsubnet(prefix, newbits, netnum)
  # This takes 10.200.0.0/16 and turns it into 10.200.1.0/24
  address_prefixes     = [cidrsubnet(var.spoke_cidr, 8, 1)]

  delegation {
    name = "managed_instance_delegation"
    service_delegation {
      name    = "Microsoft.Sql/managedInstances"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action", 
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", 
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

# 4. Hub to Spoke Peering
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "peer-hub-to-spoke"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# 5. Spoke to Hub Peering
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-spoke-to-hub"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# 6. Create the NSG for SQL MI
resource "azurerm_network_security_group" "sql_mi_nsg" {
  name                = "nsg-sqlmi-dev"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# 7. Mandatory Inbound Rule: Management Traffic
# Azure needs this to manage the cluster (High Availability, Patching)
resource "azurerm_network_security_rule" "allow_management_inbound" {
  name                        = "allow_management_inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "9000,9003,1438,1440,1452"
  source_address_prefix       = "CorpNetPublic" # Or "SqlManagement" Service Tag
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.sql_mi_nsg.name
}

# 8. Mandatory Inbound Rule: Internal MI Communication
resource "azurerm_network_security_rule" "allow_misubnet_inbound" {
  name                        = "allow_misubnet_inbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix = azurerm_subnet.sql_mi_subnet.address_prefixes[0] # Allow traffic from the MI subnet itself
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.sql_mi_nsg.name
}

# 9. Associate NSG with the SQL MI Subnet
resource "azurerm_subnet_network_security_group_association" "sql_mi_nsg_assoc" {
  subnet_id                 = azurerm_subnet.sql_mi_subnet.id
  network_security_group_id = azurerm_network_security_group.sql_mi_nsg.id
}