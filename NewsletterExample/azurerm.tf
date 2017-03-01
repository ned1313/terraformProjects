provider "azurerm" {
  subscription_id = "${var.azure_subscription_id}"
  client_id       = "${var.azure_client_id}"
  client_secret   = "${var.azure_client_secret}"
  tenant_id       = "${var.azure_tenant_id}"
}

resource "azurerm_resource_group" "test" {
  name     = "${var.azure_resource_group_name}"
  location = "${var.azure_region}"
}

resource "azurerm_virtual_network" "network" {
  name                = "${var.azure_prefix}-vnet"
  address_space       = ["${var.network_address_space}"]
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.test.name}"
}

resource "azurerm_subnet" "subnet1" {
  name                 = "${var.azure_prefix}-subnet1"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_network_name = "${azurerm_virtual_network.network.name}"
  address_prefix       = "${var.subnet1_address_space}"
}

resource "azurerm_subnet" "subnet2" {
  name                 = "${var.azure_prefix}-subnet2"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_network_name = "${azurerm_virtual_network.network.name}"
  address_prefix       = "${var.subnet2_address_space}"
}

resource "azurerm_network_interface" "test" {
  name                      = "${var.azure_prefix}-ni1"
  location                  = "${var.azure_region}"
  resource_group_name       = "${azurerm_resource_group.test.name}"
  network_security_group_id = "${azurerm_network_security_group.test.id}"

  ip_configuration {
    name                          = "${var.azure_prefix}-ni1"
    subnet_id                     = "${azurerm_subnet.subnet1.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.test.id}"
  }
}

resource "azurerm_public_ip" "test" {
  name                         = "${var.azure_prefix}-pip1"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.test.name}"
  public_ip_address_allocation = "dynamic"

  tags {
    environment = "staging"
  }
}

resource "azurerm_network_security_group" "test" {
  name                = "${var.azure_prefix}-nsg1"
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.test.name}"

  security_rule {
    name                       = "allowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${var.my_public_ip}/32"
    destination_address_prefix = "*"
  }

  tags {
    environment = "staging"
  }
}

resource "azurerm_storage_account" "test" {
  name                = "${lower(var.azure_prefix)}accsa"
  resource_group_name = "${azurerm_resource_group.test.name}"
  location            = "${var.azure_region}"
  account_type        = "Standard_LRS"

  tags {
    environment = "staging"
  }
}

resource "azurerm_storage_container" "test" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.test.name}"
  storage_account_name  = "${azurerm_storage_account.test.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_machine" "test" {
  name                  = "${var.azure_prefix}-acctvm"
  location              = "${var.azure_region}"
  resource_group_name   = "${azurerm_resource_group.test.name}"
  network_interface_ids = ["${azurerm_network_interface.test.id}"]
  vm_size               = "Standard_A0"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "14.04.2-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "myosdisk1"
    vhd_uri       = "${azurerm_storage_account.test.primary_blob_endpoint}${azurerm_storage_container.test.name}/myosdisk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.azure_prefix}-client1"
    admin_username = "${var.client_username}"
    admin_password = "${var.client_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "staging"
  }
}
