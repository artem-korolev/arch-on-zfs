# Workstation setup

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

### Hibernate

IT DOES NOT WORK YET AS WAS PLANNED. Automatic hibernate on low battery,
resuming back from sleep to protect from accidental power off.

Tasks are here, but they make not sense right now. DON'T RUN IT:

```bash
ansible-playbook playbooks/setup_hibernate.yml
```

## Contribute

### Install GPT engineer

```bash
python3 -m venv venv
source venv/bin/activate
pip install gpt-engineer
```
