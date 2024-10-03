# Developer machine setup automation

<!-- TOC tocDepth:2..4 chapterDepth:2..6 -->

- [Run Ansible project](#run-ansible-project)
  - [Workstation](#workstation)
  - [Update AWS CLI tools](#update-aws-cli-tools)
  - [Power management](#power-management)
    - [Check for hibernate support](#check-for-hibernate-support)
    - [Secure Boot and kernel lockdown](#secure-boot-and-kernel-lockdown)
    - [Configure power management (Hibernate or alternative solution)](#configure-power-management-hibernate-or-alternative-solution)
    - [Shutdown on critical battery power with upower (when Hibernate is unavailable)](#shutdown-on-critical-battery-power-with-upower-when-hibernate-is-unavailable)
- [Contribute](#contribute)
  - [Install GPT engineer](#install-gpt-engineer)

<!-- /TOC -->

## Run Ansible project

Run everything as root

```bash
apt install ansible-core
```

### Workstation

```bash
ansible-playbook playbooks/workstation.yml
```

### Update AWS CLI tools

```bash
ansible-playbook playbooks/update_awscli.yml
```

### Power management

Sleep mode is working just perfect in all Linux systems usually, so there is
no reason to configure anything related to this one. But you may have a problem
setting up Hibernate. And configuring power management can be complex in general
and it takes significant time.

I want to have slightly different setups for laptops and workstations PC.
For a workstations I want to have so called hybrid sleep, when system goes
into Sleep and Hibernate at same time, so when power is lost accidentally,
it will be restored from Hibernate, otherwise it wakes up quick using Sleep.

And for laptops I do not need hybrid sleep. Workstation can have a separate SDD
for swap partitions, so I do not care much about SDD drive life, which is not
true for laptops, and laptops usually have batteries, so accidental loss of
power working slightly different for them. So for laptops I want this kind of
behavior: wake up system from sleep mode, when battery is on critical level and
immediately put machine into Hibernate mode.

For all of that I creates a separate ansible playbook
`playbooks/configure_power.yml`

There are few notes, before you start running anything, it is better to
ensure, that you will achieve expectable result. So start reading first.

It is highly possible, that you might want to reinstall your system
in order to get good defaults, if you do not configure BIOS properly before
installation. My suggestion is to experiment with different installation
options / bios settings and figure out the best fit for you. Of course
it is possible to reconfigure everything in already installed system.
It is just matter of time and expertise level. Sometimes its easier
to reinstall, especially when you have automated provisioning and configuration
management for your system like this project, for example.

#### Check for hibernate support

I do the same in my ansible playbook

```bash
root# cat /sys/power/state

Output:
freeze mem disk
```

If you see **disk** in `/sys/power/state`, then you for sure have hibernate
support in your kernel and it can be (or already is) enabled in your system.

#### Secure Boot and kernel lockdown

If **disk** is actually missing in `/sys/power/state`, then most probably
kernel locks it down, because of Secure Boot. Or maybe you just do not have
S4 support in your ACPI hardware. First of all - its not critical, I do provide
alternative power management setup for such system in my Ansible project.

I use Ubuntu Studio 24.04 on ZFS with encryption. And its kernel locks down
hibernate feature, whenever Secure Boot is enabled in BIOS.

So, if you have it enabled, then disable it, if you want hibernate work for
you.

Maybe your kernel do not lock down hibernate feature even with Secure Boot
enabled in the system, then just no worries and continue with setting it up.

#### Configure power management (Hibernate or alternative solution)

Now, when you know your system

```bash
ansible-playbook playbooks/configure_power.yml
```

#### Shutdown on critical battery power with upower (when Hibernate is unavailable)

I created a small service that runs every 10 seconds and checks
Since we are now logging directly to systemd via journalctl, you can use the following command to tail the service logs in real-time:

bash
Copy code
journalctl -u shutdown-on-critical-battery.service -f
This will show the log output for the shutdown-on-critical-battery.service and continuously update in real-time (like tail -f).

If you want to include logs from the current boot only, you can add the -b option:

bash
Copy code
journalctl -u shutdown-on-critical-battery.service -b -f
This will limit the output to logs from the current boot and follow the output in real-time.

## Contribute

### Install GPT engineer

```bash
python3 -m venv venv
source venv/bin/activate
pip install gpt-engineer
```
