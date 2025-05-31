#!/bin/bash

GREEN='\e[1;32m'
WHITE='\e[1;37m'
RED='\e[1;31m' # Added for error messages
NC='\e[0m'

echo -e "${WHITE}=================================================${NC}"
echo -e "${GREEN}
██╗░░██╗░█████╗░██╗░██████╗░██╗░██████╗    ██████╗░███████╗██╗░░░██╗
██║░██╔╝██╔══██╗██║██╔═══██╗╚█║██╔════╝    ██╔══██╗██╔════╝██║░░░██║
█████═╝░███████║██║██║██╗██║░╚╝╚█████╗░    ██║░░██║█████╗░░╚██╗░██╔╝
██╔═██╗░██╔══██║██║╚██████╔╝░░░░╚═══██╗    ██║░░██║██╔══╝░░░╚████╔╝░
██║░╚██╗██║░░██║██║░╚═██╔═╝░░░░██████╔╝    ██████╔╝███████╗░░╚██╔╝░░
╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░░╚═╝░░░░░░╚═════╝░    ╚═════╝░╚══════╝░░░╚═╝░░░

███████╗███╗░░██╗██╗░░░██╗██╗██████╗░░█████╗░███╗░░░███╗███████╗███╗░░██╗████████╗
██╔════╝████╗░██║██║░░░██║██║██╔══██╗██╔══██╗████╗░████║██╔════╝████╗░██║╚══██╔══╝
█████╗░░██╔██╗██║╚██╗░██╔╝██║██████╔╝██║░░██║██╔████╔██║█████╗░░██╔██╗██║░░░██║░░░
██╔══╝░░██║╚████║░╚████╔╝░██║██╔══██╗██║░░██║██║╚██╔╝██║██╔══╝░░██║╚████║░░░██║░░░
███████╗██║░╚███║░░╚██╔╝░░██║██║░░██║╚█████╔╝██║░╚═╝░██║███████╗██║░╚███║░░░██║░░░
╚══════╝╚═╝░░╚══╝░░░╚═╝░░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░░░░╚═╝╚══════╝╚═╝░░╚══╝░░░╚═╝░░░${NC}"
echo -e "${WHITE}=================================================${NC}"

sleep 1
echo -e "${WHITE}Este script instala dependências e ferramentas comuns utilizadas em desenvolvimento, incluindo:
    - Docker
    - kubectl e Minikube
    - K9s
    - Visual Studio Code
    - OpenJDK 21 (via apt)
    - IntelliJ IDEA Community (via .tar.gz)

Você pode optar por instalar cada ferramenta individualmente ou todas de uma vez.${NC}"

mkdir -p ~/dev/{k9s,vscode,java,intellij} # 'java' directory might not be used by OpenJDK apt install, but doesn't hurt

install_docker() {
    echo -e "${GREEN}>> Iniciando a instalação do Docker...${NC}"
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove -y -qq $pkg > /dev/null 2>&1; done

    sudo apt-get update -qq
    sudo apt-get install -y -qq ca-certificates curl gnupg

    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -qq
    sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    if ! getent group docker > /dev/null; then
        sudo groupadd docker
    fi
    sudo usermod -aG docker $USER

    echo -e "${GREEN}>> Docker instalado com sucesso. Você pode precisar fazer logout e login para que as alterações de grupo entrem em vigor.${NC}"
}

install_kubernetes_tools() {
    echo -e "${GREEN}>> Iniciando a instalação do kubectl e Minikube...${NC}"

    echo -e "${GREEN}Instalando kubectl...${NC}"
    curl -sLO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl

    echo -e "${GREEN}Instalando Minikube...${NC}"
    curl -sLO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64

    echo -e "${GREEN}>> kubectl e Minikube instalados com sucesso.${NC}"
}

install_k9s() {
    echo -e "${GREEN}>> Iniciando a instalação do K9s...${NC}"
    K9S_LATEST_URL=$(curl -s "https://api.github.com/repos/derailed/k9s/releases/latest" | grep "browser_download_url.*k9s_linux_amd64.deb" | cut -d '"' -f 4)
    if [ -z "$K9S_LATEST_URL" ]; then
        echo -e "${RED}Não foi possível obter a URL de download mais recente do K9s. Usando versão fallback.${NC}"
        K9S_LATEST_URL="https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_linux_amd64.deb" # Fallback
    fi
    echo -e "${GREEN}Baixando K9s de: ${K9S_LATEST_URL}${NC}"
    wget -qO ~/dev/k9s/k9s.deb "$K9S_LATEST_URL"
    sudo apt install -y -qq ~/dev/k9s/k9s.deb > /dev/null
    rm ~/dev/k9s/k9s.deb
    echo -e "${GREEN}>> K9s instalado com sucesso.${NC}"
}

install_vscode() {
    echo -e "${GREEN}>> Iniciando a instalação do Visual Studio Code...${NC}"
    wget -qO ~/dev/vscode/vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
    sudo apt install -y -qq ~/dev/vscode/vscode.deb > /dev/null
    rm ~/dev/vscode/vscode.deb
    echo -e "${GREEN}>> Visual Studio Code instalado com sucesso.${NC}"
}

install_java() {
    echo -e "${GREEN}>> Iniciando a instalação do OpenJDK 21...${NC}"
    
    sudo apt-get update -qq
    echo -e "${GREEN}Instalando OpenJDK 21 JDK (pacote openjdk-21-jdk)...${NC}"
    sudo apt-get install -y -qq openjdk-21-jdk
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erro ao instalar o OpenJDK 21. Verifique sua conexão e repositórios APT.${NC}"
        return 1
    fi

    # Detectar JAVA_HOME para OpenJDK 21
    local java_exe_path
    if command -v java &>/dev/null; then
        java_exe_path=$(readlink -f $(which java)) 
    fi

    local DETECTED_JAVA_HOME=""
    if [ -n "$java_exe_path" ]; then
        DETECTED_JAVA_HOME=$(dirname $(dirname "$java_exe_path"))
    fi

    if [ ! -d "$DETECTED_JAVA_HOME" ] || [ ! -f "$DETECTED_JAVA_HOME/release" ]; then
        echo -e "${WHITE}Detecção primária do JAVA_HOME falhou ou caminho inválido (${DETECTED_JAVA_HOME}). Tentando caminho padrão...${NC}"
        DETECTED_JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64" 
        
        if [ ! -d "$DETECTED_JAVA_HOME" ] || [ ! -f "$DETECTED_JAVA_HOME/release" ]; then
            echo -e "${RED}Não foi possível detectar ou validar um diretório JAVA_HOME para o OpenJDK 21.${NC}"
            echo -e "${WHITE}Caminho padrão tentado: ${DETECTED_JAVA_HOME}${NC}"
            echo -e "${WHITE}Por favor, verifique a instalação e configure o JAVA_HOME manualmente em ~/.bashrc.${NC}"
            return 1
        fi
    fi
    
    echo -e "${GREEN}OpenJDK 21 JAVA_HOME detectado/definido como: ${DETECTED_JAVA_HOME}${NC}"

    local bashrc_updated_flag=0
    if grep -Fxq "export JAVA_HOME=\"${DETECTED_JAVA_HOME}\"" ~/.bashrc && \
       grep -Fxq 'export PATH="$JAVA_HOME/bin:$PATH"' ~/.bashrc && \
       grep -Fxq "# OpenJDK 21 Configuration" ~/.bashrc; then
        echo -e "${WHITE}Variáveis de ambiente para OpenJDK 21 já parecem estar configuradas corretamente em ~/.bashrc.${NC}"
    else
        echo -e "${GREEN}Configurando variáveis de ambiente JAVA_HOME e PATH para OpenJDK 21 em ~/.bashrc...${NC}"
        
        [[ $(tail -c1 ~/.bashrc | wc -l) -eq 0 ]] && echo "" >> ~/.bashrc

        echo "" >> ~/.bashrc
        echo "# OpenJDK 21 Configuration" >> ~/.bashrc
        echo "export JAVA_HOME=\"${DETECTED_JAVA_HOME}\"" >> ~/.bashrc
        echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> ~/.bashrc
        bashrc_updated_flag=1
    fi

    if [ "$bashrc_updated_flag" -eq 1 ]; then
        echo -e "${GREEN}Por favor, execute 'source ~/.bashrc' ou abra um novo terminal para aplicar as alterações do OpenJDK 21.${NC}"
    fi
    
    echo -e "${GREEN}>> OpenJDK 21 instalado e configurado com sucesso.${NC}"
    echo -e "${WHITE}Verifique a versão com: java --version${NC}"
}

install_intellij() {
    echo -e "${GREEN}>> Iniciando a instalação do IntelliJ IDEA Community Edition...${NC}"

    local INTELLIJ_URL="https://download.jetbrains.com/idea/ideaIC-2025.1.1.1.tar.gz?_gl=1*ijzsyy*_gcl_au*MjE4NjYyMzE3LjE3NDg2MzQzNDE.*FPAU*MjE4NjYyMzE3LjE3NDg2MzQzNDE.*_ga*MTUwMDkyMTY5Ny4xNzQ4NjM0MzQz*_ga_9J976DJZ68*czE3NDg3MzI2MjQkbzIkZzEkdDE3NDg3MzM2MDMkajU5JGwwJGgw"
    local INTELLIJ_DOWNLOAD_DIR="$HOME/dev/intellij"
    local INTELLIJ_TAR_FILENAME
    INTELLIJ_TAR_FILENAME=$(basename "${INTELLIJ_URL%%\?*}") 

    mkdir -p "$INTELLIJ_DOWNLOAD_DIR"

    echo -e "${GREEN}Baixando IntelliJ IDEA de: ${INTELLIJ_URL}${NC}"
    # wget -qO para ser quieto e output para arquivo. Adicionando --show-progress para feedback em arquivos grandes.
    wget -O "${INTELLIJ_DOWNLOAD_DIR}/${INTELLIJ_TAR_FILENAME}" "${INTELLIJ_URL}" 
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erro ao baixar o IntelliJ IDEA. Verifique a URL ou sua conexão com a internet.${NC}"
        return 1
    fi

    echo -e "${GREEN}Extraindo IntelliJ IDEA...${NC}"
    local EXTRACTED_DIR_NAME
    EXTRACTED_DIR_NAME=$(tar -tzf "${INTELLIJ_DOWNLOAD_DIR}/${INTELLIJ_TAR_FILENAME}" | head -1 | sed -e 's@/.*@@')
    
    if [ -z "$EXTRACTED_DIR_NAME" ]; then
        echo -e "${RED}Não foi possível determinar o nome do diretório extraído do IntelliJ IDEA.${NC}"
        echo -e "${RED}Removendo arquivo baixado: ${INTELLIJ_DOWNLOAD_DIR}/${INTELLIJ_TAR_FILENAME}${NC}"
        rm "${INTELLIJ_DOWNLOAD_DIR}/${INTELLIJ_TAR_FILENAME}" 
        return 1
    fi

    tar -xzf "${INTELLIJ_DOWNLOAD_DIR}/${INTELLIJ_TAR_FILENAME}" -C "${INTELLIJ_DOWNLOAD_DIR}"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erro ao extrair o IntelliJ IDEA.${NC}"
        echo -e "${RED}Removendo arquivo baixado: ${INTELLIJ_DOWNLOAD_DIR}/${INTELLIJ_TAR_FILENAME}${NC}"
        rm "${INTELLIJ_DOWNLOAD_DIR}/${INTELLIJ_TAR_FILENAME}" 
        return 1
    fi

    local INTELLIJ_INSTALL_PATH="${INTELLIJ_DOWNLOAD_DIR}/${EXTRACTED_DIR_NAME}"

    echo -e "${GREEN}IntelliJ IDEA instalado em: ${INTELLIJ_INSTALL_PATH}${NC}"

    echo -e "${GREEN}Criando atalho no menu de aplicativos (ícone)...${NC}"
    local DESKTOP_ENTRY_DIR="$HOME/.local/share/applications"
    mkdir -p "$DESKTOP_ENTRY_DIR"

    local ICON_PATH="${INTELLIJ_INSTALL_PATH}/bin/idea.png"
    if [ ! -f "$ICON_PATH" ]; then
        echo -e "${WHITE}Ícone PNG não encontrado em ${ICON_PATH}. Tentando ícone SVG.${NC}"
        ICON_PATH="${INTELLIJ_INSTALL_PATH}/bin/idea.svg"
        if [ ! -f "$ICON_PATH" ]; then
             echo -e "${RED}Ícone SVG também não encontrado em ${ICON_PATH}. O atalho pode não ter um ícone.${NC}"
             ICON_PATH="" 
        fi
    fi

    cat > "${DESKTOP_ENTRY_DIR}/jetbrains-idea-community.desktop" <<EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=IntelliJ IDEA Community Edition
Icon=${ICON_PATH}
Exec="${INTELLIJ_INSTALL_PATH}/bin/idea.sh" %f
Comment=Ambiente de Desenvolvimento Integrado
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-idea-ce
EOL

    if command -v update-desktop-database &> /dev/null; then
        echo -e "${GREEN}Atualizando banco de dados de entradas de desktop...${NC}"
        update-desktop-database "$DESKTOP_ENTRY_DIR" > /dev/null
    fi

    echo -e "${GREEN}Limpando o arquivo compactado baixado...${NC}"
    rm "${INTELLIJ_DOWNLOAD_DIR}/${INTELLIJ_TAR_FILENAME}"

    echo -e "${GREEN}>> IntelliJ IDEA Community Edition instalado com sucesso!${NC}"
    echo -e "${WHITE}Você pode encontrar o IntelliJ IDEA no menu de aplicativos do seu sistema.${NC}"
    echo -e "${WHITE}O script de inicialização está localizado em: ${INTELLIJ_INSTALL_PATH}/bin/idea.sh${NC}"
}

echo -e "${WHITE}-------------------------------------------------${NC}"
read -p "$(echo -e "${WHITE}Deseja instalar TODAS as ferramentas recomendadas de uma vez? (S/N): ${NC}")" install_all_choice
echo -e "${WHITE}-------------------------------------------------${NC}"

if [[ "$install_all_choice" =~ ^[Ss]$ ]]; then
    echo -e "${GREEN}>> Iniciando a instalação COMPLETA de todas as ferramentas recomendadas...${NC}"
    
    install_docker
    echo -e "${WHITE}-------------------------------------------------${NC}"
    
    install_kubernetes_tools
    echo -e "${GREEN}Instalando K9s (parte da suíte Kubernetes)...${NC}"
    install_k9s 
    echo -e "${WHITE}-------------------------------------------------${NC}"
    
    install_vscode
    echo -e "${WHITE}-------------------------------------------------${NC}"
    
    install_java 
    echo -e "${WHITE}-------------------------------------------------${NC}"
    
    install_intellij
    echo -e "${WHITE}-------------------------------------------------${NC}"

    echo -e "${GREEN}>> Instalação completa de todas as ferramentas processada.${NC}"

else
    echo -e "${WHITE}>> Optou-se pela instalação manual. Por favor, responda às perguntas abaixo.${NC}"
    echo -e "${WHITE}-------------------------------------------------${NC}"

    read -p "$(echo -e "${WHITE}Deseja instalar o Docker? (S/N): ${NC}")" install_docker_choice
    if [[ "$install_docker_choice" =~ ^[Ss]$ ]]; then
        install_docker
    else
        echo -e "${WHITE}>> Docker não será instalado.${NC}"
    fi
    echo -e "${WHITE}-------------------------------------------------${NC}"

    read -p "$(echo -e "${WHITE}Deseja instalar o kubectl e Minikube? (S/N): ${NC}")" install_k8s_choice
    if [[ "$install_k8s_choice" =~ ^[Ss]$ ]]; then
        install_kubernetes_tools
        read -p "$(echo -e "${WHITE}Deseja instalar o K9s (gerenciador de terminal para Kubernetes)? (S/N): ${NC}")" install_k9s_choice
        if [[ "$install_k9s_choice" =~ ^[Ss]$ ]]; then
            install_k9s
        else
            echo -e "${WHITE}>> K9s não será instalado.${NC}"
        fi
    else
        echo -e "${WHITE}>> kubectl, Minikube e K9s não serão instalados.${NC}"
    fi
    echo -e "${WHITE}-------------------------------------------------${NC}"

    read -p "$(echo -e "${WHITE}Deseja instalar o Visual Studio Code? (S/N): ${NC}")" install_vscode_choice
    if [[ "$install_vscode_choice" =~ ^[Ss]$ ]]; then
        install_vscode
    else
        echo -e "${WHITE}>> Visual Studio Code não será instalado.${NC}"
    fi
    echo -e "${WHITE}-------------------------------------------------${NC}"

    read -p "$(echo -e "${WHITE}Deseja instalar o OpenJDK 21? (S/N): ${NC}")" install_java_choice
    if [[ "$install_java_choice" =~ ^[Ss]$ ]]; then
        install_java
    else
        echo -e "${WHITE}>> OpenJDK 21 não será instalado.${NC}"
    fi
    echo -e "${WHITE}-------------------------------------------------${NC}"

    read -p "$(echo -e "${WHITE}Deseja instalar o IntelliJ IDEA? (S/N): ${NC}")" install_intellij_choice
    if [[ "$install_intellij_choice" =~ ^[Ss]$ ]]; then
        install_intellij
    else
        echo -e "${WHITE}>> IntelliJ IDEA não será instalado.${NC}"
    fi
    echo -e "${WHITE}-------------------------------------------------${NC}"
fi

echo -e "${GREEN}>> Configuração do ambiente de desenvolvimento concluída.${NC}"
echo -e "${WHITE}Lembre-se de executar 'source ~/.bashrc' ou abrir um novo terminal se o Java (OpenJDK 21) foi instalado/atualizado.${NC}"
echo -e "${WHITE}Para o Docker, pode ser necessário fazer logout e login para que as permissões de grupo tenham efeito.${NC}"