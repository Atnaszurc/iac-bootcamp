# A plan that breaks several policies. Can you spot them all before OPA does?
environment  = "prod"
owner        = "data-team"
network_name = "prod-app"
network_mode = "open"

vms = {
  web = {
    memory      = 1
    memory_unit = "GiB"
    vcpu        = 1
    disk_gib    = 20
  }
  Batch_01 = {
    memory   = 32768
    vcpu     = 12
    disk_gib = 250
  }
  db = {
    memory   = 4096
    vcpu     = 2
    disk_gib = 50
    network  = "legacy-lab"
  }
}
