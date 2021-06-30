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

#>

#-----------------------------------------------------------[Functions]------------------------------------------------------------

# Functions for text formating with write-host for showing deployment progress

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

#---------------------------------------------------------[Naming Parameters]------------------------------------------------------

<#

Prefix                      fab  (fabio)
Ressource Group             rg
NIC                         nic
Network Security Group      nsg
Location                    ane (Azure North Europe)

# Network

Network Name                fab-vnet1-ane
Ressource Group             fab-rg-vnet1-ane
Adress Range                10.0.0.0/16
Subnet Name                 ServerSubnet
Subnet Range                10.1.1.0/24

# VM

Name                        fab-vm1-ane
Ressource Group             fab-rg-vm1-ane
Disk Name                   fab-osdisk-vm1-ane
Network Security Group      fab-nsg-vm1-ane
NIC                         fab-nic-vm1-ane
Public IP                   fab-puip-vm1-ane


#>


#---------------------------------------------------------[Global Parameters]------------------------------------------------------

# Global parameters like subscription id

# Region
# Set region which will be used

# North Europe		= northeurope
# West Europe		= westeurope


$region = "northeurope"

# Subscription id

$paramglobal = @{}
$paramglobal.Add('subscriptionid','ce1116bc-f26b-4ff0-8c1e-98b52a8f3ee2')
$paramglobal.Add('tenantid','3355afa7-9881-432d-a581-caeac445d097')

# Username local administrator VMs

$locadminusername = "fabio"

#---------------------------------------------------------[Tag Parameters]----------------------------------------------------------

$creationDate = Get-Date -DisplayHint Date -Format dd.MM.yyyy

# Creator will be set in deployment.ps1 as we need the account logon in Azure first

#---------------------------------------------------------[VNET Parameters]--------------------------------------------------------

# VNET parameters

# Change network settings to your needs

$paramvnet = @{}
$paramvnet.Add('resourcegroup','fab-rg-vnet1-ane')
$paramvnet.Add('location',$region)
$paramvnet.Add('netname','fab-vnet1-ane')
$paramvnet.Add('netaddressprefix','10.0.0.0/16')
$paramvnet.Add('privatesubnetname','ServerSubnet')
$paramvnet.Add('privatesubnetaddressprefix','10.1.1.0/24')
$paramvnet.Add('publicipaddressname','fab-puip-vm1-ane')
$paramvnet.Add('publicipallocation','static')



#---------------------------------------------------------[NSG Parameters]---------------------------------------------------------

#Network Security Group rules for RDP

$nsgrule1 = New-AzNetworkSecurityRuleConfig -Name RDP -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389



#---------------------------------------------------------[VMS Parameters]---------------------------------------------------------

# If nicip = empty, DHCP
# LicensType sets Azure Hybrid Benefit

$paramvm = @{}
$paramvm.Add('location',$region)
$paramvm.Add('resourcegroup','fab-rg-vm1-ane')
$paramvm.Add('name','fab-vm1-ane')
$paramvm.Add('nsgname','fab-nsg-vm1-ane')
$paramvm.Add('nicip','')
$paramvm.Add('nicname','fab-nic-vm1-ane')
$paramvm.Add('size','Standard_D2s_v3')
$paramvm.Add('osdisk','fab-osdisk-vm1-ane')
$paramvm.Add('osdiskcaching','ReadWrite')
$paramvm.Add('storageaccounttype','StandardSSD_LRS')
$paramvm.Add('publishername','MicrosoftWindowsServer')
$paramvm.Add('offer','WindowsServer')
$paramvm.Add('sku','2019-Datacenter')
$paramvm.Add('licensetype','Windows_Server')
$paramvm.Add('datadiskstorageaccounttype','StandardSSD_LRS')

