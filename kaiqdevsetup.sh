#!/bin/bash

GREEN='\e[1;32m'
WHITE='\e[1;37m'
NC='\e[0m' 

sudo apt update
sudo apt install figlet -y

echo -e "${WHITE}=================================================${NC}"
echo -e "${GREEN}$(figlet "KAIQ'S DEV ENVIRONMENT SETUP")${NC}"
echo -e "${WHITE}=================================================${NC}"

echo -e "${WHITE}Este script instala dependências e ferramentas comuns utilizadas em desenvolvimento, incluindo:
	- Docker
	- kubectl e Minikube
	- K9s
	- Visual Studio Code
	- Java 17

Você pode optar por instalar cada ferramenta individualmente.${NC}"

mkdir -p ~/dev/{k9s,vscode,java}

install_docker() {
    echo -e "${GREEN}>> Iniciando a instalação do Docker...${NC}"
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove -y $pkg; done

    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg

    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo groupadd docker
    sudo usermod -aG docker $USER

    echo -e "${GREEN}>> Docker instalado com sucesso.${NC}"
}

install_kubernetes_tools() {
    echo -e "${GREEN}>> Iniciando a instalação do kubectl e Minikube...${NC}"

    curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl

    curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64

    echo -e "${GREEN}>> kubectl e Minikube instalados com sucesso.${NC}"
}

install_k9s() {
    echo -e "${GREEN}>> Iniciando a instalação do K9s...${NC}"
    wget -O ~/dev/k9s/k9s.deb https://github.com/derailed/k9s/releases/download/v0.50.6/k9s_linux_amd64.deb
    sudo apt install -y ~/dev/k9s/k9s.deb
    echo -e "${GREEN}>> K9s instalado com sucesso.${NC}"
}

install_vscode() {
    echo -e "${GREEN}>> Iniciando a instalação do Visual Studio Code...${NC}"
    wget -O ~/dev/vscode/vscode.deb https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64
    sudo apt install -y ~/dev/vscode/vscode.deb
    echo -e "${GREEN}>> Visual Studio Code instalado com sucesso.${NC}"
}

install_java() {
    echo -e "${GREEN}>> Iniciando a instalação do Java 17...${NC}"
    wget -O ~/dev/java/jdk17.deb https://download.oracle.com/java/17/archive/jdk-17.0.12_linux-x64_bin.deb
    sudo apt install -y ~/dev/java/jdk17.deb

    JAVA_HOME="/usr/lib/jvm/jdk-17.0.12-oracle-x64"
    if ! grep -q "JAVA_HOME" ~/.bashrc; then
        echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
        echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
    fi
    source ~/.bashrc

    echo -e "${GREEN}>> Java 17 instalado e variáveis de ambiente configuradas com sucesso.${NC}"
}

read -p "Deseja instalar o Docker? (S/N): " install_docker_choice
if [[ "$install_docker_choice" =~ ^[Ss]$ ]]; then
    install_docker
else
    echo -e "${WHITE}>> Docker não será instalado.${NC}"
fi

read -p "Deseja instalar o kubectl e Minikube? (S/N): " install_k8s_choice
if [[ "$install_k8s_choice" =~ ^[Ss]$ ]]; then
    install_kubernetes_tools
    install_k9s
else
    echo -e "${WHITE}>> kubectl e Minikube não serão instalados.${NC}"
fi


read -p "Deseja instalar o Visual Studio Code? (S/N): " install_vscode_choice
if [[ "$install_vscode_choice" =~ ^[Ss]$ ]]; then
    install_vscode
else
    echo -e "${WHITE}>> Visual Studio Code não será instalado.${NC}"
fi

read -p "Deseja instalar o Java 17? (S/N): " install_java_choice
if [[ "$install_java_choice" =~ ^[Ss]$ ]]; then
    install_java
else
    echo -e "${WHITE}>> Java 17 não será instalado.${NC}"
fi

echo -e "${GREEN}>> Configuração do ambiente de desenvolvimento concluída.${NC}"
