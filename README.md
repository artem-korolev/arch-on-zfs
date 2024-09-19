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

## Contribute

### Install GPT engineer

```bash
python3 -m venv venv
source venv/bin/activate
pip install gpt-engineer
```
