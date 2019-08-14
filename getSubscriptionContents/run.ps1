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

Set-AzContext -SubscriptionId $subscriptionId   


$resources = get-azresource
$resources = ($resources.ResourceType |group)
$result = $resources |ConvertTo-Json

if ($result) {
    $status = [HttpStatusCode]::OK
    $body = "$result"
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
