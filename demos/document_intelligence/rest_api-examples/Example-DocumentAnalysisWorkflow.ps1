<#
.SYNOPSIS
    Complete example demonstrating Azure Document Intelligence PowerShell workflow.

.DESCRIPTION
    This script demonstrates the complete workflow for analyzing documents using Azure Document Intelligence:
    1. Initialize environment variables
    2. Start document analysis
    3. Retrieve analysis results
    
    This is equivalent to running the bash scripts in sequence but with enhanced PowerShell features.

.PARAMETER DocumentUrl
    URL of the document to analyze. Default uses the sample invoice from the repository.

.PARAMETER ModelId
    Document Intelligence model to use. Default is 'prebuilt-receipt'.

.PARAMETER ServiceKey
    Azure Document Intelligence service key. Uses default from Initialize-Variables.ps1 if not provided.

.PARAMETER ServiceEndpoint
    Azure Document Intelligence service endpoint. Uses default from Initialize-Variables.ps1 if not provided.

.PARAMETER SaveResults
    Switch to save results to a JSON file.

.PARAMETER ResultsPath
    Path to save results file. Default is current directory with timestamp.

.EXAMPLE
    .\Example-DocumentAnalysisWorkflow.ps1
    
.EXAMPLE
    .\Example-DocumentAnalysisWorkflow.ps1 -ModelId "prebuilt-invoice" -SaveResults

.EXAMPLE
    .\Example-DocumentAnalysisWorkflow.ps1 -DocumentUrl "https://example.com/document.pdf" -ModelId "prebuilt-document" -SaveResults -ResultsPath "C:\results\my_analysis.json"

.NOTES
    Version: 1.0
    Author: Generated PowerShell workflow example
    Compatible with PowerShell 5.1+
    
    This script combines the functionality of:
    - initialize_variables.sh
    - analyze_document.sh  
    - get_analyze_result.sh
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$DocumentUrl = 'https://raw.githubusercontent.com/pluralsight-cloud/ai-102-azure-ai-engineer-knowledge-mining-document-intelligence-solutions/main/demos/document_intelligence/receipt_image/invoice_sample.jpg',
    
    [Parameter(Mandatory = $false)]
    [string]$ModelId = 'prebuilt-receipt',
    
    [Parameter(Mandatory = $false)]
    [string]$ServiceKey,
    
    [Parameter(Mandatory = $false)]
    [string]$ServiceEndpoint,
    
    [Parameter(Mandatory = $false)]
    [switch]$SaveResults,
    
    [Parameter(Mandatory = $false)]
    [string]$ResultsPath
)

Write-Host "=== Azure Document Intelligence PowerShell Workflow Example ===" -ForegroundColor Magenta
Write-Host ""

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

try {
    # Step 1: Initialize Variables
    Write-Host "Step 1: Initializing environment variables..." -ForegroundColor Yellow
    
    $initParams = @{}
    if ($ServiceKey) { $initParams.ServiceKey = $ServiceKey }
    if ($ServiceEndpoint) { $initParams.ServiceEndpoint = $ServiceEndpoint }
    
    & "$scriptDir\Initialize-Variables.ps1" @initParams | Out-Null
    Write-Host "✓ Environment configured" -ForegroundColor Green
    Write-Host ""
    
    # Step 2: Start Document Analysis
    Write-Host "Step 2: Starting document analysis..." -ForegroundColor Yellow
    Write-Host "Document URL: $DocumentUrl" -ForegroundColor Cyan
    Write-Host "Model ID: $ModelId" -ForegroundColor Cyan
    
    $analysisResult = & "$scriptDir\Start-DocumentAnalysis.ps1" -ModelId $ModelId -DocumentUrl $DocumentUrl -Verbose:$VerbosePreference
    
    if (-not $analysisResult.ResultId) {
        throw "Failed to get Result ID from analysis request"
    }
    
    Write-Host "✓ Analysis started successfully" -ForegroundColor Green
    Write-Host "Result ID: $($analysisResult.ResultId)" -ForegroundColor Cyan
    Write-Host ""
    
    # Step 3: Wait for and Retrieve Results
    Write-Host "Step 3: Retrieving analysis results..." -ForegroundColor Yellow
    Write-Host "Waiting for analysis to complete..." -ForegroundColor Cyan
    
    $getResultParams = @{
        ModelId = $ModelId
        ResultId = $analysisResult.ResultId
        WaitForCompletion = $true
        Verbose = $VerbosePreference
    }
    
    if ($SaveResults) {
        $getResultParams.OutputFormat = 'File'
        if ($ResultsPath) {
            $getResultParams.OutputPath = $ResultsPath
        }
    }
    
    $finalResult = & "$scriptDir\Get-AnalysisResult.ps1" @getResultParams
    
    Write-Host "✓ Analysis completed!" -ForegroundColor Green
    Write-Host ""
    
    # Display summary
    Write-Host "=== Analysis Summary ===" -ForegroundColor Magenta
    Write-Host "Model ID: $ModelId" -ForegroundColor White
    Write-Host "Result ID: $($analysisResult.ResultId)" -ForegroundColor White
    Write-Host "Status: $($finalResult.Status)" -ForegroundColor White
    Write-Host "Completed At: $($finalResult.RetrievedAt)" -ForegroundColor White
    
    if ($SaveResults -and $finalResult.OutputPath) {
        Write-Host "Results File: $($finalResult.OutputPath)" -ForegroundColor White
    }
    
    # Display key extracted data if analysis succeeded
    if ($finalResult.Status -eq 'succeeded' -and $finalResult.AnalysisResult) {
        Write-Host ""
        Write-Host "=== Key Extracted Information ===" -ForegroundColor Magenta
        
        $analysis = $finalResult.AnalysisResult
        
        # Display document type and confidence
        if ($analysis.modelId) {
            Write-Host "Model Used: $($analysis.modelId)" -ForegroundColor Cyan
        }
        
        # Display key-value pairs if available
        if ($analysis.analyzeResult.documents -and $analysis.analyzeResult.documents.Count -gt 0) {
            $document = $analysis.analyzeResult.documents[0]
            
            if ($document.fields) {
                Write-Host ""
                Write-Host "Detected Fields:" -ForegroundColor Yellow
                
                $document.fields.PSObject.Properties | ForEach-Object {
                    $fieldName = $_.Name
                    $fieldValue = $_.Value
                    
                    if ($fieldValue.content) {
                        $confidence = if ($fieldValue.confidence) { " (confidence: $([math]::Round($fieldValue.confidence * 100, 1))%)" } else { "" }
                        Write-Host "  $fieldName`: $($fieldValue.content)$confidence" -ForegroundColor White
                    }
                }
            }
        }
        
        # Display page count
        if ($analysis.analyzeResult.pages) {
            Write-Host ""
            Write-Host "Pages Analyzed: $($analysis.analyzeResult.pages.Count)" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "=== Workflow Completed Successfully ===" -ForegroundColor Green
    
    return $finalResult
}
catch {
    Write-Host ""
    Write-Host "=== Workflow Failed ===" -ForegroundColor Red
    Write-Error "Workflow error: $($_.Exception.Message)"
    throw
}
