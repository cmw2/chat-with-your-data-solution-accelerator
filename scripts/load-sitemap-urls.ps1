param (
    [Parameter(Mandatory = $true)]
    [string]$BackendUrl,
    [Parameter(Mandatory = $true)]
    [string]$BackendFunctionKey,
    [Parameter(Mandatory = $true)]
    [string]$SitemapUrl
)

# Read the sitemap.xml file
$sitemapContent = Invoke-WebRequest -Uri $SitemapUrl | Select-Object -ExpandProperty Content
$xml = [xml]$sitemapContent
$urls = $xml.urlset.url.loc

# Call the Azure Function for each URL
$functionUrl = "$BackendUrl/api/AddURLEmbeddings"
$headers = @{
    "x-functions-key" = $BackendFunctionKey
    "clientId" = "clientKey"
}
$failureCount = 0

foreach ($url in $urls) {
    if ($url -match '\.(xls|xlsx|doc|ppt|pptx)$') {
        Write-Host "Skipping URL $url as it's extension is not supported."
        continue
    }

    Write-Host "Submitting URL $url"

    $body = @{
        url = $url
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $functionUrl -Method Post -Body $body -Headers $headers -ContentType "application/json"
        Write-Host "Success: Submitted URL $url. Response: $response"
    } catch {
        Write-Host "Status: " $_.Exception.Response.StatusCode
        Write-Host "Failure: Failed to submit URL $url. Error: $_"
        $failureCount++
    }

    if ($failureCount -gt 3) {
        Write-Host "Exiting loop due to more than 3 failures."
        break
    }
}
