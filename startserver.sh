#!/bin/bash
set -eu

FORGE_VERSION=47.4.0
INSTALLER="forge-1.20.1-$FORGE_VERSION-installer.jar"
FORGE_URL="https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.1-$FORGE_VERSION/forge-1.20.1-$FORGE_VERSION-installer.jar"
LOGFILE="logs/latest.log"
PATTERN="Dedicated server took"

# Fonction de pause pour l'utilisateur
pause() {
    printf "%s\n" "Press enter to continue..."
    read ans
}

# Vérification de la présence de Java 17 ou supérieur
if ! command -v "${ATM9_JAVA:-java}" >/dev/null 2>&1; then
    echo "Minecraft 1.20.1 requires Java 17 - Java not found"
    pause
    exit 1
fi

cd "$(dirname "$0")"

# Installation de Forge si ce n'est pas déjà fait
if [ ! -d libraries ]; then
    echo "Forge not installed, installing now."
    
    # Vérification si l'installateur Forge est déjà présent
    if [ ! -f "$INSTALLER" ]; then
        echo "No Forge installer found, downloading now."
        
        # Utilisation de wget ou curl pour télécharger Forge
        if command -v wget >/dev/null 2>&1; then
            echo "DEBUG: (wget) Downloading $FORGE_URL"
            wget -O "$INSTALLER" "$FORGE_URL"
        elif command -v curl >/dev/null 2>&1; then
            echo "DEBUG: (curl) Downloading $FORGE_URL"
            curl -o "$INSTALLER" -L "$FORGE_URL"
        else
            echo "Neither wget nor curl were found on your system. Please install one and try again."
            pause
            exit 1
        fi
    fi

    # Exécution de l'installateur Forge
    echo "Running Forge installer."
    "${ATM9_JAVA:-java}" -jar "$INSTALLER" -installServer
fi

# Création du fichier server.properties si nécessaire
if [ ! -e server.properties ]; then
    printf "allow-flight=true\nmotd=All the Mods 9\nmax-tick-time=180000" > server.properties 
fi

# Si l'installation seule est demandée, on s'arrête ici
if [ "${ATM9_INSTALL_ONLY:-false}" = "true" ]; then
    echo "INSTALL_ONLY: complete"
    exit 0
fi

# Vérification de la version de Java (doit être >= 17)
JAVA_VERSION=$("${ATM9_JAVA:-java}" -fullversion 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
if [ "$JAVA_VERSION" -lt 17 ]; then
    echo "Minecraft 1.20.1 requires Java 17 - found Java $JAVA_VERSION"
    pause
    exit 1
fi

# Notification Discord : Démarrage en cours
python3 /root/minecraft/scripts/discord_notify.py "🛠️ Le serveur ATM9 est en train de démarrer... ⏳"

# Démarrage du serveur dans un screen détaché
echo "🔄 Lancement du serveur dans un screen nommé 'atm9'..."
screen -dmS atm9 "${ATM9_JAVA:-java}" @user_jvm_args.txt @libraries/net/minecraftforge/forge/1.20.1-$FORGE_VERSION/unix_args.txt nogui

# Attente que le serveur soit prêt (vérifie les logs)
echo "⏳ En attente que le serveur ATM9 termine son démarrage..."
while ! grep -q "$PATTERN" "$LOGFILE"; do
    sleep 5
done

# Le serveur est prêt, on envoie la notification Discord
echo "✅ Le serveur est en ligne, envoi de la notification Discord !"
python3 /root/minecraft/scripts/discord_notify.py "🟢 Le serveur Minecraft ATM9 est en ligne !"

# Boucle de redémarrage automatique si besoin
while true; do
    # Vérifie si le screen 'atm9' est toujours en cours d'exécution
    if ! screen -list | grep -q "atm9"; then
        echo "🔴 Serveur arrêté."
        python3 /root/minecraft/scripts/discord_notify.py "🔴 Le serveur Minecraft ATM9 est hors ligne !"

        if [ "${ATM9_RESTART:-true}" = "false" ]; then
            exit 0
        fi

        echo "♻️ Redémarrage automatique du serveur dans 10 secondes..."
        sleep 10

        # Relance le serveur dans un nouveau screen
        echo "🔄 Relancement du serveur dans un nouveau screen..."
        screen -dmS atm9 "${ATM9_JAVA:-java}" @user_jvm_args.txt @libraries/net/minecraftforge/forge/1.20.1-$FORGE_VERSION/unix_args.txt nogui
    fi

    sleep 10
done

