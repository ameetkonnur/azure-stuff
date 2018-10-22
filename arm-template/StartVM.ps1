<#
Start a VM. Triggered by Azure Monitor Alerts 
#>

param ( 
    [object]$WebhookData
)

if ($WebhookData -ne $null) {
    if (-Not $WebhookData.RequestBody)
    {
        $WebhookData = (ConvertFrom-Json -InputObject $WebhookData)
    }
    # Collect properties of WebhookData.
    #Write-Output "webhookdata $WebhookData"
    $WebhookName    =   $WebhookData.WebhookName
    $WebhookBody    =   $WebhookData.RequestBody
    $WebhookHeaders =   $WebhookData.RequestHeader
       
    # Information on the webhook name that called This
    Write-Output "This runbook was started from webhook $WebhookName."
    #Write-Output "Webhook Request $WebhookBody"
       
    # Obtain the WebhookBody containing the AlertContext
    #$WebhookBody = (ConvertFrom-Json -InputObject $WebhookBody)
    Write-Output "`nWEBHOOK BODY"
    Write-Output "============="
    $WebhookBody = (ConvertFrom-Json -InputObject $WebhookBody)
    Write-Output $WebhookBody.data

    # Obtain the AlertContext
    $AlertContext = $WebhookBody.data.context

    # Some selected AlertContext information
    Write-Output "`nALERT CONTEXT DATA"
    Write-Output "==================="
    Write-Output $AlertContext
    Write-Output $AlertContext.name
    Write-Output $AlertContext.subscriptionId
    Write-Output $AlertContext.resourceGroupName
    Write-Output $AlertContext.resourceName
    Write-Output $AlertContext.resourceType
    Write-Output $AlertContext.resourceId
    Write-Output $AlertContext.timestamp
      
    $connectionName = "AzureRunAsConnection"
    try
    {
        # Get the connection "AzureRunAsConnection "
        $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

        "Logging in to Azure..."
        Add-AzureRmAccount `
            -ServicePrincipal `
            -TenantId $servicePrincipalConnection.TenantId `
            -ApplicationId $servicePrincipalConnection.ApplicationId `
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
    }
    catch 
    {
        if (!$servicePrincipalConnection)
        {
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        } else{
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }

	
    Write-Output "~$($AlertContext.resourceName)"
    $VMName = $AlertContext.resourceName
    $prefix = $VMName.Substring(0,$VMName.Length - 3)
    $suffix = $VMName[-3..-1] -join ''
    $suffix = ([convert]::ToInt32($suffix) + 1).ToString('D3')
    $StartVMName = $prefix + $suffix
    Write-Verbose "Start VM $($StartVMName) using Resource Manager"
    $Status = Start-AzureRmVM -Name $StartVMName -ResourceGroupName $AlertContext.resourceGroupName
    
    if($Status -eq $null)
    {
        Write-Output "Error occured while starting the Virtual Machine. $StartVMName"
    }
    else
    {
       Write-Output "Successfully started the VM $StartVMName"
    }
}
else 
{
    Write-Error "This runbook is meant to only be started from a webhook." 
}