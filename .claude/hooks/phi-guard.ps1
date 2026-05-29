# Claude Code PostToolUse hook — PHI plaintext detection
# Blocks writes/edits that contain unencrypted PHI patterns.
# Customize PHI_PATTERNS and ENCRYPTION_MARKERS for your project.
# Exit code 2 = block, 0 = allow
param()

$raw  = [Console]::In.ReadToEnd()
$json = try { $raw | ConvertFrom-Json -ErrorAction Stop } catch { $null }
if (-not $json) { exit 0 }

$tool = $json.tool_name
if ($tool -notin @("Write", "Edit")) { exit 0 }

$filePath = $json.tool_input.file_path
if (-not $filePath) { exit 0 }

# Customize: set the file extensions and directories to scan
$targetExtensions = @('.dart', '.ts', '.js', '.py')
$ext = [System.IO.Path]::GetExtension($filePath)
if ($ext -notin $targetExtensions) { exit 0 }

if (-not (Test-Path $filePath)) { exit 0 }

$content = Get-Content $filePath -Raw -ErrorAction SilentlyContinue
if (-not $content) { exit 0 }

# Customize: add your project's PHI field names
$phiPatterns = @(
    '(?i)(patientName|residentName|fullName)\s*[:=]\s*["\x27][^\x27"]{2,}',
    '(?i)(phoneNumber|phone)\s*[:=]\s*["\x27][\d\-\+\(\) ]{7,}',
    '(?i)(birthDate|dateOfBirth|dob)\s*[:=]\s*["\x27]\d{4}',
    '(?i)(diagnosis|condition)\s*[:=]\s*["\x27][^\x27"]{2,}'
)

# Customize: add your project's encryption markers
$encryptionMarkers = @('AES-GCM', 'HKDF', 'X25519', 'encrypt', 'EncryptedField', 'cipher')

$hasEncryption = $false
foreach ($marker in $encryptionMarkers) {
    if ($content -match [regex]::Escape($marker)) { $hasEncryption = $true; break }
}

foreach ($pattern in $phiPatterns) {
    if ($content -match $pattern) {
        if (-not $hasEncryption) {
            $fileName = Split-Path $filePath -Leaf
            $msg = @{
                decision = "block"
                reason   = "PHI-GUARD: '$fileName' contains PHI pattern without encryption. Encrypt before storing or add encryption marker."
            }
            Write-Output ($msg | ConvertTo-Json -Compress)
            exit 2
        }
    }
}

exit 0
