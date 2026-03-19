

# PROJET AUDIT ET REMEDIATION - PATCH TUESDAY

Description :
Ce projet contient les scripts PowerShell pour l'audit de securite et la 
remediation de la vulnerabilite sur l'agent logiciel DataFlow.

Fonctionnalites :
- Audit a distance des serveurs Windows Server 2016.
- Arret automatique du service DataFlowAgent si la version est inferieure a 4.0.
- Protection specifique pour les Controleurs de Domaine (aucune action).
- Generation d'un rapport de synthese au format CSV.
- Generation d'un dashboard HTML pour la visualisation des alertes.

Utilisation :
1. Execution de l'audit : 
   Lancer le script .\MonScript.ps1 pour scanner le parc.
   
2. Generation du rapport HTML :
   Lancer le script .\Generer_Rapport_HTML.ps1 une fois l'audit termine.

3. Consultation des resultats :
   - Fichier de donnees : Resultat.csv
   - Fichier visuel : [Nombre]_Alertes_[Date].html

Structure du projet :
- MonScript.ps1 : Script principal d'audit et d'action.
- Generer_Rapport_HTML.ps1 : Script de creation du rapport HTML.
- Data/ : Repertoire contenant la liste des serveurs cibles.
- Resultat.csv : Rapport genere par le script d'audit.
