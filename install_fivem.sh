#!/bin/bash

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"

echo -e "${GREEN}FiveM Server Installer & Updater für Linux mit txAdmin und phpMyAdmin${NC}"

if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}Dieses Skript muss als root ausgeführt werden!${NC}"
    exit 1
fi

install_fivem() {
    echo -e "${GREEN}System wird aktualisiert und notwendige Pakete werden installiert...${NC}"
    apt update && apt upgrade -y
    apt install -y screen git curl wget unzip mariadb-server nginx phpmyadmin

    echo -e "${GREEN}MariaDB wird konfiguriert...${NC}"
    service mysql start
    mysql -e "CREATE DATABASE fivem; CREATE USER 'fivemuser'@'localhost' IDENTIFIED BY 'fivempassword'; GRANT ALL PRIVILEGES ON fivem.* TO 'fivemuser'@'localhost'; FLUSH PRIVILEGES;"

    echo -e "${GREEN}phpMyAdmin wird konfiguriert...${NC}"
    ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
    systemctl restart nginx

    echo -e "${GREEN}FiveM Server wird heruntergeladen und installiert...${NC}"
    mkdir -p /opt/fivem
    cd /opt/fivem
    curl -Lo fx.tar.xz "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/$(curl -s https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/ | grep -oE '[0-9]+/[a-zA-Z0-9.-]+' | head -n 1)"
    tar -xf fx.tar.xz
    rm fx.tar.xz

    echo -e "${GREEN}txAdmin wird eingerichtet...${NC}"
    echo "set txAdminPort 40120" > /opt/fivem/server.cfg

    echo -e "${GREEN}Startskript wird erstellt...${NC}"
    cat <<EOL > /opt/fivem/start.sh
#!/bin/bash
cd /opt/fivem
screen -dmS fivem ./run.sh +exec server.cfg
EOL
    chmod +x /opt/fivem/start.sh

    echo -e "${GREEN}Firewall wird konfiguriert...${NC}"
    ufw allow 30120
    ufw allow 40120
    ufw reload

    echo -e "${GREEN}Installation abgeschlossen!${NC}"
    echo -e "FiveM Server ist im Ordner /opt/fivem"
    echo -e "Nutze das Skript mit: /opt/fivem/start.sh"
    echo -e "phpMyAdmin ist verfügbar unter: http://<your-server-ip>/phpmyadmin"
}

update_fivem() {
    echo -e "${GREEN}FiveM wird auf die neueste Version aktualisiert...${NC}"
    cd /opt/fivem
    curl -Lo fx.tar.xz "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/$(curl -s https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/ | grep -oE '[0-9]+/[a-zA-Z0-9.-]+' | head -n 1)"
    tar -xf fx.tar.xz
    rm fx.tar.xz
    echo -e "${GREEN}FiveM wurde erfolgreich aktualisiert!${NC}"
}

case "$1" in
    install)
        install_fivem
        ;;
    update)
        update_fivem
        ;;
    *)
        echo -e "${RED}Usage: $0 {install|update}${NC}"
        ;;
esac
