# 1. Create the Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-dev"
  location = var.location
}

# 2. Call the Networking Module
module "networking" {
  source              = "../../modules/networking"
  
  # Pass variables from the root into the module
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  hub_cidr            = "10.100.0.0/16"
  spoke_cidr          = "10.200.0.0/16"
}