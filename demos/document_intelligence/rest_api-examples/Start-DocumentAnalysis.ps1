<#
.SYNOPSIS
    Starts document analysis using Azure Document Intelligence API.

.DESCRIPTION
    This script submits a document for analysis using Azure Document Intelligence REST API.
    It supports both URL-based and local file analysis and returns the operation details.

.PARAMETER ModelId
    The Document Intelligence model ID to use for analysis (e.g., 'prebuilt-receipt', 'prebuilt-invoice').

.PARAMETER DocumentUrl
    URL of the document to analyze. Use this for documents accessible via HTTP/HTTPS.

.PARAMETER DocumentPath
    Local path to the document file. The file will be uploaded for analysis.

.PARAMETER ServiceKey
    Azure Document Intelligence service key. If not provided, uses AI_SERVICE_KEY environment variable.

.PARAMETER ServiceEndpoint
    Azure Document Intelligence service endpoint. If not provided, uses AI_SERVICE_ENDPOINT environment variable.

.PARAMETER ApiVersion
    API version to use. Default is '2024-02-29-preview'.

.PARAMETER OutputFormat
    Output format for the response. Options: 'Json', 'Object'. Default is 'Object'.

.EXAMPLE
    .\Start-DocumentAnalysis.ps1 -ModelId "prebuilt-receipt" -DocumentUrl "https://example.com/receipt.jpg"
    
.EXAMPLE
    .\Start-DocumentAnalysis.ps1 -ModelId "prebuilt-invoice" -DocumentPath "C:\documents\invoice.pdf"

.EXAMPLE
    .\Start-DocumentAnalysis.ps1 -ModelId "prebuilt-receipt" -DocumentUrl "https://raw.githubusercontent.com/pluralsight-cloud/ai-102-azure-ai-engineer-knowledge-mining-document-intelligence-solutions/main/demos/document_intelligence/receipt_image/invoice_sample.jpg" -OutputFormat Json

.NOTES
    Version: 1.0
    Author: Generated from bash equivalent
    Compatible with PowerShell 5.1+
#>

[CmdletBinding(DefaultParameterSetName = 'UrlAnalysis')]
param(
    [Parameter(Mandatory = $true)]
    [string]$ModelId,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'UrlAnalysis')]
    [string]$DocumentUrl,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'FileAnalysis')]
    [string]$DocumentPath,
    
    [Parameter(Mandatory = $false)]
    [string]$ServiceKey,
    
    [Parameter(Mandatory = $false)]
    [string]$ServiceEndpoint,
    
    [Parameter(Mandatory = $false)]
    [string]$ApiVersion = '2024-02-29-preview',
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('Json', 'Object')]
    [string]$OutputFormat = 'Object'
)

# Get service credentials from environment if not provided
if ([string]::IsNullOrWhiteSpace($ServiceKey)) {
    $ServiceKey = $env:AI_SERVICE_KEY
    if ([string]::IsNullOrWhiteSpace($ServiceKey)) {
        throw "ServiceKey not provided and AI_SERVICE_KEY environment variable not set. Run Initialize-Variables.ps1 first."
    }
}

if ([string]::IsNullOrWhiteSpace($ServiceEndpoint)) {
    $ServiceEndpoint = $env:AI_SERVICE_ENDPOINT
    if ([string]::IsNullOrWhiteSpace($ServiceEndpoint)) {
        throw "ServiceEndpoint not provided and AI_SERVICE_ENDPOINT environment variable not set. Run Initialize-Variables.ps1 first."
    }
}

# Ensure endpoint ends with /
if (-not $ServiceEndpoint.EndsWith('/')) {
    $ServiceEndpoint += '/'
}

# Validate inputs
if ([string]::IsNullOrWhiteSpace($ModelId)) {
    throw "ModelId cannot be null or empty"
}

# Validate file exists if using file analysis
if ($PSCmdlet.ParameterSetName -eq 'FileAnalysis') {
    if (-not (Test-Path -Path $DocumentPath)) {
        throw "Document file not found: $DocumentPath"
    }
}

# Validate URL format if using URL analysis
if ($PSCmdlet.ParameterSetName -eq 'UrlAnalysis') {
    try {
        $uri = [System.Uri]::new($DocumentUrl)
        if ($uri.Scheme -notin @('http', 'https')) {
            throw "DocumentUrl must be a valid HTTP or HTTPS URL"
        }
    }
    catch {
        throw "DocumentUrl is not a valid URL: $DocumentUrl"
    }
}

# Construct API endpoint
$apiEndpoint = "${ServiceEndpoint}documentintelligence/documentModels/${ModelId}:analyze?api-version=${ApiVersion}"

Write-Verbose "API Endpoint: $apiEndpoint"
Write-Verbose "Parameter Set: $($PSCmdlet.ParameterSetName)"

# Prepare headers
$headers = @{
    'Ocp-Apim-Subscription-Key' = $ServiceKey
}

try {
    if ($PSCmdlet.ParameterSetName -eq 'UrlAnalysis') {
        # URL-based analysis
        $headers['Content-Type'] = 'application/json'
        $body = @{
            urlSource = $DocumentUrl
        } | ConvertTo-Json -Depth 10
        
        Write-Verbose "Request Body: $body"
        
        $response = Invoke-WebRequest -Uri $apiEndpoint -Method Post -Headers $headers -Body $body -UseBasicParsing
    }
    else {
        # File-based analysis
        $headers['Content-Type'] = 'application/octet-stream'
        $fileBytes = [System.IO.File]::ReadAllBytes($DocumentPath)
        
        Write-Verbose "File Size: $($fileBytes.Length) bytes"
        
        $response = Invoke-WebRequest -Uri $apiEndpoint -Method Post -Headers $headers -Body $fileBytes -UseBasicParsing
    }
    
    Write-Verbose "Response Status: $($response.StatusCode) $($response.StatusDescription)"
    Write-Verbose "Response Headers: $($response.Headers | ConvertTo-Json)"
    
    # Extract operation location from headers
    $operationLocation = $response.Headers['Operation-Location']
    if ([string]::IsNullOrWhiteSpace($operationLocation)) {
        $operationLocation = $response.Headers['operation-location']
    }
    
    # Parse result ID from operation location
    $resultId = $null
    if ($operationLocation) {
        $resultId = [System.IO.Path]::GetFileName($operationLocation.Split('?')[0])
    }
    
    $result = [PSCustomObject]@{
        StatusCode = $response.StatusCode
        StatusDescription = $response.StatusDescription
        OperationLocation = $operationLocation
        ResultId = $resultId
        ModelId = $ModelId
        RequestedAt = Get-Date
        Headers = $response.Headers
    }
    
    if ($OutputFormat -eq 'Json') {
        return $result | ConvertTo-Json -Depth 10
    }
    else {
        Write-Host "Document analysis started successfully!" -ForegroundColor Green
        Write-Host "Result ID: $resultId" -ForegroundColor Yellow
        Write-Host "Use Get-AnalysisResult.ps1 with this Result ID to retrieve the analysis results." -ForegroundColor Cyan
        return $result
    }
}
catch {
    Write-Error "Failed to start document analysis: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $errorStream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorStream)
        $errorBody = $reader.ReadToEnd()
        Write-Error "Response body: $errorBody"
    }
    throw
}
