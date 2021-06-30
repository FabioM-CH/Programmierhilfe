<#
.SYNOPSIS
    Virutal Network Deployment Mannoni Tenant
    VM Deployment Mannoni Tenant
.DESCRIPTION
    Deployment File

.NOTES
  Version:        1.0
  Author:         Fabio Mannoni
  Creation Date:  15.06.2021

.CHANGES

#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

# Load global parameters file
Write-Host -ForegroundColor Cyan "`t Loading configuration file"
. "$PSScriptRoot\parameter.ps1"
WriteSuccess "`t Config file successfully loaded"

# Set Error Action to Stop
$ErrorActionPreference = "Stop"

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

# Grab Time and start Transcript
Start-Transcript -Path "$psscriptroot\deloyment.log"
$StartDateTime = Get-Date
WriteInfoHighlighted "Script started at $StartDateTime"

# Create local admin credentials for vms
$credential = Get-Credential -Username $locadminusername -Message "Please enter complex password for user $locadminusername"

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#region Azure Logon

# Logon to the Azure Subscription and set the right context
WriteInfoHighlighted "`t Logon to the Azure Subscription and set the right context"
Connect-AzAccount -TenantId $paramglobal.tenantid -Subscription $paramglobal.subscriptionid
WriteSuccess "`t Azure context sucessfully set"

# Get account name for later tagging of resources
$azaccount = Get-AzContext

#endregion


#region network deployment

# Deploy resource group
WriteInfoHighlighted "`t creating resource group for VNet"
try {
	New-AzResourceGroup -Name $paramvnet.resourcegroup -Location $paramvnet.location -Tag @{Creator=$azaccount.account.Id; "CreationDate"=$creationDate}
} catch {
	WriteErrorAndExitAndExit ("`t failed to create resource group " + $paramvm.resourcegroup)
}
WriteSuccess ("`t resource group " + $paramvm.resourcegroup + " created successfully")

# Deploy VNet
WriteInfoHighlighted "`t creating VNet"
try {
	$vnetwork = New-AzVirtualNetwork -Name $paramvnet.Name -Location $paramvnet.location -ResourceGroupName $paramvnet.resourcegroup -AddressPrefix $paramvnet.netaddressprefix -Tag @{Creator=$azaccount.account.Id; "CreationDate"=$creationDate}
} catch {
	WriteErrorAndExitAndExit ("`t failed to create VNet " + $paramvnet.Name)
}
WriteSuccess ("`t VNet " + $paramvnet.Name + " created successfully")

# Add subnet
WriteInfoHighlighted "`t adding subnet"
try {
    Add-AzVirtualNetworkSubnetConfig -name $paramvnet.privatesubnetname -VirtualNetwork $vnetwork -AddressPrefix $paramvnet.privatesubnetaddressprefix -Tag @{Creator=$azaccount.account.Id; "CreationDate"=$creationDate}
} catch {
	WriteErrorAndExitAndExit ("`t failed to create subnet " + $paramvnet.privatesubnetname)
}
WriteSuccess ("`t subnet " + $paramvnet.privatesubnetname + " created successfully")

# Associate subnet to VNet
WriteInfoHighlighted "`t Associate subnet to VNet"
try {
    $vnetwork | Set-AzVirtualNetwork
} catch {
	WriteErrorAndExitAndExit ("`t failed to associate subnet " + $paramvnet.privatesubnetname)
}
WriteSuccess ("`t subnet " + $paramvnet.privatesubnetname + " associated successfully")

#endregion

#region VM deployment

# Deploy resource group
WriteInfoHighlighted "`t creating resource groups"
try {
	New-AzResourceGroup -Name $paramvm.resourcegroup -Location $paramvm.location -Tag @{Creator=$azaccount.account.Id; "CreationDate"=$creationDate}
} catch {
	WriteErrorAndExitAndExit ("`t failed to create resource group " + $paramvm.resourcegroup)
}
WriteSuccess ("`t resource group " + $paramvm.resourcegroup + " created successfully")

# Get network information
$vnet = Get-AzVirtualNetwork -Name $paramvnet.netname -resourcegroupname $paramvnet.resourcegroup
$subnetconfig = Get-AzVirtualNetworkSubnetConfig -Name $paramvnet.privatesubnetname -VirtualNetwork $vnet

# Deploy network security group
WriteInfoHighlighted ("`t creating network security group for " + $paramvm.Name)
try {
	$nsg = New-AzNetworkSecurityGroup -Name $paramvm.nsgname -resourcegroupname $paramvm.resourcegroup -Location $paramvm.location -SecurityRules $nsgrule1 -Tag @{Creator=$azaccount.account.Id; "CreationDate"=$creationDate}
} catch {
	WriteErrorAndExit ("`t failed to create network security group for " + $paramvm)
}
WriteSuccess ("`t network security group " + $paramvm.nsgname + " created successfully")

# Deploy network interface card and assign it to the subnet
$ipconfig = New-AzNetworkInterfaceIpConfig -Name "IPConfigPrivate" -PrivateIpAddressversion IPv4 -PrivateIpAddress $paramvm.nicip -Subnetid $subnetconfig.Id
WriteInfoHighlighted ("`t creating network interface for " + $paramvm.Name)
try {
	$nic = New-AzNetworkInterface -Name $paramvm.nicname -resourcegroupname $paramvm.resourcegroup -Location $paramvm.location `
		-NetworkSecurityGroupId $nsg.Id -IpConfiguration $ipconfig -Tag @{Creator=$azaccount.account.Id; "Creation date"=$creationDate}
} catch {
	WriteErrorAndExit ("`t failed to create network interface for " + $paramvm.Name)
}
WriteSuccess ("`t network interface for " + $paramvm.Name + " created successfully")

# Build VM from parameters
$vmconfig = New-AzVMConfig -VMName $paramvm.Name -VMSize $paramvm.size -LicenseType $paramvm.licensetype
$vmconfig = Set-AzVMOSDisk -VM $vmconfig -Name $paramvm.osdisk -Caching $paramvm.osdiskcaching -CreateOption fromImage
$vmconfig = Set-AzVMOperatingSystem -VM $vmconfig -Windows -ComputerName $paramvm.Name -Credential $credential -ProvisionVMAgent
$vmconfig = Set-AzVMSourceImage -VM $vmconfig -PublisherName $paramvm.publishername -Offer $paramvm.offer -Skus $paramvm.sku -Version latest
$vmconfig = Add-AzVMNetworkInterface -VM $vmconfig -Id $nic.Id
$vmconfig = Set-AzVMBootDiagnostic -VM $vmconfig -Enable -resourcegroupname $paramstoragediag.resourcegroup -StorageAccountName $paramstoragediag.Name

# Deploy VM
WriteInfoHighlighted ("`t deploying vm " + $paramvm.Name)
try {
	New-AzVM -resourcegroupname $paramvm.resourcegroup -Location $paramvm.location -VM $vmconfig -PublicIpAddressName $paramvnet.publicipaddressname -AllocationMethod $paramvnet.publicipallocation -Verbose -Tag @{Creator=$azaccount.account.Id; "CreationDate"=$creationDate} -DisableBginfoExtension
} catch {
	WriteErrorAndExit ("`t failed to deploy vm " + $paramvm.Name)
}
WriteSuccess ("`t vm " + $paramvm.Name + " deployed successfully")

#endregion