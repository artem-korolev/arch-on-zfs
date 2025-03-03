<!-- markdownlint-disable MD033 MD041 -->
<p align="center">
  <img src="logo.webp" alt="WorkstationForge">
</p>
<!-- markdownlint-enable MD033 MD041 -->

# Workstation Forge

<!-- TOC tocDepth:2..3 chapterDepth:2..6 -->

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Linting and Code Quality](#linting-and-code-quality)
- [Usage](#usage)
- [Contributing](#contributing)
- [Roadmap](#roadmap)
- [License](#license)
- [Acknowledgments](#acknowledgments)

<!-- /TOC -->

Originally developed and rigorously tested on **Ubuntu Studio 24.04** — which enhances its capabilities with creative studio software and specific system configurations — the project also offers quality support for Fedora (tested on Workstation 41). Note that while Ubuntu Studio delivers a comprehensive suite of creative tools, Fedora currently includes a more limited selection. A separate playbook is provided for creative studio installations, and plans are underway to replicate the full Ubuntu Studio setup on Fedora/OpenSUSE in future releases.

## Overview

Workstation Forge leverages a modular structure based on Ansible roles and playbooks, ensuring a highly scalable, maintainable, and adaptable environment. Key features include:

- **Versatile Development Environment:**
  Set up a workstation optimized for programming, debugging, and profiling with support for technologies including C/C++, Clang, Bazel, CMake, Meson, Python, Java, Node.js, and Rust.

- **Scientific Publishing Ready:**
  In addition to development tools, the workstation is configured to support scientific publishing workflows—featuring LaTeX, TexStudio, and complementary applications to create and edit scholarly articles and books.

- **Multi-Distribution Support:**
  Developed and extensively tested on Ubuntu Studio 24.04, the project also supports Fedora (tested on Workstation 41). _Note:_ Fedora currently offers a limited range of creative studio tools compared to Ubuntu Studio, with plans to expand this support in future playbooks.

- **Modular and Idempotent Design:**
  Each role focuses on a specific area (e.g., development tools, system security, power management), ensuring that the playbooks remain idempotent and robust across repeated executions.

- **Linting and Code Quality:**
  The project integrates [Trunk.io](https://docs.trunk.io) for linting and static analysis. A dedicated `.trunk/config.yaml` file sets up various linters (ansible-lint, checkov, markdownlint, shellcheck, shfmt, and more) to maintain high code quality.

## Project Structure

```bash
├── playbooks/
│ ├── workstation.yml # Main playbook to initialize and configure the workstation
│ ├── configure_power_management.yml
│ ├── secure_workstation.yml
│ ├── creative_studio.yml # Playbook for installing creative studio tools (Ubuntu Studio has all of this and much more)
│ └── ... # Other orchestration playbooks
├── roles/
│ ├── awscli/ # AWS CLI and SAM CLI installation and updates
│ ├── bazel/ # Bazel and related tooling installation
│ ├── docker/ # Docker installation and configuration
│ ├── nvidia_driver/ # NVIDIA driver installation for various distros
│ ├── security_audit/ # Security tools and hardening measures
│ ├── creative_studio/ # Creative studio applications (extensive on Ubuntu Studio)
│ ├── development/ # Development tools for C/C++, Clang, CMake, Meson, Python, Java, Node.js, Rust
│ ├── power_management/ # Hibernate and power management configuration
│ ├── users/ # User creation and configuration
│ └── ... # Additional roles (e.g., VPN, math, neovim, etc.)
├── group_vars/
│ └── all.yml # Common variables used across playbooks and roles
│ └── fedora.yml # Fedora specific variables
│ └── ubuntu.yml # Ubuntu specific variables
│ └── ... # other distribution specific variables
├── .trunk/config.yaml # Trunk.io configuration for linting and formatting
└── README.md # Project overview and documentation
```

## Getting Started

### Prerequisites

- **Ansible:** Version 2.9 or higher is recommended.
- **Python:** Python 3.x should be installed on your control node.
- **Trunk.io:** For linting and static analysis, ensure you have [Trunk](https://docs.trunk.io/cli) installed.
- **Target Systems:** A supported Linux distribution such as Ubuntu Studio 24.04 or Fedora Workstation 41.

### Installation

1. **Clone the Repository:**

   ```bash
   git clone <https://github.com/artem-korolev/workstation_forge.git>
   cd workstation-forge
   ```

2. **Review and Customize Variables:**

   Update the variables in `group_vars/all.yml` (and any distribution-specific files) to suit your environment and preferences.

3. **Run the Main Playbook:**

   Execute the main playbook to initialize and configure your workstation:

   ```bash
   ansible-playbook playbooks/workstation.yml
   ```

   _Note: Adjust the inventory as needed if deploying to remote hosts._

### Linting and Code Quality

Workstation Forge uses [Trunk.io](https://docs.trunk.io) for linting and static code analysis. The configuration is defined in `.trunk/config.yaml`, which includes settings for various tools:

- **Linters Enabled:**
  ansible-lint, checkov, git-diff-check, markdownlint, prettier, shellcheck, shfmt, trufflehog, yamllint

- **Runtimes Configured:**
  go, node, and python

To run linting checks, simply execute:

```bash
trunk_io check -a
```

This will ensure your code adheres to best practices and helps catch issues early.

## Usage

Workstation Forge is designed to be modular. You can run specific playbooks or roles for targeted tasks. For example, to run the security audit:

To install full set of software and configure workstation to be secure:

```bash
ansible-playbook playbooks/workstation.yml
```

Or use specific playbooks for your needs:

```bash
ansible-playbook playbooks/security_audit.yml
```

Refer to the inline documentation within each role for additional details on usage and customization.

Each role have its own tag, so if you want to install only particular application run it like this (this is helpful, when you test or add new roles; that way you can run specific roles):

```bash
ansible-playbook playbooks/workstation_software.yml --tags "vscode"
```

## Contributing

Contributions are welcome! If you would like to add new features, fix bugs, or improve documentation, please follow these guidelines:

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Ensure your changes follow the established style and conventions.
4. Submit a pull request with a detailed description of your changes.

For major changes, please open an issue first to discuss what you would like to change.

## Roadmap

Planned improvements and future enhancements include:

- **Refactoring Common Tasks:**
  Consolidate repeated operations (e.g., repository and key management) into shared modules or roles.
- **Enhanced Documentation:**
  Adding detailed README files to individual roles and expanding inline comments for easier maintenance.

- **Automated Testing:**
  Integrating testing frameworks such as Molecule to ensure quality and reliability.

- **Dynamic Configuration:**
  Externalizing version numbers and URLs to central configuration files to ease updates.

- **Expanding Creative Studio Support:**
  Fedora currently offers a limited range of creative studio tools compared to Ubuntu Studio. A dedicated playbook to replicate the full Ubuntu Studio creative setup on Fedora/OpenSUSE is planned as a future enhancement.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgments

Thanks to the community and contributors for providing insights and best practices that helped shape this project. Special thanks to the Ansible and Trunk.io communities for their excellent documentation and tools that keep our project robust and maintainable.
