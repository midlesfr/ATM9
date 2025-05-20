import discord
import sys
import os
from dotenv import load_dotenv

# Charger les variables d'environnement depuis le fichier .env
load_dotenv()

# Récupérer le token et l'ID du canal depuis les variables d'environnement
TOKEN = os.getenv('DISCORD_TOKEN')
CHANNEL_ID = os.getenv('CHANNEL_ID')

# Vérifier si le token et l'ID du canal sont disponibles
if not TOKEN or not CHANNEL_ID:
    print("❌ Token ou Channel ID manquant dans le fichier .env.")
    sys.exit(1)

# Convertir CHANNEL_ID en entier
try:
    CHANNEL_ID = int(CHANNEL_ID)
except ValueError:
    print("❌ CHANNEL_ID doit être un entier valide.")
    sys.exit(1)

# Récupérer le message à envoyer en argument
text_to_send = sys.argv[1] if len(sys.argv) > 1 else "⚠️ Aucun message précisé."

# Configuration du client Discord
intents = discord.Intents.default()
client = discord.Client(intents=intents)

@client.event
async def on_ready():
    print(f"✅ Bot connecté en tant que {client.user}")
    channel = client.get_channel(CHANNEL_ID)
    if channel:
        try:
            messages = [msg async for msg in channel.history(limit=1)]
            if messages:
                await messages[0].delete()
            await channel.send(text_to_send)
            print("✅ Notification envoyée avec succès.")
        except Exception as e:
            print(f"❌ Erreur lors de l'envoi du message : {e}")
    else:
        print("❌ Salon introuvable. Vérifie que le bot a bien accès au canal.")
    await client.close()

try:
    client.run(TOKEN)
except Exception as e:
    print(f"❌ Erreur de connexion au bot Discord : {e}")
