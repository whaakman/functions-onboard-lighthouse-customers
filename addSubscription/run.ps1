using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$subscriptionId = $Request.Query.subscriptionId
if (-not $subscriptionId) {
    $subscriptionId = $Request.Body.subscriptionId
}

# Change to the subscriptionID your Managed Service Identity has permissions too
# (Storage account should be located in this subscription as well)
$storageSubscription = Get-AzSubscription -SubscriptionId "<SubscriptionID StorageAccount>"
Set-AzContext -Subscription $storageSubscription


# Table storage details
$resourceGroup = "rg-Lighthouse"
$storageAccountName = "adrmsubscriptions"
$tableName = "subscriptions"
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName
$ctx = $storageAccount.Context
$cloudTable = (Get-AzStorageTable –Name $tableName –Context $ctx).CloudTable
$partitionKey1 = "partition1"

# Add Subscription To Table Storage
Add-AzTableRow `
-table $cloudTable `
-partitionKey $partitionKey1 `
-rowKey ("$subscriptionId") -property @{"Onboarded"="true"}

if ($subscriptionId) {
    $status = [HttpStatusCode]::OK
    $body = "Added $subscriptionId"
}
else {
    $status = [HttpStatusCode]::BadRequest
    $body = "Please pass a name on the query string or in the request body."
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})
