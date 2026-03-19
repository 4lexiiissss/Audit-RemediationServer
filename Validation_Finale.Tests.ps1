# =============================================================================
# SCRIPT DE VALIDATION FINALE (COMPATIBLE TOUTES VERSIONS)
# =============================================================================

# --- FONCTION UTILITAIRE (Interne) ---
function Get-StringHash {
    param($InputString)
    if ([string]::IsNullOrWhiteSpace($InputString)) { return "" }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    return [BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)).Replace('-', '')
}

$RefData = Get-Content "$PSScriptRoot\Data\infrastructure.json" | ConvertFrom-Json

Describe "Validation TP : Audit & Remediation" {

    $H_CRITIQUE = "71A12CE83C033A8422F4BFDC1B627C6E758C87160EAEB9F8B9AAA162AA35C6C9"
    $H_WARNING = "917FB9A0383EDDC8C894CDD538073A81A4CF3E0434592293FB848FB93B9FAA67"
    $H_SAFE = "DBC385CDCE13609B93DE03186ED512E9E22998A1BCE3FDB8F60A8121DE91EEFB"
    $H_DC = "CA905C4596A3AE908043A6C86C1674EFA736D964809CB0BF96AB476D673B2156"
    $H_OLD = "3182B71350C084EADDB990E8EC30672FF393A6CC2FD00CE13604D4D881611159" 

    $Script:StoppedHashes = New-Object System.Collections.ArrayList

    Mock Invoke-Command {
        param($ComputerName, $ScriptBlock)
        
        $Node = $RefData | Where-Object { $_.ComputerName -eq $ComputerName }
        if (-not $Node) { return $null }

        if ($ScriptBlock -match "Win32_OperatingSystem|Get-ComputerInfo") {
            return [PSCustomObject]@{ CSName = $Node.ComputerName; Caption = $Node.OS }
        }
        if ($ScriptBlock -match "Get-ItemProperty|HKLM") {
            return [PSCustomObject]@{ Version = $Node.Version; Role = $Node.Role }
        }
        
        if ($ScriptBlock -match "Stop-Service") {
            $Hash = Get-StringHash $Node.ComputerName
            [void]$Script:StoppedHashes.Add($Hash)
        }
    }

    # --- VERIFICATION DES REGLES METIER (ACTIONS) ---
    Context "1. Analyse des actions de remediation (Stop-Service)" {
        
        It "Le script s'execute sans erreur" {
            { . "$PSScriptRoot\MonScript.ps1" } | Should Not Throw
        }

        It "Regle Securite : Le serveur critique (Version < 4.0) a bien ete ARRETE" {
            ($Script:StoppedHashes -contains $H_CRITIQUE) | Should Be $true
        }

        It "Regle Production : Le serveur en 'Warning' (Version 4.x) N'A PAS ete arrete" {
            ($Script:StoppedHashes -contains $H_WARNING) | Should Be $false
        }

        It "Regle Production : Le serveur sain (Version 5.x) N'A PAS ete arrete" {
            ($Script:StoppedHashes -contains $H_SAFE) | Should Be $false
        }

        It "Regle Integrite AD : Le Controleur de Domaine N'A PAS ete arrete (Protection)" {
            ($Script:StoppedHashes -contains $H_DC) | Should Be $false
        }

        It "Regle Perimetre : Le serveur Windows 2012 (Hors Scope) N'A PAS ete arrete" {
            ($Script:StoppedHashes -contains $H_OLD) | Should Be $false
        }
    }

    # --- VERIFICATION DU RAPPORT (CONTENU) ---
    Context "2. Analyse du Rapport Final (JSON/CSV)" {
        
        $JsonPath = "$PSScriptRoot\Resultat.json"
        $CsvPath = "$PSScriptRoot\Resultat.csv"
        
        It "Un fichier de rapport (Resultat.json ou .csv) existe" {
            (Test-Path $JsonPath) -or (Test-Path $CsvPath) | Should Be $true
        }

        # Chargement des donnees de l'etudiant
        $Rapport = $null
        if (Test-Path $JsonPath) { $Rapport = Get-Content $JsonPath | ConvertFrom-Json }
        elseif (Test-Path $CsvPath) { $Rapport = Import-Csv $CsvPath -Delimiter ";" -Encoding UTF8 }

        if ($Rapport) {
            # On attend environ 1/3 des serveurs (car on filtre que les 2016 sur les 50 totaux)
            # Donc > 10 est un bon seuil de securite.
            It "Le rapport contient un nombre coherent de serveurs traites (> 10)" {
                $Rapport.Count | Should BeGreaterThan 10
            }

            It "Le rapport contient la colonne 'ComputerName'" {
                $Proprietes = $Rapport | Get-Member -MemberType NoteProperty | Select -Expand Name
                ($Proprietes -contains "ComputerName") | Should Be $true
            }

            # Validation du statut WARNING
            It "Le rapport indique l'etat 'WARNING' pour le serveur concerne" {
                $Ligne = $Rapport | Where-Object { (Get-StringHash $_.ComputerName) -eq $H_WARNING }
                if ($Ligne) {
                    ($Ligne.Action + $Ligne.Etat) | Should Match "WARN|ATTENTION"
                }
                else {
                    throw "Le serveur Warning n'a pas ete trouve dans votre rapport."
                }
            }

            # Validation du statut MANUAL pour le DC
            It "Le rapport indique une intervention manuelle pour le Contrôleur de Domaine" {
                $Ligne = $Rapport | Where-Object { (Get-StringHash $_.ComputerName) -eq $H_DC }
                if ($Ligne) {
                    ($Ligne.Action + $Ligne.Etat) | Should Match "MANUAL|SKIP|NO|ERROR|CHECK"
                }
                else {
                    throw "Le Controleur de Domaine n'a pas ete trouve dans votre rapport."
                }
            }
        }
    }
}