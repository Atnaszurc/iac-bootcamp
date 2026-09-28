# A plan that passes every policy
environment  = "prod"
owner        = "data-team"
network_name = "net-prod-app"
network_mode = "nat"

vms = {
  web = {
    memory      = 2
    memory_unit = "GiB"
    vcpu        = 2
    disk_gib    = 20
  }
  db = {
    memory   = 4096
    vcpu     = 2
    disk_gib = 50
  }
}
