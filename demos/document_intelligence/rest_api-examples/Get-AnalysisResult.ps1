<#
.SYNOPSIS
    Retrieves document analysis results from Azure Document Intelligence API.

.DESCRIPTION
    This script retrieves the results of a document analysis operation using the Result ID
    obtained from Start-DocumentAnalysis.ps1. It polls the API and returns the analysis results.

.PARAMETER ModelId
    The Document Intelligence model ID that was used for analysis.

.PARAMETER ResultId
    The Result ID returned from the document analysis operation.

.PARAMETER ServiceKey
    Azure Document Intelligence service key. If not provided, uses AI_SERVICE_KEY environment variable.

.PARAMETER ServiceEndpoint
    Azure Document Intelligence service endpoint. If not provided, uses AI_SERVICE_ENDPOINT environment variable.

.PARAMETER ApiVersion
    API version to use. Default is '2024-02-29-preview'.

.PARAMETER OutputFormat
    Output format for the response. Options: 'Json', 'Object', 'File'. Default is 'Object'.

.PARAMETER OutputPath
    Path to save the results when OutputFormat is 'File'. Default is current directory with timestamp.

.PARAMETER WaitForCompletion
    Switch to poll the API until analysis is complete. Default polling interval is 5 seconds.

.PARAMETER MaxWaitTime
    Maximum time to wait for completion in seconds. Default is 300 seconds (5 minutes).

.EXAMPLE
    .\Get-AnalysisResult.ps1 -ModelId "prebuilt-receipt" -ResultId "12345678-1234-1234-1234-123456789012"
    
.EXAMPLE
    .\Get-AnalysisResult.ps1 -ModelId "prebuilt-invoice" -ResultId "12345678-1234-1234-1234-123456789012" -WaitForCompletion

.EXAMPLE
    .\Get-AnalysisResult.ps1 -ModelId "prebuilt-receipt" -ResultId "12345678-1234-1234-1234-123456789012" -OutputFormat File -OutputPath "C:\results\analysis.json"

.NOTES
    Version: 1.0
    Author: Generated from bash equivalent
    Compatible with PowerShell 5.1+
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ModelId,
    
    [Parameter(Mandatory = $true)]
    [string]$ResultId,
    
    [Parameter(Mandatory = $false)]
    [string]$ServiceKey,
    
    [Parameter(Mandatory = $false)]
    [string]$ServiceEndpoint,
    
    [Parameter(Mandatory = $false)]
    [string]$ApiVersion = '2024-02-29-preview',
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('Json', 'Object', 'File')]
    [string]$OutputFormat = 'Object',
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$WaitForCompletion,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxWaitTime = 300
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

if ([string]::IsNullOrWhiteSpace($ResultId)) {
    throw "ResultId cannot be null or empty"
}

# Construct API endpoint
$apiEndpoint = "${ServiceEndpoint}documentintelligence/documentModels/${ModelId}/analyzeResults/${ResultId}?api-version=${ApiVersion}"

Write-Verbose "API Endpoint: $apiEndpoint"

# Prepare headers
$headers = @{
    'Ocp-Apim-Subscription-Key' = $ServiceKey
}

# Function to make the API call
function Get-AnalysisResultInternal {
    try {
        Write-Verbose "Making API request to get analysis results..."
        $response = Invoke-WebRequest -Uri $apiEndpoint -Method Get -Headers $headers -UseBasicParsing
        
        Write-Verbose "Response Status: $($response.StatusCode) $($response.StatusDescription)"
        
        # Parse JSON response
        $jsonResult = $response.Content | ConvertFrom-Json
        
        return [PSCustomObject]@{
            Success = $true
            StatusCode = $response.StatusCode
            Result = $jsonResult
            IsComplete = ($jsonResult.status -eq 'succeeded' -or $jsonResult.status -eq 'failed')
            Status = $jsonResult.status
            RetrievedAt = Get-Date
        }
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            return [PSCustomObject]@{
                Success = $false
                StatusCode = 404
                Result = $null
                IsComplete = $false
                Status = 'notFound'
                Error = "Analysis result not found. The ResultId may be invalid or expired."
                RetrievedAt = Get-Date
            }
        }
        else {
            Write-Error "Failed to get analysis results: $($_.Exception.Message)"
            if ($_.Exception.Response) {
                $errorStream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($errorStream)
                $errorBody = $reader.ReadToEnd()
                Write-Error "Response body: $errorBody"
            }
            throw
        }
    }
}

# Main execution logic
if ($WaitForCompletion) {
    Write-Host "Waiting for analysis to complete..." -ForegroundColor Yellow
    $startTime = Get-Date
    $pollInterval = 5  # seconds
    
    do {
        $apiResult = Get-AnalysisResultInternal
        
        if (-not $apiResult.Success) {
            throw $apiResult.Error
        }
        
        Write-Host "Status: $($apiResult.Status)" -ForegroundColor Cyan
        
        if ($apiResult.IsComplete) {
            break
        }
        
        $elapsed = (Get-Date) - $startTime
        if ($elapsed.TotalSeconds -gt $MaxWaitTime) {
            Write-Warning "Maximum wait time of $MaxWaitTime seconds exceeded. Analysis may still be in progress."
            break
        }
        
        Start-Sleep -Seconds $pollInterval
    } while (-not $apiResult.IsComplete)
}
else {
    $apiResult = Get-AnalysisResultInternal
    
    if (-not $apiResult.Success) {
        throw $apiResult.Error
    }
}

# Process output based on format
switch ($OutputFormat) {
    'Json' {
        return $apiResult.Result | ConvertTo-Json -Depth 20
    }
    'File' {
        if ([string]::IsNullOrWhiteSpace($OutputPath)) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $OutputPath = "analysis_result_${timestamp}.json"
        }
        
        $apiResult.Result | ConvertTo-Json -Depth 20 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "Results saved to: $OutputPath" -ForegroundColor Green
        
        return [PSCustomObject]@{
            ResultId = $ResultId
            Status = $apiResult.Status
            OutputPath = $OutputPath
            IsComplete = $apiResult.IsComplete
            RetrievedAt = $apiResult.RetrievedAt
        }
    }
    'Object' {
        if ($apiResult.Status -eq 'succeeded') {
            Write-Host "Analysis completed successfully!" -ForegroundColor Green
        }
        elseif ($apiResult.Status -eq 'failed') {
            Write-Host "Analysis failed!" -ForegroundColor Red
        }
        elseif ($apiResult.Status -eq 'running') {
            Write-Host "Analysis is still in progress. Use -WaitForCompletion to wait for results." -ForegroundColor Yellow
        }
        
        return [PSCustomObject]@{
            ResultId = $ResultId
            Status = $apiResult.Status
            IsComplete = $apiResult.IsComplete
            RetrievedAt = $apiResult.RetrievedAt
            AnalysisResult = $apiResult.Result
        }
    }
}
