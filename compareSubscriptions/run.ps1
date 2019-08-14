using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

#Interact with query parameters or the body of the request.
$compareSubscriptions = $Request.Query.compareSubscriptions
if (-not $compareSubscriptions) {
    $compareSubscriptions = $Request.Body.compareSubscriptions
}

# Change to the subscriptionID your Managed Service Identity has permissions too
# (Storage account should be located in this subscription as well)
$storageSubscription = Get-AzSubscription -SubscriptionId "<SubscriptionID StorageAccount>"
Set-AzContext -Subscription $storageSubscription

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Table storage details
# Edit when required
$resourceGroup = "rg-Lighthouse" 
$storageAccountName = "adrmsubscriptions"
$tableName = "subscriptions"
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName
$ctx = $storageAccount.Context
$cloudTable = (Get-AzStorageTable –Name $tableName –Context $ctx).CloudTable
$partitionKey1 = "partition1"

# Get current subscriptions stored in Table
$currentSubscriptions = Get-AzTableRow -table $cloudTable

if ($currentSubscriptions) { 
# Compare stored subscriptions with current access and store differences
$comparison = Compare-Object -ReferenceObject $currentSubscriptions.RowKey -DifferenceObject $subscriptions.Id

# Only returns first result. Next subscription will be added on next runtime of Logic App 
# Temporary situation to prevent bulk onboarding
Write-Host "Comparison 0: " $comparison[0]
$result = $comparison[0].InputObject

}
else
{
    $result = "No subscriptions found in table, adding (context)MSP Tenant"
    $subscriptionId = (get-azcontext).subscription.id
    Add-AzTableRow `
    -table $cloudTable `
    -partitionKey $partitionKey1 `
    -rowKey ("$subscriptionId") -property @{"Onboarded"="False"}
}
# returns differences
if ($result) {
    $status = [HttpStatusCode]::OK
    $body = "$result"
}
else {
    $status = [HttpStatusCode]::OK
    $body = "No new subscriptions detected"
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})
