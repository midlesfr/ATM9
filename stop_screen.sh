#!/bin/bash 

# Vérifie si un nom de session a été donné
if [ -z "$1" ]; then
	  echo "Usage: $0 <nom_de_la_session_screen>"
	    exit 1
fi

SESSION_NAME="$1"

# Vérifie si la session existe
 if screen -ls | grep -q "\.${SESSION_NAME}"; then
   echo "Fermeture de la session screen '${SESSION_NAME}'..."
     screen -X -S "${SESSION_NAME}" quit
       echo "✅ Session '${SESSION_NAME}' fermée."
       else
         echo "❌ Aucune session screen nommée '${SESSION_NAME}' trouvée."
         fi
       
