# PKR-103: Ansible Configuration Management

**Course**: PKR-100 Packer Fundamentals  
**Module**: PKR-103  
**Duration**: 1.5 hours  
**Prerequisites**: PKR-101, PKR-102  
**Difficulty**: Intermediate

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [Why Ansible with Packer?](#why-ansible-with-packer)
4. [Ansible Provisioner Fundamentals](#ansible-provisioner-fundamentals)
5. [Ansible Playbook Integration](#ansible-playbook-integration)
6. [Role-Based Provisioning](#role-based-provisioning)
7. [Advanced Ansible Patterns](#advanced-ansible-patterns)
8. [Best Practices](#best-practices)
9. [Hands-On Labs](#hands-on-labs)
10. [Troubleshooting](#troubleshooting)
11. [Checkpoint Quiz](#checkpoint-quiz)
12. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This course teaches you how to use Ansible with Packer to create sophisticated, maintainable VM images. You'll learn how to leverage Ansible's powerful configuration management capabilities to build complex images with proper software installation, configuration, and hardening.

### What You'll Build

By the end of this course, you'll be able to:
- Configure the Ansible provisioner in Packer templates
- Write Ansible playbooks for image provisioning
- Use Ansible roles for modular configuration
- Implement complex multi-tier application images
- Apply security hardening with Ansible
- Debug Ansible provisioning issues

### Course Structure

```
PKR-103-ansible/
├── README.md                          # This file
├── example/
│   ├── 01-basic-ansible/              # Basic Ansible provisioner
│   │   ├── template.pkr.hcl
│   │   └── playbook.yml
│   ├── 02-web-server/                 # Web server with Ansible
│   │   ├── template.pkr.hcl
│   │   ├── playbook.yml
│   │   └── files/
│   ├── 03-ansible-roles/              # Role-based provisioning
│   │   ├── template.pkr.hcl
│   │   ├── playbook.yml
│   │   └── roles/
│   └── 04-complex-app/                # Multi-tier application
│       ├── template.pkr.hcl
│       ├── playbook.yml
│       ├── roles/
│       └── files/
└── labs/
    ├── lab1-ansible-basics.md
    ├── lab2-web-application.md
    └── lab3-hardened-image.md
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Configure Ansible Provisioner**
   - Set up Ansible provisioner in Packer templates
   - Configure connection settings and options
   - Handle SSH authentication and sudo

2. **Write Ansible Playbooks**
   - Create playbooks for image provisioning
   - Use Ansible modules effectively
   - Implement idempotent configurations

3. **Use Ansible Roles**
   - Structure code with Ansible roles
   - Create reusable role libraries
   - Manage role dependencies

4. **Implement Complex Configurations**
   - Build multi-tier application images
   - Configure databases and web servers
   - Apply security hardening

5. **Debug and Troubleshoot**
   - Enable verbose output
   - Debug Ansible tasks
   - Handle common provisioning errors

---

## 🤔 Why Ansible with Packer?

### The Power of Ansible

Ansible is a powerful configuration management tool that brings several advantages to image building:

#### 1. **Declarative Configuration**
```yaml
# Ansible describes WHAT you want, not HOW to do it
- name: Ensure Nginx is installed
  apt:
    name: nginx
    state: present
```

vs Shell provisioner:
```bash
# Shell describes HOW to do it
if ! command -v nginx &> /dev/null; then
    apt-get update
    apt-get install -y nginx
fi
```

#### 2. **Idempotency**
Ansible tasks can be run multiple times safely:
```yaml
- name: Create application directory
  file:
    path: /opt/myapp
    state: directory
    mode: '0755'
```
Running this multiple times produces the same result.

#### 3. **Rich Module Library**
Ansible has 3,000+ modules for:
- Package management (apt, yum, dnf)
- File operations (copy, template, lineinfile)
- Service management (systemd, service)
- User management (user, group)
- Security (firewalld, selinux, ufw)
- And much more...

#### 4. **Reusability**
Ansible roles can be shared across:
- Packer image builds
- Terraform provisioners
- Direct server configuration
- CI/CD pipelines

### When to Use Ansible vs Shell

| Use Case | Ansible | Shell |
|----------|---------|-------|
| Simple commands | ❌ Overkill | ✅ Perfect |
| Complex configuration | ✅ Excellent | ❌ Hard to maintain |
| Multi-step setup | ✅ Excellent | ⚠️ Gets messy |
| Reusable code | ✅ Roles | ❌ Hard to share |
| Idempotency | ✅ Built-in | ❌ Manual |
| Cross-platform | ✅ Good | ⚠️ OS-specific |

### Ansible + Packer Benefits

1. **Maintainability**: Playbooks are easier to read and maintain than shell scripts
2. **Testability**: Ansible playbooks can be tested independently
3. **Reusability**: Same playbooks for images and live servers
4. **Community**: Thousands of pre-built roles on Ansible Galaxy
5. **Documentation**: Playbooks are self-documenting

---

## 📚 Ansible Provisioner Fundamentals

### Basic Configuration

The Ansible provisioner runs Ansible playbooks against the VM being built:

```hcl
# template.pkr.hcl
packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "ubuntu" {
  iso_url          = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso"
  iso_checksum     = "sha256:a4acfda10b18da50e2ec50ccaf860d7f20b389df8765611142305c0e911d16fd"
  output_directory = "output"
  vm_name          = "ubuntu-ansible.qcow2"
  disk_size        = "10G"
  format           = "qcow2"
  accelerator      = "kvm"
  
  ssh_username     = "ubuntu"
  ssh_password     = "ubuntu"
  ssh_timeout      = "20m"
  
  shutdown_command = "echo 'ubuntu' | sudo -S shutdown -P now"
  
  http_directory   = "http"
  boot_wait        = "5s"
  boot_command = [
    "<esc><wait>",
    "linux /casper/vmlinuz autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<enter>",
    "initrd /casper/initrd<enter>",
    "boot<enter>"
  ]
}

build {
  sources = ["source.qemu.ubuntu"]
  
  # Ansible provisioner
  provisioner "ansible" {
    playbook_file = "playbook.yml"
  }
}
```

### Ansible Provisioner Options

#### Essential Options

```hcl
provisioner "ansible" {
  # Required: Path to playbook
  playbook_file = "playbook.yml"
  
  # Optional: Extra arguments to ansible-playbook
  extra_arguments = [
    "--extra-vars", "env=production",
    "--tags", "install,configure"
  ]
  
  # Optional: Ansible user (defaults to SSH user)
  user = "ubuntu"
  
  # Optional: Use sudo for privilege escalation
  use_sudo = true
  
  # Optional: Inventory groups
  groups = ["webservers", "production"]
  
  # Optional: Host alias in inventory
  host_alias = "packer-build"
}
```

#### Advanced Options

```hcl
provisioner "ansible" {
  playbook_file = "playbook.yml"
  
  # Ansible configuration
  ansible_env_vars = [
    "ANSIBLE_HOST_KEY_CHECKING=False",
    "ANSIBLE_SSH_ARGS='-o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=60s'",
    "ANSIBLE_NOCOLOR=True"
  ]
  
  # Local Ansible installation
  local_port = 2222
  
  # Inventory file (instead of dynamic)
  inventory_file = "inventory.ini"
  
  # Galaxy requirements
  galaxy_file = "requirements.yml"
  
  # Roles path
  roles_path = "roles"
  
  # Keep generated inventory
  keep_inventory_file = true
}
```

### Connection Configuration

#### SSH Connection

```hcl
provisioner "ansible" {
  playbook_file = "playbook.yml"
  
  # SSH settings
  user = "ubuntu"
  use_sudo = true
  
  # SSH key authentication
  ssh_authorized_key_file = "~/.ssh/id_rsa.pub"
  ssh_host_key_file = "~/.ssh/known_hosts"
  
  # Connection timeout
  ansible_env_vars = [
    "ANSIBLE_SSH_TIMEOUT=30"
  ]
}
```

#### Privilege Escalation

```hcl
provisioner "ansible" {
  playbook_file = "playbook.yml"
  
  # Method 1: Use sudo (default)
  use_sudo = true
  
  # Method 2: Extra arguments
  extra_arguments = [
    "--become",
    "--become-method=sudo",
    "--become-user=root"
  ]
}
```

### Environment Variables

Control Ansible behavior with environment variables:

```hcl
provisioner "ansible" {
  playbook_file = "playbook.yml"
  
  ansible_env_vars = [
    # Disable host key checking (for new VMs)
    "ANSIBLE_HOST_KEY_CHECKING=False",
    
    # Increase verbosity
    "ANSIBLE_VERBOSITY=2",
    
    # Disable color output (for logs)
    "ANSIBLE_NOCOLOR=True",
    
    # Set Python interpreter
    "ANSIBLE_PYTHON_INTERPRETER=/usr/bin/python3",
    
    # Connection settings
    "ANSIBLE_SSH_PIPELINING=True",
    "ANSIBLE_SSH_RETRIES=3"
  ]
}
```

---

## 🎭 Ansible Playbook Integration

### Basic Playbook Structure

```yaml
# playbook.yml
---
- name: Configure Ubuntu VM
  hosts: all
  become: yes
  
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
    
    - name: Install essential packages
      apt:
        name:
          - vim
          - curl
          - wget
          - git
        state: present
    
    - name: Create application user
      user:
        name: appuser
        shell: /bin/bash
        create_home: yes
```

### Playbook Best Practices

#### 1. **Use Descriptive Task Names**

❌ Bad:
```yaml
- name: Install stuff
  apt:
    name: nginx
```

✅ Good:
```yaml
- name: Install Nginx web server
  apt:
    name: nginx
    state: present
```

#### 2. **Make Tasks Idempotent**

❌ Bad:
```yaml
- name: Add line to file
  shell: echo "export PATH=$PATH:/opt/bin" >> ~/.bashrc
```

✅ Good:
```yaml
- name: Add /opt/bin to PATH
  lineinfile:
    path: ~/.bashrc
    line: 'export PATH=$PATH:/opt/bin'
    state: present
```

#### 3. **Use Variables**

```yaml
---
- name: Configure web server
  hosts: all
  become: yes
  
  vars:
    app_name: myapp
    app_port: 8080
    app_user: appuser
  
  tasks:
    - name: Create application user
      user:
        name: "{{ app_user }}"
        shell: /bin/bash
    
    - name: Create application directory
      file:
        path: "/opt/{{ app_name }}"
        state: directory
        owner: "{{ app_user }}"
        mode: '0755'
```

#### 4. **Handle Errors Gracefully**

```yaml
- name: Check if service exists
  stat:
    path: /etc/systemd/system/myapp.service
  register: service_file
  
- name: Stop service if it exists
  systemd:
    name: myapp
    state: stopped
  when: service_file.stat.exists
  ignore_errors: yes
```

### Common Ansible Modules

#### Package Management

```yaml
# APT (Debian/Ubuntu)
- name: Install packages with apt
  apt:
    name:
      - nginx
      - postgresql
      - redis-server
    state: present
    update_cache: yes

# YUM/DNF (RHEL/CentOS/Fedora)
- name: Install packages with yum
  yum:
    name:
      - nginx
      - postgresql-server
      - redis
    state: present
```

#### File Operations

```yaml
# Copy files
- name: Copy configuration file
  copy:
    src: files/nginx.conf
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
    backup: yes

# Template files (with variables)
- name: Generate config from template
  template:
    src: templates/app.conf.j2
    dest: /etc/myapp/app.conf
    owner: appuser
    mode: '0640'

# Create directories
- name: Create application directories
  file:
    path: "{{ item }}"
    state: directory
    owner: appuser
    mode: '0755'
  loop:
    - /opt/myapp
    - /opt/myapp/logs
    - /opt/myapp/data

# Modify file content
- name: Set timezone in config
  lineinfile:
    path: /etc/myapp/app.conf
    regexp: '^timezone='
    line: 'timezone=UTC'
```

#### Service Management

```yaml
# Systemd services
- name: Enable and start Nginx
  systemd:
    name: nginx
    enabled: yes
    state: started
    daemon_reload: yes

# Restart service
- name: Restart application service
  systemd:
    name: myapp
    state: restarted
  when: config_changed
```

#### User Management

```yaml
# Create users
- name: Create application user
  user:
    name: appuser
    comment: "Application User"
    shell: /bin/bash
    create_home: yes
    groups: www-data
    append: yes

# Create groups
- name: Create application group
  group:
    name: appgroup
    state: present
```

### Web Server Example

Complete playbook for Nginx web server:

```yaml
# playbook.yml
---
- name: Configure Nginx web server
  hosts: all
  become: yes
  
  vars:
    nginx_port: 80
    site_name: mywebsite
    document_root: /var/www/html
  
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
    
    - name: Install Nginx
      apt:
        name: nginx
        state: present
    
    - name: Create document root
      file:
        path: "{{ document_root }}"
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'
    
    - name: Copy website files
      copy:
        src: files/index.html
        dest: "{{ document_root }}/index.html"
        owner: www-data
        group: www-data
        mode: '0644'
    
    - name: Configure Nginx site
      template:
        src: templates/nginx-site.conf.j2
        dest: /etc/nginx/sites-available/{{ site_name }}
        owner: root
        group: root
        mode: '0644'
      notify: Restart Nginx
    
    - name: Enable Nginx site
      file:
        src: /etc/nginx/sites-available/{{ site_name }}
        dest: /etc/nginx/sites-enabled/{{ site_name }}
        state: link
      notify: Restart Nginx
    
    - name: Remove default site
      file:
        path: /etc/nginx/sites-enabled/default
        state: absent
      notify: Restart Nginx
    
    - name: Ensure Nginx is started and enabled
      systemd:
        name: nginx
        state: started
        enabled: yes
  
  handlers:
    - name: Restart Nginx
      systemd:
        name: nginx
        state: restarted
```

Template file (`templates/nginx-site.conf.j2`):
```nginx
server {
    listen {{ nginx_port }};
    server_name _;
    
    root {{ document_root }};
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
```

---

## 🎯 Role-Based Provisioning

### What Are Ansible Roles?

Roles are a way to organize playbooks into reusable components:

```
roles/
├── common/              # Common configuration
│   ├── tasks/
│   │   └── main.yml
│   ├── handlers/
│   │   └── main.yml
│   ├── files/
│   ├── templates/
│   └── vars/
│       └── main.yml
├── webserver/           # Web server role
│   ├── tasks/
│   │   └── main.yml
│   ├── handlers/
│   │   └── main.yml
│   └── templates/
│       └── nginx.conf.j2
└── database/            # Database role
    ├── tasks/
    │   └── main.yml
    └── vars/
        └── main.yml
```

### Creating a Role

#### Role Structure

```bash
# Create role structure
mkdir -p roles/webserver/{tasks,handlers,templates,files,vars,defaults}
```

#### Role Tasks (`roles/webserver/tasks/main.yml`)

```yaml
---
# Main tasks for webserver role
- name: Install Nginx
  apt:
    name: nginx
    state: present
    update_cache: yes

- name: Copy Nginx configuration
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
  notify: Restart Nginx

- name: Ensure Nginx is started
  systemd:
    name: nginx
    state: started
    enabled: yes
```

#### Role Handlers (`roles/webserver/handlers/main.yml`)

```yaml
---
# Handlers for webserver role
- name: Restart Nginx
  systemd:
    name: nginx
    state: restarted

- name: Reload Nginx
  systemd:
    name: nginx
    state: reloaded
```

#### Role Variables (`roles/webserver/vars/main.yml`)

```yaml
---
# Variables for webserver role
nginx_port: 80
nginx_worker_processes: auto
nginx_worker_connections: 1024
document_root: /var/www/html
```

#### Role Defaults (`roles/webserver/defaults/main.yml`)

```yaml
---
# Default variables (can be overridden)
nginx_port: 80
nginx_user: www-data
nginx_group: www-data
```

### Using Roles in Playbooks

```yaml
# playbook.yml
---
- name: Configure web server
  hosts: all
  become: yes
  
  roles:
    - common
    - webserver
```

With variables:
```yaml
---
- name: Configure web server
  hosts: all
  become: yes
  
  roles:
    - role: webserver
      vars:
        nginx_port: 8080
        document_root: /opt/website
```

### Multi-Role Example

```yaml
# playbook.yml
---
- name: Configure application server
  hosts: all
  become: yes
  
  vars:
    app_name: myapp
    app_port: 8080
  
  roles:
    # Base system configuration
    - role: common
      tags: ['common']
    
    # Security hardening
    - role: security
      tags: ['security']
    
    # Web server
    - role: webserver
      vars:
        nginx_port: 80
      tags: ['webserver']
    
    # Application
    - role: application
      vars:
        app_name: "{{ app_name }}"
        app_port: "{{ app_port }}"
      tags: ['application']
```

### Role Dependencies

Define dependencies in `meta/main.yml`:

```yaml
# roles/application/meta/main.yml
---
dependencies:
  - role: common
  - role: webserver
    vars:
      nginx_port: 80
```

### Ansible Galaxy Roles

Use community roles from Ansible Galaxy:

```yaml
# requirements.yml
---
roles:
  - name: geerlingguy.nginx
    version: 3.1.4
  
  - name: geerlingguy.postgresql
    version: 3.4.0
```

Install roles:
```bash
ansible-galaxy install -r requirements.yml
```

Use in Packer:
```hcl
provisioner "ansible" {
  playbook_file = "playbook.yml"
  galaxy_file   = "requirements.yml"
  roles_path    = "roles"
}
```

---

## 🚀 Advanced Ansible Patterns

### Conditional Execution

```yaml
- name: Install packages based on OS
  apt:
    name: nginx
    state: present
  when: ansible_os_family == "Debian"

- name: Install packages on RHEL
  yum:
    name: nginx
    state: present
  when: ansible_os_family == "RedHat"
```

### Loops and Iteration

```yaml
# Simple loop
- name: Create multiple directories
  file:
    path: "{{ item }}"
    state: directory
  loop:
    - /opt/app1
    - /opt/app2
    - /opt/app3

# Loop with dict
- name: Create users
  user:
    name: "{{ item.name }}"
    groups: "{{ item.groups }}"
  loop:
    - { name: 'alice', groups: 'admin' }
    - { name: 'bob', groups: 'users' }
```

### Error Handling

```yaml
- name: Try to start service
  systemd:
    name: myapp
    state: started
  register: service_result
  failed_when: false
  changed_when: service_result.rc == 0

- name: Handle service failure
  debug:
    msg: "Service failed to start, continuing anyway"
  when: service_result.rc != 0
```

### Blocks and Rescue

```yaml
- name: Handle errors with blocks
  block:
    - name: Attempt risky operation
      command: /opt/risky-script.sh
    
    - name: Follow-up task
      debug:
        msg: "Risky operation succeeded"
  
  rescue:
    - name: Handle failure
      debug:
        msg: "Risky operation failed, running recovery"
    
    - name: Recovery task
      command: /opt/recovery-script.sh
  
  always:
    - name: Cleanup (always runs)
      file:
        path: /tmp/temp-file
        state: absent
```

### Tags for Selective Execution

```yaml
- name: Install packages
  apt:
    name: nginx
  tags: ['install', 'packages']

- name: Configure Nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  tags: ['configure', 'nginx']

- name: Start services
  systemd:
    name: nginx
    state: started
  tags: ['services']
```

Run specific tags:
```hcl
provisioner "ansible" {
  playbook_file = "playbook.yml"
  extra_arguments = [
    "--tags", "install,configure"
  ]
}
```

### Vault for Secrets

Encrypt sensitive data:

```bash
# Create encrypted file
ansible-vault create secrets.yml

# Edit encrypted file
ansible-vault edit secrets.yml
```

```yaml
# secrets.yml (encrypted)
db_password: supersecret
api_key: abc123xyz
```

Use in playbook:
```yaml
- name: Configure database
  hosts: all
  become: yes
  vars_files:
    - secrets.yml
  
  tasks:
    - name: Set database password
      postgresql_user:
        name: dbuser
        password: "{{ db_password }}"
```

Packer configuration:
```hcl
provisioner "ansible" {
  playbook_file = "playbook.yml"
  extra_arguments = [
    "--vault-password-file", ".vault-pass"
  ]
}
```

---

## ✅ Best Practices

### 1. Playbook Organization

```
ansible/
├── playbook.yml              # Main playbook
├── requirements.yml          # Galaxy requirements
├── inventory/
│   └── hosts.ini
├── group_vars/
│   ├── all.yml              # Variables for all hosts
│   └── webservers.yml       # Group-specific variables
├── host_vars/
│   └── packer-build.yml     # Host-specific variables
├── roles/
│   ├── common/
│   ├── webserver/
│   └── application/
├── files/
│   └── static-files/
└── templates/
    └── config-templates/
```

### 2. Variable Precedence

Understand variable precedence (lowest to highest):
1. Role defaults (`roles/*/defaults/main.yml`)
2. Inventory variables
3. Playbook variables
4. Role variables (`roles/*/vars/main.yml`)
5. Extra variables (`--extra-vars`)

### 3. Idempotency

Always write idempotent tasks:

❌ Not idempotent:
```yaml
- name: Add line to file
  shell: echo "config=value" >> /etc/app.conf
```

✅ Idempotent:
```yaml
- name: Set configuration value
  lineinfile:
    path: /etc/app.conf
    regexp: '^config='
    line: 'config=value'
```

### 4. Testing Playbooks

Test playbooks before using in Packer:

```bash
# Syntax check
ansible-playbook playbook.yml --syntax-check

# Dry run
ansible-playbook playbook.yml --check

# Run with verbosity
ansible-playbook playbook.yml -vvv
```

### 5. Performance Optimization

```yaml
# Disable fact gathering if not needed
- name: Quick configuration
  hosts: all
  gather_facts: no
  
  tasks:
    - name: Simple task
      command: echo "Hello"
```

```hcl
# Packer: Enable pipelining
provisioner "ansible" {
  playbook_file = "playbook.yml"
  ansible_env_vars = [
    "ANSIBLE_SSH_PIPELINING=True"
  ]
}
```

### 6. Documentation

Document your playbooks:

```yaml
---
# playbook.yml
# Purpose: Configure web server for production
# Requirements: Ubuntu 22.04, sudo access
# Variables:
#   - nginx_port: Port for Nginx (default: 80)
#   - app_name: Application name (required)

- name: Configure web server
  hosts: all
  become: yes
  # ... tasks ...
```

### 7. Error Messages

Provide helpful error messages:

```yaml
- name: Verify required variables
  assert:
    that:
      - app_name is defined
      - app_port is defined
    fail_msg: "Required variables app_name and app_port must be defined"
    success_msg: "All required variables are defined"
```

---

## 🔬 Hands-On Labs

### Lab 1: Basic Ansible Provisioning (15 minutes)

**Objective**: Create a Packer template that uses Ansible to configure a basic Ubuntu VM.

**Tasks**:
1. Create a Packer template with QEMU builder
2. Write an Ansible playbook that:
   - Updates package cache
   - Installs vim, curl, wget, git
   - Creates a user named "devuser"
   - Sets up a custom MOTD
3. Build the image
4. Verify the configuration

**Expected Output**:
- Image with installed packages
- User "devuser" exists
- Custom MOTD displays on login

**Hints**:
- Use `apt` module for packages
- Use `user` module for user creation
- Use `copy` module for MOTD file

---

### Lab 2: Web Application Image (20 minutes)

**Objective**: Build a complete web server image with Nginx and a custom website.

**Tasks**:
1. Create Ansible playbook with:
   - Nginx installation
   - Custom website deployment
   - SSL certificate setup (self-signed)
   - Firewall configuration
2. Use templates for Nginx configuration
3. Deploy static website files
4. Build and test the image

**Expected Output**:
- Nginx serving custom website
- SSL configured
- Firewall rules applied

**Hints**:
- Use `template` module for Nginx config
- Use `copy` module for website files
- Use `ufw` module for firewall

---

### Lab 3: Hardened Image with Roles (30 minutes)

**Objective**: Create a security-hardened image using Ansible roles.

**Tasks**:
1. Create three roles:
   - `common`: Base system configuration
   - `security`: Security hardening
   - `webserver`: Nginx configuration
2. Implement security measures:
   - Disable root login
   - Configure SSH hardening
   - Set up automatic updates
   - Configure fail2ban
3. Build the image
4. Verify security configurations

**Expected Output**:
- Hardened SSH configuration
- Fail2ban installed and configured
- Automatic updates enabled
- Web server running securely

**Hints**:
- Use `lineinfile` for SSH config
- Use `apt` module for fail2ban
- Use `systemd` module for services

---

## 🐛 Troubleshooting

### Common Issues

#### 1. SSH Connection Failures

**Problem**: Ansible can't connect to VM
```
FAILED! => {"msg": "Failed to connect to the host via ssh"}
```

**Solutions**:
```hcl
# Increase SSH timeout
provisioner "ansible" {
  playbook_file = "playbook.yml"
  ansible_env_vars = [
    "ANSIBLE_HOST_KEY_CHECKING=False",
    "ANSIBLE_SSH_TIMEOUT=60"
  ]
}
```

#### 2. Sudo Password Required

**Problem**: Tasks fail with "sudo: a password is required"

**Solutions**:
```hcl
# Enable sudo
provisioner "ansible" {
  playbook_file = "playbook.yml"
  use_sudo = true
}
```

Or configure passwordless sudo in cloud-init:
```yaml
# user-data
users:
  - name: ubuntu
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
```

#### 3. Python Not Found

**Problem**: "/usr/bin/python: not found"

**Solution**:
```hcl
provisioner "ansible" {
  playbook_file = "playbook.yml"
  ansible_env_vars = [
    "ANSIBLE_PYTHON_INTERPRETER=/usr/bin/python3"
  ]
}
```

#### 4. Module Not Found

**Problem**: "The module X was not found"

**Solution**:
```yaml
# Install required Python packages first
- name: Install Python dependencies
  apt:
    name:
      - python3-pip
      - python3-setuptools
    state: present

- name: Install Python modules
  pip:
    name:
      - docker
      - boto3
```

### Debugging Techniques

#### Enable Verbose Output

```hcl
provisioner "ansible" {
  playbook_file = "playbook.yml"
  extra_arguments = [
    "-vvv"  # Very verbose
  ]
}
```

#### Debug Tasks

```yaml
- name: Debug variable
  debug:
    var: my_variable
    verbosity: 2

- name: Debug message
  debug:
    msg: "Current value: {{ my_variable }}"
```

#### Register and Display Results

```yaml
- name: Run command
  command: ls -la /opt
  register: command_result

- name: Show command output
  debug:
    var: command_result.stdout_lines
```

---

## 📝 Checkpoint Quiz

Test your understanding of Ansible with Packer:

### Question 1: Ansible Provisioner Basics
**Which Packer provisioner option specifies the Ansible playbook to run?**

A) `ansible_file`  
B) `playbook_file`  
C) `playbook_path`  
D) `ansible_playbook`

<details>
<summary>Click to reveal answer</summary>

**Answer: B) `playbook_file`**

Explanation: The `playbook_file` option specifies the path to the Ansible playbook that Packer should execute during the provisioning phase.

```hcl
provisioner "ansible" {
  playbook_file = "playbook.yml"
}
```
</details>

---

### Question 2: Idempotency
**Which approach is idempotent for adding a line to a file?**

A) `shell: echo "line" >> file.txt`  
B) `command: echo "line" >> file.txt`  
C) `lineinfile` module  
D) `raw: echo "line" >> file.txt`

<details>
<summary>Click to reveal answer</summary>

**Answer: C) `lineinfile` module**

Explanation: The `lineinfile` module is idempotent - it checks if the line exists before adding it. Shell commands with `>>` will append the line every time they run.

```yaml
# Idempotent approach
- name: Add line to file
  lineinfile:
    path: /etc/file.txt
    line: 'my line'
    state: present
```
</details>

---

### Question 3: Ansible Roles
**What is the correct directory structure for an Ansible role named "webserver"?**

A) `webserver/main.yml`  
B) `roles/webserver/tasks/main.yml`  
C) `ansible/webserver/tasks.yml`  
D) `playbooks/webserver/main.yml`

<details>
<summary>Click to reveal answer</summary>

**Answer: B) `roles/webserver/tasks/main.yml`**

Explanation: Ansible roles follow a specific directory structure. The main tasks file for a role must be at `roles/<role_name>/tasks/main.yml`.

```
roles/
└── webserver/
    ├── tasks/
    │   └── main.yml
    ├── handlers/
    │   └── main.yml
    └── templates/
```
</details>

---

### Question 4: Privilege Escalation
**How do you enable sudo for Ansible tasks in Packer?**

A) Add `sudo: yes` to each task  
B) Use `use_sudo = true` in provisioner  
C) Set `become: yes` in playbook  
D) Both B and C

<details>
<summary>Click to reveal answer</summary>

**Answer: D) Both B and C**

Explanation: You can enable sudo either in the Packer provisioner configuration or in the Ansible playbook itself.

```hcl
# Method 1: Packer provisioner
provisioner "ansible" {
  playbook_file = "playbook.yml"
  use_sudo = true
}
```

```yaml
# Method 2: Ansible playbook
- name: Configure system
  hosts: all
  become: yes  # Enable sudo
  tasks:
    # ... tasks ...
```
</details>

---

### Question 5: Error Handling
**What does `failed_when: false` do in an Ansible task?**

A) Prevents the task from running  
B) Ignores all errors  
C) Prevents task failure from stopping the playbook  
D) Retries the task on failure

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Prevents task failure from stopping the playbook**

Explanation: `failed_when: false` tells Ansible to never consider the task as failed, allowing the playbook to continue even if the task returns a non-zero exit code.

```yaml
- name: Try to stop service (may not exist)
  systemd:
    name: myapp
    state: stopped
  failed_when: false  # Don't fail if service doesn't exist
```
</details>

---

### Question 6: Ansible Galaxy
**How do you use Ansible Galaxy roles in Packer?**

A) Install roles manually before running Packer  
B) Use `galaxy_file` option in provisioner  
C) Roles are automatically downloaded  
D) Galaxy roles can't be used with Packer

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Use `galaxy_file` option in provisioner**

Explanation: Packer can automatically install Ansible Galaxy roles by specifying a requirements file with the `galaxy_file` option.

```hcl
provisioner "ansible" {
  playbook_file = "playbook.yml"
  galaxy_file   = "requirements.yml"
  roles_path    = "roles"
}
```

```yaml
# requirements.yml
---
roles:
  - name: geerlingguy.nginx
    version: 3.1.4
```
</details>

---

## 📚 Additional Resources

### Official Documentation
- [Packer Ansible Provisioner](https://www.packer.io/docs/provisioners/ansible)
- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

### Ansible Galaxy
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Popular Roles](https://galaxy.ansible.com/search?order_by=-download_count)

### Learning Resources
- [Ansible for DevOps](https://www.ansiblefordevops.com/)
- [Ansible Examples](https://github.com/ansible/ansible-examples)
- [Packer Examples](https://github.com/hashicorp/packer/tree/main/examples)

### Community
- [Ansible Community](https://www.ansible.com/community)
- [Packer Community](https://discuss.hashicorp.com/c/packer)
- [r/ansible](https://www.reddit.com/r/ansible/)

---

## 🎯 Next Steps

After completing PKR-103, you should:

1. **Practice**: Build several images with different configurations
2. **Explore**: Try community roles from Ansible Galaxy
3. **Advance**: Move to PKR-104 for image versioning and HCP Packer
4. **Apply**: Use these skills in real projects

### Continue Your Journey

- **Next Course**: [PKR-104: Image Versioning & HCP Packer](../PKR-104-versioning-hcp/README.md)
- **Related**: [TF-103: Infrastructure Resources](../../TF-100-fundamentals/TF-103-infrastructure/README.md)
- **Advanced**: [TF-201: Module Design](../../TF-200-modules/TF-201-module-design/README.md)

---

## 📋 Course Completion Checklist

- [ ] Understand Ansible provisioner configuration
- [ ] Write basic Ansible playbooks
- [ ] Use Ansible modules effectively
- [ ] Create and use Ansible roles
- [ ] Implement complex configurations
- [ ] Complete all three hands-on labs
- [ ] Pass the checkpoint quiz
- [ ] Build at least one production-ready image

**Congratulations on completing PKR-103! You now have the skills to create sophisticated VM images using Ansible with Packer.** 🎉

---

*Part of the [Hashi-Training](../../README.md) curriculum - A comprehensive, hands-on training program for mastering Infrastructure as Code.*

---

## 📚 Supplemental Content

| Topic | Description | Directory |
|-------|-------------|-----------|
| [Packer Variables & Var-Files](packer-variables/README.md) | Variable declaration, var-files, sensitive values, locals | `packer-variables/` |

### What You've Learned (Updated)

In addition to the core Ansible content above, the supplemental section covers:

- ✅ **Variables**: Declare and use typed variables in Packer templates
- ✅ **Var-files**: Separate environment-specific values into `.pkrvars.hcl` files
- ✅ **Locals**: Compute derived values (timestamps, image names) from variables
- ✅ **Sensitive variables**: Prevent secrets from appearing in logs
- ✅ **Precedence**: CLI > var-file > auto-file > env var > default
