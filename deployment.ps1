<#
.SYNOPSIS
    Virutal Network Deployment Mannoni Tenant
    VM Deployment Mannoni Tenant
.DESCRIPTION
    Deployment File

.NOTES
  Version:        3.0
  Author:         Fabio Mannoni
  Creation Date:  15.06.2021

.CHANGES
Diverse Anpassungen, Fehler beheben	21.06.2021 - 23.06.2021
Diverse Anpassungen, Fehler beheben	28.06.2021 - 30.06.2021
#>

#---------------------------------------------------------[Script Parameter]------------------------------------------------------

# Parameter Datei laden
Write-Host -ForegroundColor Cyan "`t Lade Parameter Datei"
. "$PSScriptRoot\parameter.ps1"
WriteSuccess "`t Parameter Datei erfolgreich geladen"

# Verhalten bei Scriptfehlern auf "Stop" setzen
$ErrorActionPreference = "Stop"

#---------------------------------------------------------[Vorbereitungen]--------------------------------------------------------

# Datum und Uhrzeit ermitteln und Log starten
Start-Transcript -Path "$psscriptroot\deloyment.log"
$StartDateTime = Get-Date
WriteInfoHighlighted "Script started at $StartDateTime"

# Passwort für Administrator in VM abfragen
$credential = Get-Credential -Username $locadminusername -Message ("Bitte komplexes Passwort für " + $locadminusername + " eingeben")

#-----------------------------------------------------------[Ausführung]------------------------------------------------------------

#region Azure Logon

# In Azure anmelden mit Subscription ID und Tenant ID
WriteInfoHighlighted "`t Anmeldung in Azure wird gestartet"
Connect-AzAccount -TenantId $paramglobal.tenantid -Subscription $paramglobal.subscriptionid
WriteSuccess "`t Anmeldung in Azure war erfolgreich!"

# Benutzernamen abfragen für Tags
$azaccount = Get-AzContext

#endregion


#region Netzwerk Deployment

# Ressource Gruppe für vNET deployen
WriteInfoHighlighted ("`t Erstelle die Ressource Gruppe für das vNET " + $paramvnet.Name)
try {
	New-AzResourceGroup -Name $paramvnet.resourcegroup -Location $paramvnet.location -Tag @{Ersteller=$azaccount.account.Id; "ErstellDatum"=$creationDate}
} catch {
	WriteErrorAndExitAndExit ("`t Erstellung der Ressource Gruppe " + $paramvnet.resourcegroup + " fehlgeschlagen")
}
WriteSuccess ("`t Ressource Gruppe " + $paramvm.resourcegroup + " erfolgreich erstellt")

# VNet deployen
WriteInfoHighlighted ("`t Erstelle VNet " + $paramvnet.NetName)
try {
	$vnetwork = New-AzVirtualNetwork -Name $paramvnet.NetName -Location $paramvnet.location -ResourceGroupName $paramvnet.resourcegroup -AddressPrefix $paramvnet.netaddressprefix -Tag @{Ersteller=$azaccount.account.Id; "ErstellDatum"=$creationDate}
} catch {
	WriteErrorAndExitAndExit ("`t Erstellung des vNET " + $paramvnet.NetName + "fehlgeschlagen" )
}
WriteSuccess ("`t vNET " + $paramvnet.NetName + " erfolgreich erstellt")

# Subnet erstellen
WriteInfoHighlighted ("`t Erstelle Subnet" + $paramvnet.privatesubnetname)
try {
    Add-AzVirtualNetworkSubnetConfig -name $paramvnet.privatesubnetname -VirtualNetwork $vnetwork -AddressPrefix $paramvnet.privatesubnetaddressprefix
} catch {
	WriteErrorAndExitAndExit ("`t Erstellung des Subnets " + $paramvnet.privatesubnetname + " fehlgeschlagen")
}
WriteSuccess ("`t Subnet " + $paramvnet.privatesubnetname + " erfolgreich erstellt")

# Subnet dem vNET hinzufügen
WriteInfoHighlighted "`t Füge Subnet dem vNet hinzu"
try {
    $vnetwork | Set-AzVirtualNetwork
} catch {
	WriteErrorAndExitAndExit ("`t Subnet dem vNET hinzufügen fehlgeschlagen")
}
WriteSuccess ("`t Subnet erfolgreich dem vNET " + $paramvnet.NetName + " hinzugefügt")

#endregion

#region VM Deployment

# Ressource Gruppe für VM deployen
WriteInfoHighlighted ("`t Erstelle die Ressource Gruppe für die VM " + $paramvm.Name)
try {
	New-AzResourceGroup -Name $paramvm.resourcegroup -Location $paramvm.location -Tag @{Ersteller=$azaccount.account.Id; "ErstellDatum"=$creationDate}
} catch {
	WriteErrorAndExitAndExit ("`t Erstellung der Ressource Gruppe " + $paramvm.resourcegroup + " fehlgeschlagen")
}
WriteSuccess ("`t Ressource Gruppe " + $paramvm.resourcegroup + " erfolgreich erstellt")

# Netzwerk Informationen für VM Konfiguration abfragen
$vnet = Get-AzVirtualNetwork -Name $paramvnet.netname -resourcegroupname $paramvnet.resourcegroup
$subnetconfig = Get-AzVirtualNetworkSubnetConfig -Name $paramvnet.privatesubnetname -VirtualNetwork $vnet

# Öffentliche IP Adresse für VM erstellen
WriteInfoHighlighted ("`t Erstelle öffentliche IP für die VM " + $paramvm.Name)
try {
	$publicIp = New-AzPublicIpAddress -Name $paramvnet.publicipaddressname -ResourceGroupName $paramvm.resourcegroup -AllocationMethod $paramvnet.publicipallocation -Location $region
} catch {
	WriteErrorAndExitAndExit ("`t Erstellung der öffentlichen IP " + $paramvnet.publicipaddressname + " fehlgeschlagen")
}
WriteSuccess ("`t Öffentliche IP " + $paramvnet.publicipaddressname + " erfolgreich erstellt")

# NSG für VM erstellen
WriteInfoHighlighted ("`t Erstelle die NSG für die VM " + $paramvm.Name)
try {
	$nsg = New-AzNetworkSecurityGroup -Name $paramvm.nsgname -resourcegroupname $paramvm.resourcegroup -Location $paramvm.location -SecurityRules $nsgrule1 -Tag @{Ersteller=$azaccount.account.Id; "ErstellDatum"=$creationDate}
} catch {
	WriteErrorAndExitAndExit ("`t Erstellung der NSG " + $paramvm.nsgname + " fehlgeschlagen")
}
WriteSuccess ("`t NSG " + $paramvnet.nsgname + " erfolgreich erstellt")

# Erstelle Konfiguration der Netzwerkkarte
WriteInfoHighlighted ("`t Erstelle Konfiguration der Netzwerkkarte für VM " + $paramvm.Name)
try {
    $ipconfig = New-AzNetworkInterfaceIpConfig -Name "IPConfigPrivate" -PrivateIpAddressversion IPv4 -PrivateIpAddress $paramvm.nicip -Subnetid $subnetconfig.Id -PublicIpAddressId $publicip.Id
} catch {
	WriteErrorAndExit ("`t Erstellung der Konfiguration der Netzwerkkarte für VM " + $paramvm.Name + " fehlgeschlagen")
}
WriteSuccess ("`t Konfiguration der Netzwerkkarte für VM " + $paramvnet.Name + " erfolgreich erstellt")

# Netzwerkkarte erstellen und dem Subnet zuweisen
WriteInfoHighlighted ("`t Erstelle Netzwerkkarte für VM " + $paramvm.Name)
try {
	$nic = New-AzNetworkInterface -Name $paramvm.nicname -resourcegroupname $paramvm.resourcegroup -Location $paramvm.location `
		-NetworkSecurityGroupId $nsg.Id -IpConfiguration $ipconfig -Tag @{Ersteller=$azaccount.account.Id; "ErstellDatum"=$creationDate}
} catch {
	WriteErrorAndExit ("`t Erstellung der Netzwerkkarte für VM " + $paramvm.Name + " fehlgeschlagen")
}
WriteSuccess ("`t Netzwerkkarte für VM " + $paramvnet.Name + " erfolgreich erstellt")

# VM Konfiguration zusammenstellen
$vmconfig = New-AzVMConfig -VMName $paramvm.Name -VMSize $paramvm.size -LicenseType $paramvm.licensetype					#Name, VM Grösse, Lizenzierung
$vmconfig = Set-AzVMOSDisk -VM $vmconfig -Name $paramvm.osdisk -Caching $paramvm.osdiskcaching -CreateOption fromImage				#Diskname (C:), Cache
$vmconfig = Set-AzVMOperatingSystem -VM $vmconfig -Windows -ComputerName $paramvm.Name -Credential $credential -ProvisionVMAgent		#Betriebssystem, Computername, Admin Account, AzureVMAgent	
$vmconfig = Set-AzVMSourceImage -VM $vmconfig -PublisherName $paramvm.publishername -Offer $paramvm.offer -Skus $paramvm.sku -Version latest	#Betriebssystem Hersteller, Version
$vmconfig = Add-AzVMNetworkInterface -VM $vmconfig -Id $nic.Id											#Netzwerkkarte
$vmconfig = Set-AzVMBootDiagnostic -VM $vmconfig -Enable -resourcegroupname $paramstoragediag.resourcegroup -StorageAccountName $paramstoragediag.Name	#BootDiagnose, StorageAccount

# VM Deployment
WriteInfoHighlighted ("`t Erstelle VM " + $paramvm.Name)
try {
	New-AzVM -resourcegroupname $paramvm.resourcegroup -Location $paramvm.location -VM $vmconfig -Verbose -DisableBginfoExtension -Tag @{Ersteller=$azaccount.account.Id; "ErstellDatum"=$creationDate} 
} catch {
	WriteErrorAndExit ("`t Erstellung der VM " + $paramvm.Name + " fehlgeschlagen")
}
WriteSuccess ("`t VM " + $paramvm.Name + " erfolgreich erstellt")

#endregion
