<#
.SYNOPSIS
    Virutal Network Deployment Mannoni Tenant
    VM Deployment Mannoni Tenant
.DESCRIPTION
    Parameter File

.NOTES
  Version:        1.0
  Author:         Fabio Mannoni
  Creation Date:  15.06.2021

.CHANGES
Diverse Anpassungen, Fehler beheben	21.06.2021 - 23.06.2021
Diverse Anpassungen, Fehler beheben	28.06.2021 - 30.06.2021
#>

#-----------------------------------------------------------[Funktionen]------------------------------------------------------------

# Funktionen für Textausgabe während Deployment definieren

function WriteInfo ($message) {
	Write-Host $message
}

function WriteInfoHighlighted ($message) {
	Write-Host $message -ForegroundColor Cyan
}

function WriteSuccess ($message) {
	Write-Host $message -ForegroundColor Green
}

function WriteError ($message) {
	Write-Host $message -ForegroundColor Red
}

function WriteErrorAndExit ($message) {
	Write-Host $message -ForegroundColor Red
	Write-Host "Press enter to continue ..."
	Stop-Transcript
	Read-Host | Out-Null
	exit
}

#---------------------------------------------------------[Namens- Konvention]------------------------------------------------------

<#
# Ressourcen

Prefix                      	fab  (fabio)
Ressource Gruppe		rg
Netzwerkkarte	              	nic
Netzwerk Sicherheits Gruppe	nsg
Lokation	                ane (Azure North Europe)

# Netzwerk

Netzwerk Name	                fab-vnet1-ane
Ressource Gruppe	        fab-rg-vnet1-ane
Adress Bereich Netzwerk         10.0.0.0/16
Subnet Name	                ServerSubnet
Adress Bereich Subnet		10.1.1.0/24

# VM

Name                        	fab-vm1-ane
Ressource Gruppe	        fab-rg-vm1-ane
Disk Name C:\	                fab-osdisk-vm1-ane
Netzwerk Sicherheits Gruppe     fab-nsg-vm1-ane
Netzwerkkarte                   fab-nic-vm1-ane
Öffentliche IP                  fab-puip-vm1-ane


#>


#---------------------------------------------------------[Allgemeine Parameter]------------------------------------------------------

# Region
# Welche Azure Region wird genutzt

# North Europe		= northeurope
# West Europe		= westeurope


$region = "northeurope"


$paramglobal = @{}
$paramglobal.Add('subscriptionid','ce1116bc-f26b-4ff0-8c1e-98b52a8f3ee2')	# Subscription ID
$paramglobal.Add('tenantid','3355afa7-9881-432d-a581-caeac445d097')		# Tenant ID


$locadminusername = "fabio"						# Benutzername für den Administrator Account in der VM

#---------------------------------------------------------[Tag Parameter]----------------------------------------------------------

$creationDate = Get-Date -DisplayHint Date -Format dd.MM.yyyy		# Datum und Zeit ermitteln

# Ersteller wird im Deployment Script abgefragt um Ersteller zu taggen

#---------------------------------------------------------[VNET Parameter]--------------------------------------------------------


$paramvnet = @{}
$paramvnet.Add('resourcegroup','fab-rg-vnet1-ane')			# Name der Ressource Gruppe
$paramvnet.Add('location',$region)					# Lokation
$paramvnet.Add('netname','fab-vnet1-ane')				# Netzwerk Name
$paramvnet.Add('netaddressprefix','10.0.0.0/16')			# Adress Bereich Netzwerk
$paramvnet.Add('privatesubnetname','ServerSubnet')			# Subnet Name
$paramvnet.Add('privatesubnetaddressprefix','10.1.1.0/24')		# Adress Bereich Subnet
$paramvnet.Add('publicipaddressname','fab-puip-vm1-ane')		# Öffentliche IP Name
$paramvnet.Add('publicipallocation','static')				# Statische oder dynamische öffentliche IP



#---------------------------------------------------------[NSG Parameter]---------------------------------------------------------

# NSG für RDP Zugriff vom Internet öffnen (Port 3389)

$nsgrule1 = New-AzNetworkSecurityRuleConfig -Name RDP -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389

#---------------------------------------------------------[Storage Parameter]-----------------------------------------------------

# Angaben für den Storage Account den wir für die Boot Diagnose der VM brauchen

$paramstoragediag = @{}
$paramstoragediag.Add('name','mmstodiag1')				# Name des Storage Accounts
$paramstoragediag.Add('resourcegroup','mm-rg-stodiag1-cwe')		# Name der Ressource Gruppe


#---------------------------------------------------------[VM Parameter]---------------------------------------------------------


$paramvm = @{}
$paramvm.Add('location',$region)					# Lokation
$paramvm.Add('resourcegroup','fab-rg-vm1-ane')				# Name der Ressource Gruppe
$paramvm.Add('name','fab-vm1-ane')					# Name der VM
$paramvm.Add('nsgname','fab-nsg-vm1-ane')				# Name der Netzwerk Sicherheits Gruppe	
$paramvm.Add('nicip','')						# private IP Adresse, wenn leer = DHCP
$paramvm.Add('nicname','fab-nic-vm1-ane')				# Name der Netzwerkkarte
$paramvm.Add('size','Standard_D2s_v3')					# Grösse, Typ der VM
$paramvm.Add('osdisk','fab-osdisk-vm1-ane')				# Name der Disk (C:\)
$paramvm.Add('osdiskcaching','ReadWrite')				# Caching der Disk (C:\)
$paramvm.Add('storageaccounttype','StandardSSD_LRS')			# Art der Disk (C:\), HDD, SSD
$paramvm.Add('publishername','MicrosoftWindowsServer')			# Herstellername Betriebssystem
$paramvm.Add('offer','WindowsServer')					# Betriebssystem
$paramvm.Add('sku','2019-Datacenter')					# Betriebssystem Version
$paramvm.Add('licensetype','Windows_Server')				# Lizenztyp, wenn Lizenz schon vorhanden, günstiger = Windows_Server
$paramvm.Add('datadiskstorageaccounttype','StandardSSD_LRS')		# Art der Disk (D:\), HDD, SSD

