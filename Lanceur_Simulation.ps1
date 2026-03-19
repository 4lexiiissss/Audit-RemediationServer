# =============================================================================
# SIMULATEUR D'INFRASTRUCTURE (NE PAS MODIFIER CE FICHIER)
# =============================================================================
# Lancez ce script pour tester 'MonScript.ps1'.
# Il simule le réseau et affiche les actions que votre script tente d'effectuer.
# =============================================================================

Clear-Host
Write-Host "--- DEMARRAGE DE LA SIMULATION ---" -ForegroundColor Cyan

# 1. Chargement de la base de données fictive
$CheminJson = "$PSScriptRoot\Data\infrastructure.json"
if (!(Test-Path $CheminJson)) { throw "ERREUR : Fichier Data\infrastructure.json introuvable !" }
$RefData = Get-Content $CheminJson | ConvertFrom-Json

# 2. Configuration de l'environnement (Mocks)
Describe "Environnement de Simulation" {
    
    # On rend Pester silencieux sur les résultats de tests (car ce n'est pas un test)
    # On veut juste voir les Write-Host de l'étudiant et du simulateur.

    Mock Invoke-Command {
        param($ComputerName, $ScriptBlock)

        # Recherche du serveur dans le JSON
        $Node = $RefData | Where-Object { $_.ComputerName -eq $ComputerName }
        
        if (-not $Node) { 
            Write-Host " [ERREUR RESEAU] Le serveur '$ComputerName' est inconnu !" -ForegroundColor Red
            return 
        }

        # Simulation OS (Get-CimInstance ou Get-ComputerInfo)
        if ($ScriptBlock -match "Win32_OperatingSystem|Get-ComputerInfo") {
            return [PSCustomObject]@{ CSName=$Node.ComputerName; Caption=$Node.OS }
        }

        # Simulation Version/Rôle (Get-ItemProperty)
        if ($ScriptBlock -match "Get-ItemProperty|HKLM") {
            return [PSCustomObject]@{ Version=$Node.Version; Role=$Node.Role }
        }

        # Simulation de l'action Stop-Service
        if ($ScriptBlock -match "Stop-Service") {
            Write-Host " [ACTION] Demande d'arret du service sur $ComputerName" -ForegroundColor Yellow
            return
        }
    }

    # 3. Exécution du script de l'étudiant
    Context "Execution de MonScript.ps1" {
        It "Lancement du script étudiant..." {
            try {
                . "$PSScriptRoot\MonScript.ps1"
            }
            catch {
                Write-Host " [ERREUR FATALE] Votre script a plante :" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
        }
    }
}

Write-Host "`n--- FIN DE LA SIMULATION ---" -ForegroundColor Cyan
Write-Host "Verifiez si un fichier Resultat.json ou .csv a ete cree." -ForegroundColor Green