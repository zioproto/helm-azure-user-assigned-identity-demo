# Helm repository login with Azure User-Assigned Managed Identity

This repo is a demo to deploy:
* a VM with a user-assigned managed identity
* an Azure Container Registry
* a role assignment to allow the VM to login to the ACR
* Helm will use the User-Assigned Managed Identity to login to the ACR

## Deploy the infrastructure

```
terraform init -upgrade
cp tfvars.example .tfvars
terraform apply -var-file=.tfvars
```

You will need later the public IP of the VM to login to the VM.
The name of the Azure Container Registry is also needed to login to the ACR.
The clientId of the User-Assigned Managed Identity is needed to login to the ACR.

Use the following commands to get the information:

```
az network public-ip list -o table
az acr list -o table
az identity show --name helmuser -g myvm-rg
```

## login

SSH to the VM on port 2222 with the public IP of the VM.

```
ssh -p 2222 azureuser@<publicIp>
```

Login to the ACR with the clientId of the User-Assigned Managed Identity.

```
az login --identity --user <ClientId>
az acr login --name <acrName> # Needs Docker installed
```

At this point Helm will use the Docker configuration to login to the ACR.
You can see the credentials in the Docker configuration.

```
$ cat ~/.docker/config.json

{
  "auths": {
    "openaizpequtrp.azurecr.io": {
      "auth": "<redacted>",
      "identitytoken": "<redacted>"
    }
  }
}
```

## Helm

Now you can use Helm push/pull to the ACR.

