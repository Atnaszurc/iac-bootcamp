# Your infrastructure as a Canary or Blue-Green deployment

When managing and deploying infrastructure changes, the strategies of canary and blue-green deployments play a crucial role in ensuring stability and minimizing risks. These methods allow teams to validate infrastructure updates in a controlled manner, reducing the potential impact of configuration errors or compatibility issues.

In this section you build both with libvirt: two pools of web servers, one on Ubuntu 22.04 (blue) and one on Ubuntu 24.04 (green), and a load balancer that decides how much traffic each pool gets.

## Table of Contents

- [How the example is built](#how-the-example-is-built)
- [Task 1: Deploy the blue pool](#task-1-deploy-the-blue-pool)
- [Task 2: Put a load balancer in front](#task-2-put-a-load-balancer-in-front)
- [Task 3: Add a green canary pool](#task-3-add-a-green-canary-pool)
- [Task 4: Shift the traffic](#task-4-shift-the-traffic)
- [Task 5: Retire the blue pool](#task-5-retire-the-blue-pool)
- [Task 6: Roll a pool in place with create_before_destroy](#task-6-roll-a-pool-in-place-with-create_before_destroy)
- [Task 7: Clean up](#task-7-clean-up)
- [Extra tasks for the interested](#extra-tasks-for-the-interested)
- [Canary Deployments for Infrastructure](#canary-deployments-for-infrastructure)
- [Blue-Green Deployments for Infrastructure](#blue-green-deployments-for-infrastructure)
- [Comparison](#comparison)

## How the example is built

Everything is driven by one map variable, `vm_pools`. Each key is a pool, and each pool is a module instance:

```hcl
vm_pools = {
  blue = {
    base_image_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    vm_count       = 2
    weight         = 100
  }
}
```

| File | What it does |
|------|--------------|
| `main.tf` | Shared network and storage pool, one `module "vm_pool"` per map entry, and the load balancer config |
| `modules/libvirt-vm/` | One pool: base image, disks, cloud-init and VMs. Every VM installs nginx and serves a page saying which pool and OS answered |
| `templates/haproxy.cfg.tftpl` | HAProxy config template with every VM and its pool's weight |

libvirt has no load balancer resource, so Terraform writes an HAProxy config to `out/haproxy.cfg` and you run HAProxy on your host. That turns out to be a feature: you can read exactly what the load balancer is told to do.

## Task 1: Deploy the blue pool

```bash
cd example
terraform init
terraform apply
```

The first apply downloads the Ubuntu image, so it takes a minute or two depending on your connection. After that you have two VMs. The outputs show their addresses:

```
backends = [
  { "ip" = "10.210.0.170", "name" = "blue-e2f3-vm-0", "pool" = "blue", "weight" = 100 },
  { "ip" = "10.210.0.176", "name" = "blue-e2f3-vm-1", "pool" = "blue", "weight" = 100 },
]
generations = { "blue" = "e2f3" }
```

Your IPs and the four-character suffix will differ. The suffix is the pool's **generation**; Task 6 explains why it's there.

cloud-init needs another 15 to 30 seconds to install nginx. Then ask each VM directly:

```bash
curl http://10.210.0.170/
# pool=blue vm=0 os=Ubuntu 22.04.5 LTS
curl http://10.210.0.176/
# pool=blue vm=1 os=Ubuntu 22.04.5 LTS
```

If you get the default "Welcome to nginx!" page, cloud-init hasn't written the custom page yet. Wait a few seconds and try again.

## Task 2: Put a load balancer in front

Have a look at `out/haproxy.cfg`. The interesting part is at the bottom:

```
backend pools
    balance roundrobin
    # pool: blue
    server blue-e2f3-vm-0 10.210.0.170:80 weight 100 check
    # pool: blue
    server blue-e2f3-vm-1 10.210.0.176:80 weight 100 check
```

Start HAProxy with that config. With Docker:

```bash
docker run -d --name tf202-lb --network host \
  -v "$PWD/out:/usr/local/etc/haproxy:ro" haproxy:3.0-alpine
```

Or without Docker: `sudo apt install haproxy` and `haproxy -f out/haproxy.cfg`.

Now ask the load balancer instead of the VMs:

```bash
for i in $(seq 1 6); do curl -s http://localhost:8080/; done
# pool=blue vm=0 os=Ubuntu 22.04.5 LTS
# pool=blue vm=1 os=Ubuntu 22.04.5 LTS
# pool=blue vm=0 os=Ubuntu 22.04.5 LTS
# ...
```

Round robin across the blue pool. This is the "current production" you're about to upgrade.

## Task 3: Add a green canary pool

So how do you try Ubuntu 24.04 without betting everything on it? You add it next to what already works, and give it a small share of the traffic.

Create `terraform.tfvars`:

```hcl
vm_pools = {
  blue = {
    base_image_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    vm_count       = 2
    weight         = 90
  }
  green = {
    base_image_url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    vm_count       = 1
    weight         = 10
  }
}
```

Run `terraform plan` first and read it carefully:

```
  # local_file.haproxy_cfg must be replaced
  # module.vm_pool["green"].libvirt_domain.vm[0] will be created
  # ...
Plan: 7 to add, 0 to change, 1 to destroy.
```

Nothing in the blue pool is touched. The one "destroy" is the config file: `local_file` replaces the file whenever its content changes. That's the whole point of the pattern. The new version is built next to the old one, and the old one keeps serving while you check the new one.

Apply, wait for the green VM to answer, then tell HAProxy to reload its config:

```bash
terraform apply
docker kill -s HUP tf202-lb        # or: sudo systemctl reload haproxy
```

Send 190 requests and count who answered:

```bash
for i in $(seq 1 190); do curl -s http://localhost:8080/; done | sort | uniq -c
#   90 pool=blue vm=0 os=Ubuntu 22.04.5 LTS
#   90 pool=blue vm=1 os=Ubuntu 22.04.5 LTS
#   10 pool=green vm=0 os=Ubuntu 24.04.5 LTS
```

Why 10 out of 190 and not 10%? The weight is **per VM**. Two blue VMs at 90 plus one green VM at 10 gives green 10/190, a little over 5%. If you want the pool as a whole to get 10%, you have to take the number of VMs into account.

## Task 4: Shift the traffic

The canary looks healthy. Move the weights in steps, applying and reloading HAProxy each time:

| Step | blue weight | green weight | Green share (2 blue VMs, 1 green VM) |
|------|-------------|--------------|--------------------------------------|
| Canary | 90 | 10 | ~5% |
| Half | 50 | 100 | 50% |
| Green only | 0 | 100 | 100% |

A weight of 0 means HAProxy sends a server no new traffic, but the VMs are still there. That's your instant rollback: if green misbehaves, set blue back to 100 and green to 0, apply, reload. No VM needs to be created for you to go back.

Going straight from 100/0 to 0/100 in one step is a blue-green switch instead of a canary. Same code, different habit.

The variable has two validations you might run into: weights must be between 0 and 256 (HAProxy's range), and at least one pool must have a weight above 0.

## Task 5: Retire the blue pool

When green has carried all the traffic for a while, remove blue from `terraform.tfvars` and scale green to two VMs:

```hcl
vm_pools = {
  green = {
    base_image_url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    vm_count       = 2
    weight         = 100
  }
}
```

```bash
terraform apply
docker kill -s HUP tf202-lb
for i in $(seq 1 20); do curl -s http://localhost:8080/; done | sort | uniq -c
#   10 pool=green vm=0 os=Ubuntu 24.04.5 LTS
#   10 pool=green vm=1 os=Ubuntu 24.04.5 LTS
```

Compare `terraform output generations` before and after. Green's generation didn't change when it went from one VM to two. Scaling adds VMs, it doesn't rebuild the existing ones.

## Task 6: Roll a pool in place with create_before_destroy

Pools are great for big changes like a new OS. But what about a small one, like giving green more memory? Adding a whole new pool for that is a lot of ceremony.

Terraform's answer is `create_before_destroy`: build the replacement first, then remove the old one. The example uses it on every volume and VM in the module. There's a catch, though, and an earlier version of this very example walked straight into it:

```
Error: Domain Creation Failed
... already exists with uuid 37c05875-a28f-4cbd-a738-3a2b1bbac894
```

With `create_before_destroy`, the old and the new VM exist at the same time for a moment. libvirt won't allow two VMs with the same name, and the VMs were named `canary-vm-0` both before and after the change.

That's what the generation suffix fixes. In `modules/libvirt-vm/main.tf`:

```hcl
resource "random_id" "generation" {
  byte_length = 2

  keepers = {
    base_image_url = var.base_image_url
    memory_mb      = var.memory_mb
    vcpu_count     = var.vcpu_count
  }
}

locals {
  prefix = "${var.pool_name}-${random_id.generation.hex}"
}
```

When a keeper changes, `random_id` gets a new value. Every name built from `local.prefix` changes with it, and `replace_triggered_by = [random_id.generation]` makes sure the volumes and VMs are replaced rather than updated in place. `vm_count` is deliberately not a keeper, which is why scaling in Task 5 didn't roll the pool.

Try it. Give green 1536 MiB of memory:

```hcl
    memory_mb      = 1536
```

```bash
terraform apply
```

Watch the order of events in the output:

```
module.vm_pool["green"].libvirt_domain.vm[0]: Creation complete [name=green-<new>-vm-0]
module.vm_pool["green"].libvirt_domain.vm[1]: Creation complete [name=green-<new>-vm-1]
local_file.haproxy_cfg: Creation complete
module.vm_pool["green"].libvirt_domain.vm[0] (deposed object ...): Destroying... [name=green-<old>-vm-0]
module.vm_pool["green"].libvirt_domain.vm[1] (deposed object ...): Destroying... [name=green-<old>-vm-1]
```

New VMs first, then the new load balancer config, then the old VMs. The VMs use `wait_for_ip`, so Terraform doesn't consider a new VM created until it has an address.

One gap remains: HAProxy still has the old config loaded until you reload it, and by then the old VMs are gone. In a real pipeline the reload is part of the deployment. The extra tasks below show one way to make Terraform do it.

> 💡 The rule is general: `create_before_destroy` only works when the new object can exist next to the old one. Anything that must be unique, like VM names, volume names, bucket names or DNS records, needs a name that changes on replacement.

## Task 7: Clean up

```bash
terraform destroy
docker rm -f tf202-lb
```

## Extra tasks for the interested

1. **Reload HAProxy automatically.** Terraform 1.14 added actions, and the `hashicorp/local` provider has a `local_command` action. Trigger one from `local_file.haproxy_cfg` with `events = [after_create]` that runs `docker kill -s HUP tf202-lb`. Why `after_create` and not `after_update`? (Hint: look at what the plan says about the config file in Task 3.) See [TF-307](../../../TF-300-advanced/TF-307-query-actions/README.md).
2. **Make the weight mean "share of traffic".** Change the template so a pool's weight is spread across its VMs, so `weight = 10` gives the pool 10% no matter how many VMs it has.
3. **Health checks that know about your app.** HAProxy's `check` only tests that port 80 answers. Add `option httpchk GET /` and think about what a real health endpoint for your application would need to report.

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

In this lab you did both with the same code. The difference between a canary and a blue-green switch turned out to be how you move the weights, not how you build the infrastructure. Pick the strategy per change: a new OS deserves a canary, a config tweak is fine with a blue-green switch or an in-place roll.
