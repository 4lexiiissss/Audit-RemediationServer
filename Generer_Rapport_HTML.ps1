$CsvPath = "Resultat.csv"

# pour importer le csv
$Data = Import-Csv -Path $CsvPath -Delimiter ";" -Encoding UTF8

$TotalServeurs = $Data.Count
$ServeursSains = ($Data | Where-Object { $_.Action -eq 'OK' }).Count
$PourcentageSain = 0

if ($TotalServeurs -gt 0) {
    $PourcentageSain = (($ServeursSains / $TotalServeurs) * 100)
}

$ServeursAlerte = $Data | Where-Object { $_.Action -in @('STOPPED', 'WARNING', 'MANUAL_CHECK') }
$NombreAlertes = $ServeursAlerte.Count

$HtmlContent = @"
<html>
<head>
    <title>Rapport DSI</title>
    <style>
        body { 
            background-color: #f4f4f4; 
            text-align: center; 
            font-family: Arial, sans-serif; 
        }
        table { 
            margin-left: auto; 
            margin-right: auto; 
            border-collapse: collapse; 
            background-color: white;
        }
        th, td { 
            padding: 10px; 
        }
    </style>
</head>
<body>
    <h1>Rapport des alertes serveurs</h1>
    <h3>Pourcentage de serveurs sains (OK) : $PourcentageSain %</h3>
    
    <table border="1">
        <tr>
            <th>Nom</th>
            <th>OS</th>
            <th>Role</th>
            <th>Version</th>
            <th>Action</th>
        </tr>
"@

foreach ($Serveur in $ServeursAlerte) {
    $couleur = "white"
    if ($Serveur.Action -eq "STOPPED") { $couleur = "#ffcccc" }
    if ($Serveur.Action -eq "WARNING") { $couleur = "#ffe5b4" }
    
    $HtmlContent += "        <tr style='background-color: $couleur;'>`n"
    $HtmlContent += "            <td>$($Serveur.ComputerName)</td>`n"
    $HtmlContent += "            <td>$($Serveur.OS)</td>`n"
    $HtmlContent += "            <td>$($Serveur.Role)</td>`n"
    $HtmlContent += "            <td>$($Serveur.Version)</td>`n"
    $HtmlContent += "            <td>$($Serveur.Action)</td>`n"
    $HtmlContent += "        </tr>`n"
}

$HtmlContent += @"
    </table>
</body>
</html>
"@

$DateDuJour = Get-Date -Format "yyyy-MM-dd"
$NomFichier = "${NombreAlertes}_Alertes_${DateDuJour}.html"

$HtmlContent | Out-File -FilePath $NomFichier -Encoding UTF8