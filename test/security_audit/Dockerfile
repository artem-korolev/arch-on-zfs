# trunk-ignore-all(checkov/CKV_DOCKER_2)
# trunk-ignore-all(checkov/CKV_DOCKER_7)
# trunk-ignore-all(checkov/CKV_DOCKER_9)
# trunk-ignore-all(checkov/CKV_DOCKER_3)
FROM kalilinux/kali-rolling:latest

# Install nmap and iputils-ping
RUN apt update && \
    apt install -y nmap iputils-ping iproute2 && \
    apt clean

# Set default command to bash
CMD ["/bin/bash"]
