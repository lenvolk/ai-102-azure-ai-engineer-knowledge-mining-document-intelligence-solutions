<#
.SYNOPSIS
    Initializes environment variables for Azure Document Intelligence API access.

.DESCRIPTION
    This script sets up the required environment variables (AI_SERVICE_KEY and AI_SERVICE_ENDPOINT) 
    for Azure Document Intelligence REST API operations. It validates the inputs and provides 
    feedback on the configuration.

.PARAMETER ServiceKey
    The subscription key for Azure Document Intelligence service.

.PARAMETER ServiceEndpoint
    The endpoint URL for Azure Document Intelligence service.

.PARAMETER ShowValues
    Switch to display the configured values (be careful with sensitive data).

.EXAMPLE
    .\Initialize-Variables.ps1 -ServiceKey "your-key" -ServiceEndpoint "https://your-endpoint.cognitiveservices.azure.com/"
    
.EXAMPLE
    .\Initialize-Variables.ps1 -ServiceKey "your-key" -ServiceEndpoint "https://your-endpoint.cognitiveservices.azure.com/" -ShowValues

.NOTES
    Version: 1.0
    Author: Generated from bash equivalent
    Compatible with PowerShell 5.1+
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ServiceKey = 'xxxx-xxx-xxxxxx',
    
    [Parameter(Mandatory = $false)]
    [string]$ServiceEndpoint = 'https://ai102-docuintel.cognitiveservices.azure.com/',
    
    [Parameter(Mandatory = $false)]
    [switch]$ShowValues
)

# Input validation
if ([string]::IsNullOrWhiteSpace($ServiceKey)) {
    throw "ServiceKey cannot be null or empty"
}

if ([string]::IsNullOrWhiteSpace($ServiceEndpoint)) {
    throw "ServiceEndpoint cannot be null or empty"
}

# Validate endpoint format
try {
    $uri = [System.Uri]::new($ServiceEndpoint)
    if ($uri.Scheme -notin @('http', 'https')) {
        throw "ServiceEndpoint must be a valid HTTP or HTTPS URL"
    }
}
catch {
    throw "ServiceEndpoint is not a valid URL: $ServiceEndpoint"
}

# Set environment variables
$env:AI_SERVICE_KEY = $ServiceKey
$env:AI_SERVICE_ENDPOINT = $ServiceEndpoint

# Provide feedback
Write-Host "Azure Document Intelligence environment variables configured successfully." -ForegroundColor Green

if ($ShowValues) {
    Write-Host "KEY = $env:AI_SERVICE_KEY" -ForegroundColor Yellow
    Write-Host "ENDPOINT = $env:AI_SERVICE_ENDPOINT" -ForegroundColor Yellow
} else {
    Write-Host "KEY = $($ServiceKey.Substring(0, [Math]::Min(8, $ServiceKey.Length)))..." -ForegroundColor Yellow
    Write-Host "ENDPOINT = $ServiceEndpoint" -ForegroundColor Yellow
}

# Return configuration object
return [PSCustomObject]@{
    ServiceKey = if ($ShowValues) { $ServiceKey } else { "$($ServiceKey.Substring(0, [Math]::Min(8, $ServiceKey.Length)))..." }
    ServiceEndpoint = $ServiceEndpoint
    ConfiguredAt = Get-Date
}
