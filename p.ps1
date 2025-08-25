# Configuration variables - Update these for your environment
$sourceRepo = "https://dev.azure.com/your-organization/your-project/_git/CertScanConfig"
$sourceFile = "QA/application_stgedicoreneb01.properties"
$destinationHost = "stgedicoreneb01"
$destinationPath = "F:\certscan\"
$destinationFile = "application.properties"
$backupPath = "F:\certscan\backup\"

# Create temporary directory for cloning
$tempDir = Join-Path $env:TEMP "CertScanConfig-$(Get-Date -Format 'yyyyMMddHHmmss')"
Write-Host "Creating temp directory: $tempDir"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    # Clone the repository (authentication handled by Azure DevOps)
    Write-Host "Cloning repository from: $sourceRepo"
    git clone --depth 1 --quiet $sourceRepo $tempDir
    
    if ($LASTEXITCODE -ne 0) {
        throw "Git clone failed with error code: $LASTEXITCODE. Check repository URL and permissions."
    }
    
    Write-Host "Repository cloned successfully"
    
    # Check if source file exists
    $sourceFilePath = Join-Path $tempDir $sourceFile
    if (-not (Test-Path $sourceFilePath)) {
        throw "Source file not found: $sourceFilePath. Available files in QA folder: $(Get-ChildItem (Join-Path $tempDir 'QA') | Select-Object -ExpandProperty Name)"
    }
    
    Write-Host "Source file found: $sourceFilePath"
    
    # Create backup directory if it doesn't exist
    if (-not (Test-Path $backupPath)) {
        Write-Host "Creating backup directory: $backupPath"
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    }
    
    # Create backup of current application.properties if it exists
    $currentAppProperties = Join-Path $destinationPath $destinationFile
    if (Test-Path $currentAppProperties) {
        $backupFile = "application.properties.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
        $backupFilePath = Join-Path $backupPath $backupFile
        Write-Host "Creating backup: $backupFilePath"
        Copy-Item $currentAppProperties $backupFilePath -Force
        Write-Host "Backup created successfully"
    } else {
        Write-Host "No existing application.properties found for backup"
    }
    
    # Ensure destination directory exists
    if (-not (Test-Path $destinationPath)) {
        Write-Host "Creating destination directory: $destinationPath"
        New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
    }
    
    # Copy and rename the file
    Write-Host "Copying file to: $destinationPath$destinationFile"
    Copy-Item $sourceFilePath (Join-Path $destinationPath $destinationFile) -Force
    
    # Verify the file was copied
    $finalDestination = Join-Path $destinationPath $destinationFile
    if (Test-Path $finalDestination) {
        $fileSize = (Get-Item $finalDestination).Length
        Write-Host "SUCCESS: File deployed successfully to $finalDestination (Size: $fileSize bytes)"
        
        # Optional: Display first few lines for verification
        Write-Host "File preview (first 5 lines):"
        Get-Content $finalDestination -Head 5 | ForEach-Object { Write-Host "  $_" }
    } else {
        throw "Deployment failed - file not found at destination: $finalDestination"
    }
    
} catch {
    Write-Error "ERROR: $($_.Exception.Message)"
    Write-Error "Deployment failed. Check repository access, file paths, and permissions."
    exit 1
} finally {
    # Clean up temporary directory
    if (Test-Path $tempDir) {
        Write-Host "Cleaning up temporary directory: $tempDir"
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Script execution completed"
