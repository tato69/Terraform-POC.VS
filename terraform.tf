resource "azurerm_resource_group" "test" {
  name     = "Terraform-POC.domainjoin"
  location = "West US 2"
}

resource "azurerm_public_ip" "test" {
  name                         = "acceptanceTestPublicIp1"
  location                     = "West US 2"
  resource_group_name          = "${azurerm_resource_group.test.name}"
  public_ip_address_allocation = "static"

  tags {
    environment = "Production"
  }
}

resource "azurerm_virtual_network" "test" {
  name                = "acctvn"
  address_space       = ["10.0.0.0/16"]
  location            = "West US 2"
  resource_group_name = "${azurerm_resource_group.test.name}"
  dns_servers         = ["10.0.2.4" , "8.8.8.8"]
}

resource "azurerm_subnet" "test" {
  name                 = "acctsub"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "test" {
  name                = "acctni"
  location            = "West US 2"
  resource_group_name = "${azurerm_resource_group.test.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.test.id}"
    private_ip_address_allocation = "static"
    private_ip_address = "10.0.2.4"
    public_ip_address_id          = "${azurerm_public_ip.test.id}"
  }
}

resource "azurerm_virtual_machine" "test" {
  name                  = "acctvm"
  location              = "West US 2"
  resource_group_name   = "${azurerm_resource_group.test.name}"
  network_interface_ids = ["${azurerm_network_interface.test.id}"]
  vm_size               = "Standard_B1ms"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2012-R2-Datacenter"
    version   = "latest"
  }

  # Uncomment this line to delete the OS disk automatically when deleting the VM
   delete_os_disk_on_termination = true

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "ariso001a"
    admin_password = "Password123"
  }


os_profile_windows_config {
    provision_vm_agent = "True"
}
}

resource "azurerm_virtual_machine_extension" "choco" {
name = "hostname22"
location = "West US 2"
resource_group_name = "${azurerm_resource_group.test.name}"
virtual_machine_name = "${azurerm_virtual_machine.test.name}"
publisher = "Microsoft.Compute"
type = "CustomScriptExtension"
type_handler_version = "1.8"
depends_on = ["azurerm_virtual_machine.test"]

settings = <<SETTINGS
{
"fileUris": ["https://raw.githubusercontent.com/tato69/Terraform-POC.VS/master/choco.ps1"],
"commandToExecute": "powershell.exe -executionpolicy bypass -file choco.ps1"
}
SETTINGS

}

resource "azurerm_virtual_machine_extension" "visualstudio" {
name = "hostname22"
location = "West US 2"
resource_group_name = "${azurerm_resource_group.test.name}"
virtual_machine_name = "${azurerm_virtual_machine.test.name}"
publisher = "Microsoft.Compute"
type = "CustomScriptExtension"
type_handler_version = "1.8"
depends_on = ["azurerm_virtual_machine_extension.choco"]

settings = <<SETTINGS
{
"fileUris": ["https://raw.githubusercontent.com/tato69/Terraform-POC.VS/master/VS.ps1"],
"commandToExecute": "powershell.exe -executionpolicy bypass -file VS.ps1"
}
SETTINGS

}

output "VS public IP" {
value = "${azurerm_public_ip.test.ip_address}"
}

