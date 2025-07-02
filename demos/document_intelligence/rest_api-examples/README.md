# Azure Document Intelligence PowerShell Scripts

This folder contains PowerShell equivalents of the bash shell scripts for Azure Document Intelligence REST API operations.

## Scripts Overview

### Core Scripts

1. **Initialize-Variables.ps1** - Sets up environment variables for API access
2. **Start-DocumentAnalysis.ps1** - Submits documents for analysis
3. **Get-AnalysisResult.ps1** - Retrieves analysis results
4. **Example-DocumentAnalysisWorkflow.ps1** - Complete workflow demonstration

### Original Bash Scripts (for reference)

- `initialize_variables.sh` - Original environment setup
- `analyze_document.sh` - Original document analysis
- `get_analyze_result.sh` - Original result retrieval

## Prerequisites

- PowerShell 5.1 or newer
- Azure Document Intelligence resource with valid endpoint and key
- Internet connectivity for API calls

## Quick Start

### 1. Initialize Environment Variables

```powershell
.\Initialize-Variables.ps1
```

This uses the default credentials from the original bash script. You can also provide custom values:

```powershell
.\Initialize-Variables.ps1 -ServiceKey "your-key" -ServiceEndpoint "https://your-endpoint.cognitiveservices.azure.com/"
```

### 2. Analyze a Document

```powershell
# Analyze a document from URL
.\Start-DocumentAnalysis.ps1 -ModelId "prebuilt-receipt" -DocumentUrl "https://example.com/receipt.jpg"

# Analyze a local file
.\Start-DocumentAnalysis.ps1 -ModelId "prebuilt-invoice" -DocumentPath "C:\documents\invoice.pdf"
```

### 3. Get Analysis Results

```powershell
# Get results (replace with actual Result ID from step 2)
.\Get-AnalysisResult.ps1 -ModelId "prebuilt-receipt" -ResultId "12345678-1234-1234-1234-123456789012"

# Wait for completion automatically
.\Get-AnalysisResult.ps1 -ModelId "prebuilt-receipt" -ResultId "12345678-1234-1234-1234-123456789012" -WaitForCompletion
```

### 4. Complete Workflow Example

```powershell
# Run the complete workflow with default sample document
.\Example-DocumentAnalysisWorkflow.ps1

# Save results to file
.\Example-DocumentAnalysisWorkflow.ps1 -SaveResults

# Use custom document and model
.\Example-DocumentAnalysisWorkflow.ps1 -DocumentUrl "https://example.com/invoice.pdf" -ModelId "prebuilt-invoice" -SaveResults
```

## Available Document Models

Common model IDs you can use:

- `prebuilt-receipt` - For receipts and similar documents
- `prebuilt-invoice` - For invoices
- `prebuilt-document` - General document analysis
- `prebuilt-businessCard` - Business cards
- `prebuilt-idDocument` - ID documents and passports
- `prebuilt-layout` - Layout analysis only

## Parameters and Options

### Initialize-Variables.ps1

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| ServiceKey | Azure Document Intelligence service key | No | From original script |
| ServiceEndpoint | Service endpoint URL | No | From original script |
| ShowValues | Display configured values (use carefully) | No | False |

### Start-DocumentAnalysis.ps1

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| ModelId | Document Intelligence model ID | Yes | - |
| DocumentUrl | URL of document to analyze | Yes* | - |
| DocumentPath | Local path to document file | Yes* | - |
| ServiceKey | Service key (uses env var if not provided) | No | From environment |
| ServiceEndpoint | Service endpoint (uses env var if not provided) | No | From environment |
| ApiVersion | API version | No | 2024-02-29-preview |
| OutputFormat | Response format (Json/Object) | No | Object |

*Either DocumentUrl or DocumentPath is required

### Get-AnalysisResult.ps1

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| ModelId | Document Intelligence model ID | Yes | - |
| ResultId | Result ID from analysis operation | Yes | - |
| ServiceKey | Service key (uses env var if not provided) | No | From environment |
| ServiceEndpoint | Service endpoint (uses env var if not provided) | No | From environment |
| ApiVersion | API version | No | 2024-02-29-preview |
| OutputFormat | Response format (Json/Object/File) | No | Object |
| OutputPath | File path for saving results | No | Auto-generated |
| WaitForCompletion | Poll until analysis completes | No | False |
| MaxWaitTime | Maximum wait time in seconds | No | 300 |

## Output Formats

### Object Format (Default)
Returns PowerShell objects with structured data and status information.

### JSON Format
Returns raw JSON strings, suitable for further processing or debugging.

### File Format
Saves results to JSON files with timestamps.

## Error Handling

All scripts include comprehensive error handling:

- Input validation
- HTTP error responses
- Network connectivity issues
- Missing environment variables
- Invalid file paths or URLs

## Examples

### Basic Receipt Analysis

```powershell
# 1. Set up environment
.\Initialize-Variables.ps1

# 2. Analyze receipt
$analysis = .\Start-DocumentAnalysis.ps1 -ModelId "prebuilt-receipt" -DocumentUrl "https://example.com/receipt.jpg"

# 3. Get results
$results = .\Get-AnalysisResult.ps1 -ModelId "prebuilt-receipt" -ResultId $analysis.ResultId -WaitForCompletion
```

### Batch Processing Multiple Documents

```powershell
# Initialize once
.\Initialize-Variables.ps1

# Process multiple documents
$documents = @(
    "https://example.com/receipt1.jpg",
    "https://example.com/receipt2.jpg",
    "https://example.com/receipt3.jpg"
)

$results = @()
foreach ($doc in $documents) {
    $analysis = .\Start-DocumentAnalysis.ps1 -ModelId "prebuilt-receipt" -DocumentUrl $doc
    $result = .\Get-AnalysisResult.ps1 -ModelId "prebuilt-receipt" -ResultId $analysis.ResultId -WaitForCompletion -OutputFormat File
    $results += $result
}

Write-Host "Processed $($results.Count) documents"
```

### Custom Model Analysis

```powershell
# For custom trained models
.\Start-DocumentAnalysis.ps1 -ModelId "your-custom-model-id" -DocumentPath "C:\documents\form.pdf"
```

## Troubleshooting

### Common Issues

1. **"Environment variable not set"**
   - Run `Initialize-Variables.ps1` first
   - Check that your service key and endpoint are correct

2. **"Result ID not found"**
   - The analysis may have expired (results are kept for 24 hours)
   - Verify the Result ID is correct

3. **"Analysis failed"**
   - Check that the document format is supported
   - Verify the document URL is accessible
   - Ensure the model ID is correct for your document type

4. **PowerShell execution policy**
   - Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Verbose Output

Use the `-Verbose` parameter for detailed execution information:

```powershell
.\Start-DocumentAnalysis.ps1 -ModelId "prebuilt-receipt" -DocumentUrl "https://example.com/receipt.jpg" -Verbose
```

## Differences from Bash Scripts

### Enhancements in PowerShell Version

1. **Parameter Validation** - Input validation and type checking
2. **Error Handling** - Comprehensive error handling with meaningful messages
3. **Structured Output** - PowerShell objects instead of raw text
4. **Progress Indication** - Visual feedback during operations
5. **Polling Support** - Automatic waiting for analysis completion
6. **File Output** - Save results to files with automatic naming
7. **Help Documentation** - Built-in help with examples
8. **Pipeline Support** - Can be used in PowerShell pipelines

### Equivalent Commands

| Bash | PowerShell |
|------|------------|
| `source initialize_variables.sh` | `.\Initialize-Variables.ps1` |
| `./analyze_document.sh` | `.\Start-DocumentAnalysis.ps1 -ModelId "{model-id}" -DocumentUrl "url"` |
| `./get_analyze_result.sh` | `.\Get-AnalysisResult.ps1 -ModelId "{model-id}" -ResultId "{resultId}"` |

## Security Notes

- Service keys are sensitive - avoid displaying them in logs
- Use `-ShowValues` parameter carefully in `Initialize-Variables.ps1`
- Consider using Azure Key Vault for production scenarios
- Environment variables are session-scoped and not persisted

## Support

For issues with these scripts:
1. Check the troubleshooting section above
2. Use `-Verbose` for detailed output
3. Verify your Azure Document Intelligence resource configuration
4. Check Azure service status and quotas
