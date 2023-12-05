locals {
  custom_data = <<CUSTOM_DATA
#!/bin/bash
echo "Execute your super awesome commands here!"
sudo sed -i "s/#Port 22/Port 2222/" /etc/ssh/sshd_config
sudo systemctl restart ssh
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker azureuser
sudo apt-get -y install build-essential jq
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
curl -sL https://aka.ms/InstallAzureCLIDeb | bash
CUSTOM_DATA
}

resource "azurerm_resource_group" "this" {
  name     = "myvm-rg"
  location = "West Europe"
}

resource "azurerm_virtual_machine" "main" {
  name                  = "myubuntuvm"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.helmuser.id]
  }

storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "azureuser"
    #admin_password = "Password1234!"
    custom_data    = base64encode(local.custom_data)
  }



  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = var.public_ssh_key
    }
  }

  tags = {
    environment = "staging"
  }
}
