# =============================================================================
# TP AUDIT & REMÉDIATION - OPÉRATION PATCH TUESDAY
# Auteur : Alexis DEMOL
# =============================================================================

# --- RAPPEL DES CONSIGNES ---
# 1. Parcourir la liste des serveurs (fichier Data/liste_serveurs.txt)
# 2. Utiliser Invoke-Command pour récupérer : OS, Rôle, Version de l'agent
# 3. Appliquer la logique métier (Stop si < 4.0, sauf DC, etc.)
# 4. Générer un rapport 'Resultat.json' ou 'Resultat.csv'

# --- EXEMPLE DE COMMANDE DISPONIBLE (Via Simulation) ---
# Invoke-Command -ComputerName X -ScriptBlock { Get-CimInstance Win32_OperatingSystem }

# --- DÉBUT DU SCRIPT ---

Write-Host "Demarrage de l'audit..." -ForegroundColor Cyan

# ÉTAPE 1 : Chargez la liste des serveurs à auditer

$data = get-content "Data/liste_serveurs.txt" 


# ÉTAPE 2 : Bouclez sur les serveurs et appliquez la logique métier
# (Audit OS, Audit Application, Remédiation si nécessaire)
$resultats = [System.Collections.Generic.List[object]]::new()

foreach ($servers in $data) {
    Write-host "Audit servers: $servers" -ForegroundColor Green
    $os = Invoke-Command -ComputerName $servers -ScriptBlock {
        Get-CimInstance Win32_OperatingSystem
    }

    $Agent = Invoke-Command -ComputerName $servers -ScriptBlock {
        Get-itemproperty "HKLM:\Software\DataFlow" -ErrorAction SilentlyContinue
    }

    $Version = $Agent.Version
    $Role = $Agent.Role 
    if ($os.Caption -ne "Windows Server 2016") {
        continue
    }
    if ($Role -eq "DomainController") {
        $action = "MANUAL_CHECK"
    }
        
    if ($Version -lt "4.0" -and $Role -ne "DomainController") {
        Invoke-Command -ComputerName $servers -ScriptBlock { Stop-Service "DataFlowAgent" -Force }
        $action = "STOPPED"
    }
    if ($Version -ge "4.0" -and $Version -lt "5.0") {
        $action = "WARNING"
    }
    if ($Version -ge "5.0") {
        $action = "OK"
    }
    $obj = [PSCustomObject]@{
        ComputerName = $servers
        OS = $os.Caption
        Role = $Role
        Version = $Version
        Action = $action
    }
    $resultats.Add($obj)   
}
write-host $resultats
$resultats | Export-Csv "Resultat.csv" -Delimiter ";" -NoTypeInformation -Encoding UTF8
Write-Host "Audit terminee. Resultats sauvegardes dans 'Resultat.csv'" -ForegroundColor Cyan
