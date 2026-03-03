# Your infrastructure as a Canary or Blue-Green deployment

When managing and deploying infrastructure changes, the strategies of canary and blue-green deployments play a crucial role in ensuring stability and minimizing risks. These methods allow teams to validate infrastructure updates in a controlled manner, reducing the potential impact of configuration errors or compatibility issues.

## Table of Contents

[Tasks for blue-green deployment](#tasks-for-blue-green-deployment)
- [Task 1: Multiple virtual machines](#task-1-multiple-virtual-machines)
  - [1.1 Edit the network module](#11-edit-the-network-module)
  - [1.2 Add subnet_id output](#12-add-subnet_id-output)
  - [1.3 Edit the virtual machine module](#13-edit-the-virtual-machine-module)
  - [1.4 Add the Virtual Machine Extension and use it to install Nginx](#14-add-the-virtual-machine-extension-and-use-it-to-install-nginx)
  - [1.5 Link the security group to the network interface](#15-link-the-security-group-to-the-network-interface)
  - [1.6 Add outputs for the network interface id in the virtual machine module](#16-add-outputs-for-the-network-interface-id-in-the-virtual-machine-module)
- [Task 2: Add a load balancer with a public IP address](#task-2-add-a-load-balancer-with-a-public-ip-address)
  - [2.1 Create the IP address together with the load balancer](#21-create-the-ip-address-together-with-the-load-balancer)
  - [2.2 Add backend pool](#22-add-backend-pool)
  - [2.3 Add health probe and rules](#23-add-health-probe-and-rules)
  - [2.4 Add variables](#24-add-variables)
  - [2.5 Add outputs](#25-add-outputs)
- [Task 3: Update the azure/main.tf file](#task-3-update-the-azure/main.tf-file)
  - [3.1 Add the network security group](#31-add-the-network-security-group)
  - [3.2 Associate the network security group with the network interface](#32-associate-the-network-security-group-with-the-network-interface)
  - [3.3 Update the variables file](#33-update-the-variables-file)
- [Task 4: Test your new module](#task-4-test-your-new-module)
  - [4.1 Update the root module](#41-update-the-root-module)
  - [4.2 Run Terraform](#42-run-terraform)
  - [4.3 Test the new infrastructure](#43-test-the-new-infrastructure)
  - [4.4 Add a new virtual machine setup running Ubuntu 24.04 LTS](#44-add-a-new-virtual-machine-setup-running-ubuntu-2404-lts)
  - [4.5 Run Terraform](#45-run-terraform)
  - [4.6 Test the new infrastructure](#46-test-the-new-infrastructure)
  - [4.7 Remove VM-1](#47-remove-vm-1)
  - [4.8 Clean up](#48-clean-up)
- [Extra tasks for the interested](#extra-tasks-for-the-interested)

## Tasks for blue-green deployment

### Task 1: Multiple virtual machines

Start by using the code in the example folder, we need to modify some of the modules to be able to deploy multiple virtual machines.

#### 1.1 Edit the network module
First we need to migrate the network interface creation out of the network module and into the virtual machine module. 
To do this, we need to move the code block below to the virtual machine module.
```hcl
resource "azurerm_network_interface" "example" {
  name                = "${var.server_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}
```

As you can see, we need the subnet_id to be able to create the network interface, this value is currently being passed in from the network module.

#### 1.2 Add subnet_id output
In the network module, add the following output for the subnet_id.
```hcl
output "subnet_id" {
  value = azurerm_subnet.example.id
}
```
And remove the network_interface_id output.

#### 1.3 Edit the virtual machine module
In the virtual machine module, we need to add a variable for the subnet_id of the type string. Also, change the subnet_id in the resource block to use this variable. And update the creation of the vm to use the new resource that is locally available within the module. 

We also need to add a variable for the security group id, in this case it is the http security group id.
```hcl
variable "http_security_group_id" {
  type = string
}
```

We also need to need to add a variable for the source image reference of the virtual machine, an example of how to do this can be seen below.
```hcl
variable "source_image_reference" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  suffix = string
}
```
Don't forget to update the resource block to use this variable.

#### 1.4 Add the Virtual Machine Extension and use it to install Nginx

This is an example code of how you can do this:
```hcl
# Enable virtual machine extension and install Nginx
resource "azurerm_virtual_machine_extension" "example" {
  name                 = "Nginx"
  virtual_machine_id   = azurerm_linux_virtual_machine.example.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
 {
  "commandToExecute": "sudo apt-get update && sudo apt-get install nginx -y && echo \"Hello World from $(hostnamectl)\" > /var/www/html/index.html && sudo systemctl restart nginx"
 }
SETTINGS
}
```

#### 1.5 Link the security group to the network interface

This can be done by adding the following code to the virtual machine module.
```hcl
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = var.http_security_group_id
}
```

#### 1.6 Add outputs for the network interface id in the virtual machine module
Add the following outputs to the virtual machine module.
```hcl
output "network_interface_id" {
  value = azurerm_network_interface.example.id
}
```

Now, we have a module that can create virtual machines and it owns the respective network interface for said machine.
You need to remember to remove the network interface variable and the output from the network module.

### Task 2: Add a load balancer with a public IP address

#### 2.1 Create the IP address together with the load balancer

Create a new module for the load-balancer, and add the following code to the main.tf file you just created.
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.0.1"
    }
  }
}

resource "azurerm_public_ip" "example" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create Public Load Balancer
resource "azurerm_lb" "example" {
  name                = var.load_balancer_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = var.public_ip_name
    public_ip_address_id = azurerm_public_ip.example.id
  }
}
```

This will create a public IP address and a load balancer. Next up we need to add rules, backend pools and health probes to the load balancer.

#### 2.2 Add backend pool

This part will need information from the virtual machine module. Specifically, we need the network interface id's for the virtual machines we want to add to the backend pool.

Add the following code to the load balancer module.
```hcl
resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id      = azurerm_lb.example.id
  name                 = "virtual-machine-pool"
}

resource "azurerm_network_interface_backend_address_pool_association" "example" {
  count                   = length(var.network_interface_ids)
  network_interface_id    = var.network_interface_ids[count.index]
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.example.id
}
```

#### 2.3 Add health probe and rules

Add the following code to the load balancer module.
```hcl
resource "azurerm_lb_probe" "example" {
  loadbalancer_id     = azurerm_lb.example.id
  name                = "probe"
  port                = 80
}

resource "azurerm_lb_rule" "example" {
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "inbound"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  disable_outbound_snat          = true
  frontend_ip_configuration_name = var.public_ip_name
  probe_id                       = azurerm_lb_probe.example.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.example.id]
}

resource "azurerm_lb_outbound_rule" "example" {
  name                    = "outbound"
  loadbalancer_id         = azurerm_lb.example.id
  protocol                = "Tcp"
  backend_address_pool_id = azurerm_lb_backend_address_pool.example.id

  frontend_ip_configuration {
    name = var.public_ip_name
  }
}
```

#### 2.4 Add variables

Add the following variables to the load balancer module.
```hcl
variable "resource_group_name" {
  type = string
}   

variable "location" {
  type = string
}

variable "public_ip_name" {
  type = string
}

variable "load_balancer_name" {
  type = string
    }

variable "network_interface_ids" {
  type = list(string)
}
```

#### 2.5 Add outputs

Add an output for the public IP address.
```hcl
output "public_ip_address" {
  value = azurerm_public_ip.example.ip_address
}
```

### Task 3: Update the azure/main.tf file

#### 3.1 Add the load balancer module
Update the `azure/main.tf` file to use the new modules and variables.

The call to the load balancer module should look something like this.
```hcl
module "load-balancer" {
  source = "./load-balancer"
  resource_group_name = var.resource_group_name
  location = data.azurerm_resource_group.example.location
  public_ip_name = format("%s-public-ip", var.server_name)
  load_balancer_name = format("%s-load-balancer", var.server_name)
  network_interface_ids = [for vm in module.virtual-machine: vm.network_interface_id]
}
```

#### 3.2 Create a new variable for handling the virtual machine setup

To do this, we will create a map of virtual machine objects, so that we can easily deploy different virtual machines with different configurations into the same load balancer. 
Here is an example of how you can do this.
```hcl
variable "virtual_machine_setup" {
  type = map(object({
    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    suffix = string
  }))
  default = {
    "vm-1" = {
      source_image_reference = {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts"
        version   = "latest"
      }
      suffix = "ubuntu-22-04-lts"
    }
  }
}
```

Feel free to add more properties to the virtual machine object, but make sure to update the module to accept these new properties. One example would be to add flavor names, as well as the amount of virtual machines to deploy.

#### 3.3 Add outputs to the `azure/main.tf` file

Add the following outputs to the `azure/main.tf` file.
```hcl
output "public_ip" {
  value = module.load-balancer.public_ip
}
```

#### 3.4 Update the virtual machine module to use the new variables

Update the virtual machine module to use the new variables.

This can be done by rewriting the azure/main.tf file to use the new variables.
```hcl
module "virtual-machine" {
  source = "./virtual-machine"
  for_each = var.virtual_machine_setup
  resource_group_name = data.azurerm_resource_group.example.name
  location            = data.azurerm_resource_group.example.location
  public_ssh_key      = var.public_ssh_key
  server_name         = format("%s-%s", var.server_name, each.value.suffix)
  source_image_reference = each.value.source_image_reference
  subnet_id = module.network.subnet_id
  http_security_group_id = module.security-group.http_security_group_id
}
```

### Task 4: Test your new module

#### 4.1 Update your root module

Your root module should look something like this:
> main.tf
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.0.1"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "azure-vm" {
  source = "./modules/azure/"
  resource_group_name = var.resource_group_name
  server_name = var.server_name
  public_ssh_key = var.public_ssh_key
  virtual_machine_setup = var.virtual_machine_setup
}
```

> variables.tf
```hcl
variable "resource_group_name" {
  type = string
}

variable "server_name" {
  type = string
}

variable "public_ssh_key" {
  type = string
}

variable "virtual_machine_setup" {
  type = map(object({
    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    suffix = string
  }))
}

variable "subscription_id" {
  type = string
}
```

> outputs.tf
```hcl
output "public_ip" {
  value = "http://${module.azure-vm.public_ip}"
}
```

> terraform.tfvars
```hcl
virtual_machine_setup = {
  "vm-1" = {
    source_image_reference = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts"
      version   = "latest"
    }
    suffix = "ubuntu-22-04-lts"
  },
  "vm-2" = {
    source_image_reference = {
      publisher = "Canonical"
      offer     = "ubuntu-24_04-lts-daily"
      sku       = "server"
      version   = "24.04.202408220"
    }
    suffix = "ubuntu-24-04-lts"
  }
}
```

> terraform.tfvars
```hcl
server_name = "<your-server-name>"
resource_group_name = "<your-resource-group-name>"
public_ssh_key = "<your-public-ssh-key>"
virtual_machine_setup = {
  "vm-1" = {
    source_image_reference = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts"
      version   = "latest"
    }
    suffix = "ubuntu-22-04-lts"
  }
```

#### 4.2 Run Terraform

Run the following commands to run Terraform.
```bash
terraform init
terraform plan
terraform apply
```
#### 4.3 Test the new infrastructure

Use the output from the Terraform apply command to access the new infrastructure, either through your browser or by using curl.

Example with curl:
```bash
curl $(terraform output -raw public_ip)
```
#### 4.4 Add a new virtual machine setup running Ubuntu 24.04 LTS

Add the following to the terraform.tfvars file after the existing vm-1 entry. Make sure the {} are closed correctly.
```hcl
virtual_machine_setup = {
  "vm-2" = {
    source_image_reference = {
      publisher = "Canonical"
      offer     = "ubuntu-24_04-lts-daily"
      sku       = "server"
      version   = "24.04.202408220"
    }
    suffix = "ubuntu-24-04-lts"
  }
```

#### 4.5 Run Terraform

Run the following commands to run Terraform.
```bash
terraform plan
terraform apply
```

You should see that you will create about 5-6 new resources, all of which are related to the new virtual machine.

#### 4.6 Test the new infrastructure

Use the output from the Terraform apply command to access the new infrastructure, either through your browser or by using curl.

Run it a couple of times to see how it cycles through the virtual machines. The text on the website should change every now and then as the loadbalancer distributes the traffic across the new virtual machine. One will report an Operating System version of 22.04 and the other 24.04.

Example with curl:
```bash
curl $(terraform output -raw public_ip)
```

#### 4.7 Remove VM-1

This can be done by removing the entire vm-1 block from the virtual_machine_setup map in your terraform.tfvars file. Or by commenting it out. Run Terraform again and see how it affects the deployment. It should destroy 5-6 resources, and recreate 1 of them. 

The recreation will be the association with the load balancer. This will cause a temporary downtime, as the old virtual machine will be removed from the load balancer. 

A solution for this downtime would be to ensure that the old virtual machine is registered as unhealthy in the health probe. 

#### 4.8 Clean up

When you are done testing, you can remove the virtual machine setup from the terraform.tfvars file and run `terraform destroy`. If you just remove the blocks inside the virtual_machine_setup map, you will only remove the virtual machines, and the rest of the infrastructure will remain. 

#### Extra tasks for the interested

Consider other deployments that can use the same infrastructure, such as a web application. How would you deploy this? What changes would you need to make?

I've successfully deployed self-managed Kubernetes clusters on Openstack using the same structure, and managed to update the Kubernetes version without any downtime. 

Here is an example from the tfvars file used there:
```hcl
cluster_pools = {
  "cluster-1" = {
    color                     = "blue",
    rke2_version              = "v1.28.6+rke2r1",
    controller_instance_count = 3,
    controller_flavor_name    = "general-v1.4c.8g",
    worker_instance_count     = 3,
    worker_flavor_name        = "general-v1.8c.16g",
  }
  "cluster-2" = {
    color                     = "green",
    rke2_version              = "v1.29.5+rke2r1",
    controller_instance_count = 3,
    controller_flavor_name    = "general-v1.4c.8g",
    worker_instance_count     = 3,
    worker_flavor_name        = "general-v1.8c.16g",
  }
}
```

Consider looking at lifecycle arguments such as create_before_destroy, ignore_changes and prevent_destroy. Would these be useful in your blue/green or canary deployments? [Documentation](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle)

### Canary Deployments for Infrastructure

#### Definition

Canary deployments for infrastructure involve gradually rolling out changes to a small subset of the infrastructure environment. This approach allows teams to monitor the new changes under real-world conditions before applying them broadly, ensuring that any issues are caught early without affecting the entire infrastructure.

#### How It Works

1. **Preparation**:
    - The new infrastructure configuration or changes are applied to a small, isolated subset of the environment, known as the canary group.

2. **Initial Rollout**:
    - The canary group receives a small portion of the traffic or workload, allowing the new changes to be tested without impacting the majority of users or applications.

3. **Monitoring**:
    - Key metrics (e.g., performance, resource usage, error rates) for the canary group are closely monitored. Automated monitoring tools can help detect anomalies and deviations from expected behavior.

4. **Evaluation**:
    - Based on the monitoring data, a decision is made to either:
        - Incrementally expand the rollout to more infrastructure components until the changes are applied widely.
        - Roll back the changes if significant issues are detected, reverting the canary group to the previous state.

#### Benefits

- **Reduced Risk**: Early detection of issues limits exposure and potential impact.
- **Real-World Validation**: Changes are tested with actual workloads and traffic patterns.
- **Incremental Rollout**: Offers flexibility to stop and roll back at any stage if problems arise.

#### Drawbacks

- **Complexity**: Requires sophisticated monitoring and traffic management.
- **Resource Overhead**: Maintaining and monitoring multiple versions of the infrastructure temporarily increases resource usage.

---

### Blue-Green Deployments for Infrastructure

#### Definition

Blue-green deployments for infrastructure involve maintaining two identical environments: the "blue" (current) environment and the "green" (new) environment. When changes are ready to be deployed, they are applied to the green environment. Once the green environment is fully validated, traffic or workloads are switched from the blue to the green environment.

#### How It Works

1. **Preparation**:
    - The new infrastructure configuration is deployed to the idle green environment, while the current environment (blue) continues to serve all traffic and workloads.

2. **Testing**:
    - The green environment is rigorously tested to ensure the new changes are functioning correctly without impacting the live environment.

3. **Switching Traffic**:
    - After successful testing, traffic or workloads are switched from the blue environment to the green environment. This can be achieved using load balancers or DNS updates.

4. **Monitoring**:
    - Monitor the newly active green environment for any issues. If any problems arise, traffic can be quickly and easily switched back to the blue environment.

#### Benefits

- **Zero Downtime**: Traffic switching is instantaneous, resulting in minimal or no downtime.
- **Quick Rollback**: Rolling back is straightforward and can be done instantly by switching back to the blue environment.
- **Isolated Testing**: Changes can be thoroughly tested in the green environment without impacting the live environment.

#### Drawbacks

- **Resource Intensive**: Requires maintaining duplicate infrastructure environments, which can be costly.
- **Deployment Process Complexity**: Needs careful management to ensure consistent states and smooth traffic switching.

---

### Comparison

| Feature                     | Canary Deployments for Infrastructure           | Blue-Green Deployments for Infrastructure                  |
|-----------------------------|-------------------------------------------------|-----------------------------------------------------------|
| **Risk Mitigation**         | Gradual rollout mitigates risk                  | Full environment switch mitigates risk                     |
| **Downtime**                | Minimal, with gradual introduction              | Zero downtime, traffic switch is seamless                   |
| **Rollback Complexity**     | Can be complex, depending on the traffic split  | Simple, immediate rollback by switching traffic back       |
| **Resource Utilization**    | Temporary increased usage                       | Requires duplicate environments                             |
| **Implementation Complexity** | High, requires sophisticated monitoring and traffic management | Moderate, needs careful traffic management     |
| **Usage Scenarios**         | Ideal for continuous incremental deliveries     | Ideal for major updates requiring extensive testing        |
