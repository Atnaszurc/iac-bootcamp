# PKR-104: Image Versioning & HCP Packer

**Course**: PKR-100 Packer Fundamentals  
**Module**: PKR-104  
**Duration**: 0.5 hours  
**Prerequisites**: PKR-101, PKR-102, PKR-103  
**Difficulty**: Intermediate

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [Why Version Your Images?](#why-version-your-images)
4. [Image Versioning Strategies](#image-versioning-strategies)
5. [Metadata and Tagging](#metadata-and-tagging)
6. [Image Lifecycle Management](#image-lifecycle-management)
7. [HCP Packer Overview](#hcp-packer-overview)
8. [Best Practices](#best-practices)
9. [Hands-On Labs](#hands-on-labs)
10. [Troubleshooting](#troubleshooting)
11. [Checkpoint Quiz](#checkpoint-quiz)
12. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This course teaches you how to version, tag, and manage VM images throughout their lifecycle. You'll learn strategies for tracking image versions, implementing semantic versioning, and get an overview of HCP Packer for enterprise image management.

### What You'll Learn

By the end of this course, you'll be able to:
- Implement image versioning strategies
- Use metadata and tags effectively
- Track image lineage and dependencies
- Manage image lifecycle (build, test, promote, deprecate)
- Understand HCP Packer capabilities
- Implement automated versioning in CI/CD

### Course Structure

```
PKR-104-versioning-hcp/
├── README.md                          # This file
├── example/
│   ├── 01-basic-versioning/           # Simple versioning
│   │   ├── template.pkr.hcl
│   │   └── version.sh
│   ├── 02-semantic-versioning/        # SemVer implementation
│   │   ├── template.pkr.hcl
│   │   └── version-manager.sh
│   ├── 03-metadata-tagging/           # Rich metadata
│   │   ├── template.pkr.hcl
│   │   └── metadata.json
│   └── 04-lifecycle-management/       # Complete lifecycle
│       ├── template.pkr.hcl
│       ├── build.sh
│       └── promote.sh
└── labs/
    ├── lab1-versioning-basics.md
    ├── lab2-automated-versioning.md
    └── lab3-lifecycle-pipeline.md
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Implement Versioning**
   - Choose appropriate versioning schemes
   - Implement semantic versioning
   - Automate version generation

2. **Use Metadata and Tags**
   - Add meaningful metadata to images
   - Implement tagging strategies
   - Track build information

3. **Manage Image Lifecycle**
   - Track image stages (dev, test, prod)
   - Implement promotion workflows
   - Deprecate and retire old images

4. **Understand HCP Packer**
   - Learn HCP Packer capabilities
   - Understand image registry concepts
   - Plan for enterprise adoption

5. **Automate Versioning**
   - Integrate with CI/CD pipelines
   - Automate version bumping
   - Generate changelogs

---

## 🤔 Why Version Your Images?

### The Problem Without Versioning

Imagine this scenario:
```bash
# Which image should I use?
ubuntu-web-server.qcow2
ubuntu-web-server-new.qcow2
ubuntu-web-server-final.qcow2
ubuntu-web-server-final-v2.qcow2
ubuntu-web-server-really-final.qcow2
```

**Problems**:
- ❌ Can't tell which is newest
- ❌ No change history
- ❌ Can't rollback safely
- ❌ No audit trail
- ❌ Team confusion

### The Solution: Proper Versioning

```bash
# Clear, trackable versions
ubuntu-web-server-1.0.0.qcow2  # Initial release
ubuntu-web-server-1.1.0.qcow2  # Added monitoring
ubuntu-web-server-1.1.1.qcow2  # Security patch
ubuntu-web-server-2.0.0.qcow2  # Major update
```

**Benefits**:
- ✅ Clear version progression
- ✅ Documented changes
- ✅ Safe rollback capability
- ✅ Compliance and auditing
- ✅ Team coordination

### Real-World Benefits

#### 1. **Traceability**
Know exactly what's in each image:
```
Version 1.2.3:
- Ubuntu 22.04.3
- Nginx 1.24.0
- Security patches: CVE-2023-1234, CVE-2023-5678
- Built: 2024-01-15 14:30 UTC
- Built by: CI/CD Pipeline
- Git commit: abc123def
```

#### 2. **Rollback Capability**
```bash
# Production issue? Roll back safely
terraform apply -var="image_version=1.2.2"  # Previous stable version
```

#### 3. **Testing and Promotion**
```
Build → Test (v1.3.0-dev) → Stage (v1.3.0-rc1) → Production (v1.3.0)
```

#### 4. **Compliance**
```
Audit Question: "What was running on 2024-01-15?"
Answer: "Image version 1.2.3, built from commit abc123"
```

---

## 📊 Image Versioning Strategies

### 1. Semantic Versioning (SemVer)

**Format**: `MAJOR.MINOR.PATCH`

```
1.0.0 → 1.0.1 → 1.1.0 → 2.0.0
```

**Rules**:
- **MAJOR**: Breaking changes (e.g., OS upgrade, major software changes)
- **MINOR**: New features, backward compatible (e.g., new packages)
- **PATCH**: Bug fixes, security patches (e.g., CVE fixes)

**Example**:
```hcl
# template.pkr.hcl
locals {
  version = "1.2.3"
  image_name = "ubuntu-web-${local.version}"
}

source "qemu" "ubuntu" {
  vm_name = "${local.image_name}.qcow2"
  
  # Add version to metadata
  qemuargs = [
    ["-smbios", "type=1,version=${local.version}"]
  ]
}
```

### 2. Date-Based Versioning

**Format**: `YYYY.MM.DD` or `YYYYMMDD`

```
2024.01.15 → 2024.01.16 → 2024.02.01
```

**Best for**:
- Regular scheduled builds
- Snapshot-based images
- Time-sensitive compliance

**Example**:
```hcl
locals {
  version = formatdate("YYYY.MM.DD", timestamp())
  image_name = "ubuntu-web-${local.version}"
}
```

### 3. Git-Based Versioning

**Format**: `git-commit-short` or `branch-commit`

```
main-abc123f
develop-def456a
v1.2.3-abc123f
```

**Best for**:
- Development images
- Tracking source code
- CI/CD integration

**Example**:
```hcl
locals {
  git_commit = substr(var.git_commit, 0, 7)
  git_branch = var.git_branch
  version = "${local.git_branch}-${local.git_commit}"
  image_name = "ubuntu-web-${local.version}"
}
```

### 4. Hybrid Versioning

**Format**: `MAJOR.MINOR.PATCH-metadata+build`

```
1.2.3-dev+20240115
1.2.3-rc1+abc123
1.2.3+20240115.abc123
```

**Best for**:
- Complex environments
- Multiple stages (dev, test, prod)
- Maximum traceability

**Example**:
```hcl
locals {
  semver = "1.2.3"
  stage = var.environment  # dev, test, prod
  build_date = formatdate("YYYYMMDD", timestamp())
  git_commit = substr(var.git_commit, 0, 7)
  
  version = "${local.semver}-${local.stage}+${local.build_date}.${local.git_commit}"
  image_name = "ubuntu-web-${local.version}"
}
```

### Comparison Table

| Strategy | Pros | Cons | Best For |
|----------|------|------|----------|
| **SemVer** | Clear meaning, industry standard | Manual version bumping | Production images |
| **Date-Based** | Automatic, chronological | No semantic meaning | Scheduled builds |
| **Git-Based** | Traceable to code | Not human-friendly | Development |
| **Hybrid** | Maximum information | Complex | Enterprise |

---

## 🏷️ Metadata and Tagging

### Why Metadata Matters

Metadata provides context about your images:
- **What**: Software versions, configurations
- **When**: Build date, timestamps
- **Who**: Builder, approver
- **Why**: Purpose, changelog
- **How**: Build process, source

### Adding Metadata to Images

#### 1. **Filename Metadata**

```hcl
locals {
  version = "1.2.3"
  os = "ubuntu-22.04"
  arch = "amd64"
  
  image_name = "${local.os}-${local.arch}-${local.version}.qcow2"
  # Result: ubuntu-22.04-amd64-1.2.3.qcow2
}
```

#### 2. **QEMU SMBIOS Metadata**

Embed metadata in the VM's SMBIOS:

```hcl
source "qemu" "ubuntu" {
  vm_name = "ubuntu-web-${local.version}.qcow2"
  
  qemuargs = [
    # System information
    ["-smbios", "type=1,manufacturer=MyCompany"],
    ["-smbios", "type=1,product=WebServer"],
    ["-smbios", "type=1,version=${local.version}"],
    ["-smbios", "type=1,serial=${local.build_id}"]
  ]
}
```

Read metadata from running VM:
```bash
sudo dmidecode -t system
```

#### 3. **File-Based Metadata**

Create metadata files in the image:

```hcl
provisioner "file" {
  content = jsonencode({
    version = local.version
    build_date = timestamp()
    git_commit = var.git_commit
    builder = "packer"
    os = "Ubuntu 22.04"
    packages = {
      nginx = "1.24.0"
      postgresql = "14.9"
    }
  })
  destination = "/etc/image-metadata.json"
}
```

#### 4. **Manifest Files**

Packer can generate manifest files:

```hcl
post-processor "manifest" {
  output = "manifest.json"
  strip_path = true
  custom_data = {
    version = local.version
    build_date = timestamp()
    git_commit = var.git_commit
    environment = var.environment
  }
}
```

Generated `manifest.json`:
```json
{
  "builds": [
    {
      "name": "ubuntu",
      "builder_type": "qemu",
      "build_time": 1705329600,
      "files": [
        {
          "name": "ubuntu-web-1.2.3.qcow2",
          "size": 2147483648
        }
      ],
      "artifact_id": "qemu:ubuntu-web-1.2.3.qcow2",
      "packer_run_uuid": "abc-123-def",
      "custom_data": {
        "version": "1.2.3",
        "build_date": "2024-01-15T14:30:00Z",
        "git_commit": "abc123def",
        "environment": "production"
      }
    }
  ],
  "last_run_uuid": "abc-123-def"
}
```

### Tagging Strategies

#### Environment Tags
```hcl
locals {
  tags = {
    Environment = var.environment  # dev, test, prod
    Version = local.version
    ManagedBy = "Packer"
  }
}
```

#### Lifecycle Tags
```hcl
locals {
  tags = {
    Status = "active"  # active, deprecated, retired
    Stage = "production"  # dev, staging, production
    Promoted = "2024-01-15"
  }
}
```

#### Compliance Tags
```hcl
locals {
  tags = {
    Compliance = "PCI-DSS"
    SecurityScan = "passed"
    LastPatched = "2024-01-15"
    CVEsFixed = "CVE-2023-1234,CVE-2023-5678"
  }
}
```

---

## 🔄 Image Lifecycle Management

### Image Lifecycle Stages

```
┌─────────┐    ┌──────────┐    ┌─────────┐    ┌────────────┐
│  Build  │ -> │   Test   │ -> │  Stage  │ -> │ Production │
└─────────┘    └──────────┘    └─────────┘    └────────────┘
     │              │               │                │
     v              v               v                v
  v1.0.0-dev   v1.0.0-test    v1.0.0-rc1        v1.0.0
```

### 1. Build Stage

Initial image creation:

```hcl
# template.pkr.hcl
variable "environment" {
  type = string
  default = "dev"
}

locals {
  version = "1.0.0"
  stage_suffix = var.environment == "prod" ? "" : "-${var.environment}"
  full_version = "${local.version}${local.stage_suffix}"
  
  image_name = "ubuntu-web-${local.full_version}"
}

source "qemu" "ubuntu" {
  vm_name = "${local.image_name}.qcow2"
  output_directory = "output/${var.environment}"
}

build {
  sources = ["source.qemu.ubuntu"]
  
  provisioner "shell" {
    inline = [
      "echo 'Version: ${local.full_version}' | sudo tee /etc/image-version",
      "echo 'Stage: ${var.environment}' | sudo tee -a /etc/image-version",
      "echo 'Built: ${timestamp()}' | sudo tee -a /etc/image-version"
    ]
  }
}
```

### 2. Test Stage

Automated testing:

```bash
#!/bin/bash
# test-image.sh

IMAGE_VERSION="1.0.0-test"
IMAGE_FILE="output/test/ubuntu-web-${IMAGE_VERSION}.qcow2"

echo "Testing image: ${IMAGE_FILE}"

# Start VM for testing
qemu-system-x86_64 \
  -drive file="${IMAGE_FILE}",format=qcow2 \
  -m 2048 \
  -nographic \
  -daemonize

# Wait for boot
sleep 30

# Run tests
echo "Running smoke tests..."
# Add your tests here

# Cleanup
pkill qemu-system-x86_64

echo "Tests passed! Image ready for staging."
```

### 3. Promotion Workflow

Promote tested images:

```bash
#!/bin/bash
# promote-image.sh

SOURCE_VERSION="1.0.0-test"
TARGET_VERSION="1.0.0-rc1"

SOURCE_FILE="output/test/ubuntu-web-${SOURCE_VERSION}.qcow2"
TARGET_FILE="output/staging/ubuntu-web-${TARGET_VERSION}.qcow2"

echo "Promoting ${SOURCE_VERSION} to ${TARGET_VERSION}"

# Copy image
cp "${SOURCE_FILE}" "${TARGET_FILE}"

# Update metadata
echo "Promoted from: ${SOURCE_VERSION}" >> metadata.txt
echo "Promoted to: ${TARGET_VERSION}" >> metadata.txt
echo "Promoted at: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> metadata.txt

echo "Promotion complete!"
```

### 4. Production Release

Final production release:

```bash
#!/bin/bash
# release-to-production.sh

RC_VERSION="1.0.0-rc1"
PROD_VERSION="1.0.0"

RC_FILE="output/staging/ubuntu-web-${RC_VERSION}.qcow2"
PROD_FILE="output/production/ubuntu-web-${PROD_VERSION}.qcow2"

echo "Releasing ${RC_VERSION} to production as ${PROD_VERSION}"

# Copy to production
cp "${RC_FILE}" "${PROD_FILE}"

# Create release notes
cat > "releases/${PROD_VERSION}.md" <<EOF
# Release ${PROD_VERSION}

**Release Date**: $(date -u +%Y-%m-%d)
**Source**: ${RC_VERSION}

## Changes
- Initial production release
- All tests passed
- Security scan: PASSED

## Deployment
\`\`\`bash
# Use this image in Terraform
image_version = "${PROD_VERSION}"
\`\`\`
EOF

echo "Production release complete!"
```

### 5. Deprecation and Retirement

Mark old images as deprecated:

```bash
#!/bin/bash
# deprecate-image.sh

OLD_VERSION="0.9.0"
REPLACEMENT_VERSION="1.0.0"

echo "Deprecating version ${OLD_VERSION}"
echo "Replacement: ${REPLACEMENT_VERSION}"

# Create deprecation notice
cat > "output/production/ubuntu-web-${OLD_VERSION}.DEPRECATED" <<EOF
DEPRECATED: This image version is no longer supported.

Deprecated on: $(date -u +%Y-%m-%d)
Reason: Superseded by ${REPLACEMENT_VERSION}
End of Life: $(date -u -d '+90 days' +%Y-%m-%d)

Please migrate to version ${REPLACEMENT_VERSION}
EOF

echo "Deprecation notice created"
```

### Complete Lifecycle Script

```bash
#!/bin/bash
# image-lifecycle.sh

set -e

VERSION="1.0.0"

# 1. Build development image
echo "=== Building development image ==="
packer build -var="environment=dev" template.pkr.hcl

# 2. Test the image
echo "=== Testing image ==="
./test-image.sh "${VERSION}-dev"

# 3. Promote to staging
echo "=== Promoting to staging ==="
./promote-image.sh "${VERSION}-dev" "${VERSION}-rc1"

# 4. Run staging tests
echo "=== Running staging tests ==="
./test-image.sh "${VERSION}-rc1"

# 5. Release to production
echo "=== Releasing to production ==="
./release-to-production.sh "${VERSION}-rc1" "${VERSION}"

# 6. Tag in git
echo "=== Tagging release ==="
git tag -a "v${VERSION}" -m "Release version ${VERSION}"
git push origin "v${VERSION}"

echo "=== Lifecycle complete ==="
```

---

## ☁️ HCP Packer Overview

### What is HCP Packer?

**HCP Packer** (HashiCorp Cloud Platform Packer) is a managed service for tracking and managing Packer images across their lifecycle.

### Key Features

#### 1. **Image Registry**
Central repository for all your images:
```
Organization: MyCompany
├── Bucket: ubuntu-web-server
│   ├── Version: 1.0.0 (production)
│   ├── Version: 1.1.0 (staging)
│   └── Version: 1.2.0-dev (development)
├── Bucket: ubuntu-database
│   └── Version: 2.0.0 (production)
└── Bucket: ubuntu-app-server
    └── Version: 3.1.0 (production)
```

#### 2. **Version Tracking**
Track all versions and their metadata:
- Build date and time
- Source code commit
- Builder information
- Artifacts produced
- Deployment status

#### 3. **Lineage and Dependencies**
Understand image relationships:
```
ubuntu-base:1.0.0
├── ubuntu-web:1.0.0
│   └── ubuntu-web-prod:1.0.0
└── ubuntu-app:1.0.0
    └── ubuntu-app-prod:1.0.0
```

#### 4. **Revocation**
Mark images as revoked (security issues):
```
ubuntu-web:1.0.0 [REVOKED]
Reason: CVE-2023-1234
Replacement: ubuntu-web:1.0.1
```

### HCP Packer Configuration

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

# HCP Packer configuration
build {
  # HCP Packer bucket name
  hcp_packer_registry {
    bucket_name = "ubuntu-web-server"
    description = "Ubuntu 22.04 with Nginx web server"
    
    bucket_labels = {
      "os" = "ubuntu"
      "version" = "22.04"
      "type" = "web-server"
    }
    
    build_labels = {
      "build-time" = timestamp()
      "git-commit" = var.git_commit
    }
  }
  
  sources = ["source.qemu.ubuntu"]
  
  # ... provisioners ...
}
```

### HCP Packer Benefits

#### For Development Teams
- ✅ Single source of truth for images
- ✅ Easy discovery of available images
- ✅ Clear version history
- ✅ Automated notifications

#### For Operations Teams
- ✅ Track what's deployed where
- ✅ Quick security response (revocation)
- ✅ Compliance reporting
- ✅ Audit trail

#### For Security Teams
- ✅ Vulnerability tracking
- ✅ Revocation capabilities
- ✅ Compliance verification
- ✅ Security scanning integration

### HCP Packer vs Local Management

| Feature | Local Management | HCP Packer |
|---------|------------------|------------|
| **Cost** | Free | Paid (free tier available) |
| **Setup** | Manual | Managed service |
| **Tracking** | Manual scripts | Automatic |
| **Collaboration** | File sharing | Built-in |
| **Revocation** | Manual process | One-click |
| **Reporting** | Custom scripts | Built-in dashboards |
| **Scale** | Limited | Enterprise-ready |

### When to Use HCP Packer

**Use HCP Packer if**:
- ✅ Multiple teams building images
- ✅ Need centralized tracking
- ✅ Compliance requirements
- ✅ Large-scale deployments
- ✅ Multi-cloud environments

**Stick with local if**:
- ✅ Small team or solo
- ✅ Simple workflows
- ✅ Budget constraints
- ✅ Learning/experimentation

### HCP Packer Alternatives

For those not using HCP Packer:

#### 1. **Git-Based Tracking**
```bash
# Store metadata in git
git tag -a v1.0.0 -m "Release 1.0.0"
echo "1.0.0" > VERSION
git add VERSION
git commit -m "Bump version to 1.0.0"
```

#### 2. **Artifact Repository**
- Artifactory
- Nexus
- Cloud storage (S3, Azure Blob)

#### 3. **Custom Database**
```sql
CREATE TABLE images (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255),
  version VARCHAR(50),
  build_date TIMESTAMP,
  git_commit VARCHAR(40),
  status VARCHAR(20)
);
```

---

## ✅ Best Practices

### 1. Version Naming Conventions

**DO**:
```
✅ ubuntu-web-1.0.0.qcow2
✅ ubuntu-web-1.0.0-dev.qcow2
✅ ubuntu-web-2024.01.15.qcow2
```

**DON'T**:
```
❌ ubuntu-web-new.qcow2
❌ ubuntu-web-final.qcow2
❌ ubuntu-web-v1-copy.qcow2
```

### 2. Semantic Versioning Rules

```
MAJOR.MINOR.PATCH

MAJOR: Breaking changes
- OS version upgrade (Ubuntu 20.04 → 22.04)
- Major software version (Nginx 1.x → 2.x)
- Configuration breaking changes

MINOR: New features
- New packages added
- New configurations
- Backward-compatible changes

PATCH: Bug fixes
- Security patches
- Bug fixes
- Minor updates
```

### 3. Metadata Standards

Always include:
```json
{
  "version": "1.0.0",
  "build_date": "2024-01-15T14:30:00Z",
  "git_commit": "abc123def",
  "builder": "packer",
  "os": {
    "name": "Ubuntu",
    "version": "22.04.3"
  },
  "packages": {
    "nginx": "1.24.0",
    "postgresql": "14.9"
  },
  "security": {
    "last_scan": "2024-01-15",
    "vulnerabilities": 0
  }
}
```

### 4. Changelog Maintenance

Keep a changelog:
```markdown
# Changelog

## [1.2.0] - 2024-01-15
### Added
- PostgreSQL 14.9
- Monitoring agent

### Changed
- Nginx upgraded to 1.24.0

### Fixed
- CVE-2023-1234
- CVE-2023-5678

## [1.1.0] - 2024-01-01
### Added
- Redis cache
```

### 5. Automated Version Bumping

```bash
#!/bin/bash
# bump-version.sh

CURRENT_VERSION=$(cat VERSION)
BUMP_TYPE=${1:-patch}  # major, minor, or patch

IFS='.' read -r -a version_parts <<< "$CURRENT_VERSION"
MAJOR="${version_parts[0]}"
MINOR="${version_parts[1]}"
PATCH="${version_parts[2]}"

case $BUMP_TYPE in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
echo "$NEW_VERSION" > VERSION
echo "Version bumped: ${CURRENT_VERSION} → ${NEW_VERSION}"
```

### 6. CI/CD Integration

```yaml
# .github/workflows/build-image.yml
name: Build Image

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Extract version
        id: version
        run: echo "VERSION=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT
      
      - name: Build image
        run: |
          packer build \
            -var="version=${{ steps.version.outputs.VERSION }}" \
            -var="git_commit=${{ github.sha }}" \
            template.pkr.hcl
      
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: image-${{ steps.version.outputs.VERSION }}
          path: output/*.qcow2
```

---

## 🔬 Hands-On Labs

### Lab 1: Basic Versioning (10 minutes)

**Objective**: Implement semantic versioning for a Packer image.

**Tasks**:
1. Create a VERSION file with "1.0.0"
2. Modify Packer template to read version from file
3. Include version in image name
4. Add version metadata to the image
5. Build the image
6. Verify version information

**Expected Output**:
- Image named with version (e.g., `ubuntu-web-1.0.0.qcow2`)
- Version metadata embedded in image
- VERSION file tracked in git

**Hints**:
- Use `file()` function to read VERSION file
- Use locals for version variable
- Add version to SMBIOS or metadata file

---

### Lab 2: Automated Versioning (15 minutes)

**Objective**: Create an automated versioning script integrated with git.

**Tasks**:
1. Create version bump script (major, minor, patch)
2. Integrate with git tagging
3. Automate version in Packer build
4. Generate changelog automatically
5. Test the complete workflow

**Expected Output**:
- Script that bumps version
- Git tags created automatically
- Changelog updated
- Image built with correct version

**Hints**:
- Parse VERSION file in bash
- Use `git tag` for versioning
- Generate changelog from git commits

---

### Lab 3: Lifecycle Pipeline (20 minutes)

**Objective**: Implement a complete image lifecycle pipeline.

**Tasks**:
1. Create build script for dev environment
2. Add testing stage
3. Implement promotion workflow
4. Create production release process
5. Add deprecation mechanism
6. Test complete pipeline

**Expected Output**:
- Images progress through stages (dev → test → staging → prod)
- Each stage has appropriate version suffix
- Metadata tracks promotion history
- Old versions can be deprecated

**Hints**:
- Use environment variable for stage
- Copy images between stages
- Track metadata in separate files
- Create deprecation notices

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Version Conflicts

**Problem**: Multiple images with same version

**Solution**:
```bash
# Add build number to version
VERSION="1.0.0"
BUILD_NUMBER="${CI_BUILD_NUMBER:-1}"
FULL_VERSION="${VERSION}+build.${BUILD_NUMBER}"
```

#### 2. Metadata Not Persisting

**Problem**: Metadata lost after image creation

**Solution**:
```hcl
# Write metadata to file in image
provisioner "shell" {
  inline = [
    "echo '${jsonencode(local.metadata)}' | sudo tee /etc/image-metadata.json"
  ]
}
```

#### 3. Version Parsing Errors

**Problem**: Script fails to parse version

**Solution**:
```bash
# Validate version format
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Invalid version format: $VERSION"
  echo "Expected: MAJOR.MINOR.PATCH (e.g., 1.0.0)"
  exit 1
fi
```

#### 4. Git Tag Conflicts

**Problem**: Tag already exists

**Solution**:
```bash
# Check if tag exists before creating
if git rev-parse "v${VERSION}" >/dev/null 2>&1; then
  echo "Error: Tag v${VERSION} already exists"
  exit 1
fi

git tag -a "v${VERSION}" -m "Release ${VERSION}"
```

### Debugging Tips

#### Verify Version in Image

```bash
# Method 1: Check filename
ls -lh output/*.qcow2

# Method 2: Check metadata file
virt-cat -a image.qcow2 /etc/image-metadata.json

# Method 3: Check SMBIOS
virt-cat -a image.qcow2 /sys/class/dmi/id/product_version
```

#### Validate Manifest

```bash
# Check manifest file
cat manifest.json | jq '.builds[0].custom_data'

# Verify version
VERSION=$(cat manifest.json | jq -r '.builds[0].custom_data.version')
echo "Built version: $VERSION"
```

---

## 📝 Checkpoint Quiz

Test your understanding of image versioning:

### Question 1: Semantic Versioning
**In semantic versioning (MAJOR.MINOR.PATCH), when should you increment the MAJOR version?**

A) When fixing bugs  
B) When adding new features  
C) When making breaking changes  
D) Every month

<details>
<summary>Click to reveal answer</summary>

**Answer: C) When making breaking changes**

Explanation: In semantic versioning, the MAJOR version is incremented when you make incompatible or breaking changes, such as upgrading the OS version (Ubuntu 20.04 → 22.04) or making configuration changes that aren't backward compatible.

```
1.0.0 → 2.0.0  # Breaking change (e.g., OS upgrade)
1.0.0 → 1.1.0  # New feature (backward compatible)
1.0.0 → 1.0.1  # Bug fix or patch
```
</details>

---

### Question 2: Version Formats
**Which version format is best for tracking images back to source code?**

A) Date-based (2024.01.15)  
B) Sequential (v1, v2, v3)  
C) Git-based (main-abc123f)  
D) Random (uuid)

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Git-based (main-abc123f)**

Explanation: Git-based versioning includes the git commit hash, making it easy to trace the image back to the exact source code that built it.

```hcl
locals {
  git_commit = substr(var.git_commit, 0, 7)
  version = "1.0.0-${local.git_commit}"
  # Result: 1.0.0-abc123f
}
```
</details>

---

### Question 3: Metadata Storage
**What is the most reliable way to store metadata in a VM image?**

A) In the filename only  
B) In a file inside the image  
C) In external documentation  
D) In the build logs

<details>
<summary>Click to reveal answer</summary>

**Answer: B) In a file inside the image**

Explanation: Storing metadata in a file inside the image (e.g., `/etc/image-metadata.json`) ensures it travels with the image and can be read from running VMs.

```hcl
provisioner "file" {
  content = jsonencode({
    version = local.version
    build_date = timestamp()
    git_commit = var.git_commit
  })
  destination = "/etc/image-metadata.json"
}
```
</details>

---

### Question 4: Image Lifecycle
**What is the correct order for image lifecycle stages?**

A) Production → Test → Development  
B) Development → Production → Test  
C) Development → Test → Production  
D) Test → Development → Production

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Development → Test → Production**

Explanation: Images should progress from development (build) to testing (validation) to production (deployment). This ensures quality and stability.

```
Build (dev) → Test → Staging (rc) → Production
v1.0.0-dev  → v1.0.0-test → v1.0.0-rc1 → v1.0.0
```
</details>

---

### Question 5: HCP Packer
**What is the primary benefit of HCP Packer?**

A) Faster image builds  
B) Centralized image tracking and management  
C) Automatic security patching  
D) Free image storage

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Centralized image tracking and management**

Explanation: HCP Packer provides a centralized registry for tracking all your images, their versions, metadata, and deployment status across your organization.

Key features:
- Image registry
- Version tracking
- Lineage and dependencies
- Revocation capabilities
- Compliance reporting
</details>

---

### Question 6: Version Bumping
**What does this command do: `1.2.3 → 1.3.0`?**

A) Major version bump  
B) Minor version bump  
C) Patch version bump  
D) Build number increment

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Minor version bump**

Explanation: This is a minor version bump (middle number incremented), which indicates a new feature or backward-compatible change. The patch version is reset to 0.

```bash
# Minor bump
MINOR=$((MINOR + 1))
PATCH=0
# 1.2.3 → 1.3.0
```
</details>

---

## 📚 Additional Resources

### Official Documentation
- [Packer Post-Processors](https://www.packer.io/docs/post-processors)
- [HCP Packer Documentation](https://developer.hashicorp.com/hcp/docs/packer)
- [Semantic Versioning](https://semver.org/)

### Tools
- [HCP Packer](https://cloud.hashicorp.com/products/packer)
- [Git Tagging](https://git-scm.com/book/en/v2/Git-Basics-Tagging)
- [jq - JSON processor](https://stedolan.github.io/jq/)

### Best Practices
- [Image Versioning Strategies](https://www.hashicorp.com/blog/image-versioning-strategies)
- [GitOps for Infrastructure](https://www.gitops.tech/)
- [Changelog Best Practices](https://keepachangelog.com/)

### Community
- [HCP Packer Community](https://discuss.hashicorp.com/c/hcp-packer)
- [Packer GitHub](https://github.com/hashicorp/packer)

---

## 🎯 Next Steps

Congratulations on completing PKR-104 and the entire PKR-100 series!

### What You've Learned

**PKR-100 Series Complete**:
- ✅ PKR-101: Introduction to Image Building
- ✅ PKR-102: QEMU Builder & Provisioners
- ✅ PKR-103: Ansible Configuration Management
- ✅ PKR-104: Image Versioning & HCP Packer

### Continue Your Journey

**Core Training**:
- **Completed**: All 16 core courses! 🎉
- **Next**: Optional cloud provider modules

**Optional Modules**:
- [AWS-200: AWS with Terraform](../../cloud-modules/AWS-200-terraform/README.md)
- [AZ-200: Azure with Terraform](../../cloud-modules/AZ-200-terraform/README.md)
- [MC-300: Multi-Cloud Architecture](../../cloud-modules/MC-300-multi-cloud/README.md)

**Apply Your Skills**:
1. Build production-ready images
2. Implement CI/CD pipelines
3. Integrate with Terraform
4. Contribute to the community

---

## 📋 Course Completion Checklist

- [ ] Understand versioning strategies
- [ ] Implement semantic versioning
- [ ] Add metadata and tags to images
- [ ] Manage image lifecycle
- [ ] Understand HCP Packer capabilities
- [ ] Complete all three hands-on labs
- [ ] Pass the checkpoint quiz
- [ ] Build a versioned image pipeline

**Congratulations on completing PKR-104 and the entire PKR-100 Packer Fundamentals course!** 🎉

You now have comprehensive skills in:
- Infrastructure as Code with Terraform
- Image building with Packer
- Configuration management with Ansible
- Testing and validation
- Policy enforcement
- Image versioning and lifecycle management

**You're ready for production!** 🚀

---

*Part of the [Hashi-Training](../../README.md) curriculum - A comprehensive, hands-on training program for mastering Infrastructure as Code.*