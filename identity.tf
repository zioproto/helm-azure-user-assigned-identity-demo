resource azurerm_user_assigned_identity helmuser {
  name = "helmuser"
  location = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource azurerm_role_assignment "helmuser" {
  scope = azurerm_resource_group.this.id
  role_definition_name = "Contributor"
  principal_id = azurerm_user_assigned_identity.helmuser.principal_id
}