<#
.SYNOPSIS
    Optimization Suite for Sea of Thieves.
.DESCRIPTION
    A comprehensive tool to clear shader caches (System, GPU, Steam, Game),
    detect installation paths via Registry/VDF parsing, enforce configuration
    immutability, and clean local precache files (.upsoprecache / .ushaderprecache).
.NOTES
    Requires Administrator Privileges.
    Version: 1.0 
	Auth: Fizzbane
#>

# =============================================================================
# INITIALIZATION & ELEVATION (Universal)
# =============================================================================
$Principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Administrator privileges required. Restarting with elevation..."
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# =============================================================================
# CONFIGURATION CONTENT (HEREDOCS)
# =============================================================================

$Global:NewEngineIni = @'
[Core.System]
Paths=../../../Engine/Content
Paths=../../../Athena/Content
Paths=../../../Engine/Plugins/2D/Paper2D/Content
Paths=../../../Engine/Plugins/Rare/RareShaderTest/Content
Paths=../../../Engine/Plugins/Runtime/Coherent/CoherentUIGTPlugin/Content

; --- ANTI-ALIASING ---
r.DefaultFeature.AntiAliasing=0
r.PostProcessAAQuality=0

; --- PERFORMANCE & MEMORY MANAGEMENT ---
r.Streaming.PoolSize=4096
r.Streaming.LimitPoolSizeToVRAM=1
r.TextureStreaming=1
r.CreateShadersOnLoad=1
r.XGEShaderCompile=1
s.ForceGCAfterLevelStreamedOut=0
s.ContinuouslyIncrementalGCWhileLevelsPendingPurge=0

; --- INPUT LATENCY OPTIMIZATION ---
r.OneFrameThreadLag=0
r.FinishCurrentFrame=0
m.MouseSmoothing=0

; --- NETWORK OPTIMIZATION ---
ConfiguredInternetSpeed=100000
ConfiguredLanSpeed=100000
NetServerMaxTickRate=120
LanMaxClientRate=100000
InternetMaxClientRate=100000
TotalNetBandwidth=100000
MaxDynamicBandwidth=100000
MinDynamicBandwidth=20000

; --- VISUAL CLARITY ---
r.LightShaftQuality=0
r.LightShafts=0
r.LensFlareQuality=0
r.DefaultFeature.LensFlare=0
r.DefaultFeature.Bloom=0
r.BloomQuality=0
r.MotionBlurQuality=0
r.MotionBlur.Amount=0
r.DefaultFeature.MotionBlur=0
r.DepthOfFieldQuality=0
r.DepthOfField.MaxSize=0
r.Tonemapper.GrainQuantization=0
r.Tonemapper.Quality=0
r.SceneColorFringeQuality=0
r.SceneColorFringe.Max=0

; --- RENDERING ---
r.StaticMeshLODDistanceScale=0.7
foliage.LODDistanceScale=0.8
r.Tonemapper.Sharpen=1.3
r.EyeAdaptationQuality=0
r.DefaultFeature.AutoExposure=0
r.ShadowQuality=0
r.Shadow.DistanceScale=0
r.ContactShadows=0
r.Shadow.CSM.MaxCascades=0
r.Shadow.MaxResolution=512
'@

$Global:NewGameUserSettingsIni = @'
[ScalabilityGroups]
sg.ResolutionQuality=100
sg.ViewDistanceQuality=3
sg.AntiAliasingQuality=0
sg.ShadowQuality=0
sg.PostProcessQuality=3
sg.TextureQuality=2
sg.EffectsQuality=3

[/Script/Athena.AthenaGameUserSettings]
MaxVerticalResolution=0
MaxFPS=0
VSync=0
LightingDetail=0
ModelDetail=2
ShadowDetail=0
TextureDetail=2
WaterDetail=0
AnimationQuality=0
MMCThresholdScale=4
ResolutionScaling=100.000000
ParticleEmitterQuality=0
ParticleResolutionQuality=0
BackBufferCount=2
ShowPerformanceCounters=3
SmoothFPS=False
HDR=False
AudioOutputSpatialAudio=False
Fullscreen=True
bUseVSync=False
ResolutionSizeX=0
ResolutionSizeY=0
LastUserConfirmedResolutionSizeX=0
LastUserConfirmedResolutionSizeY=0
WindowPosX=-1
WindowPosY=-1
bUseDesktopResolutionForFullscreen=False
FullscreenMode=2
LastConfirmedFullscreenMode=2
Version=5
AudioQualityLevel=0
D3DVersionForced=0
D3DVersion=12
ParallelRendering=True
GpuCrashDetection=False
ShowPerformanceCounters_Console=0
GameLanguage=1
AudioOutputFormat=2
ImmerseHeadsetId=0
'@

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

function Write-Header {
    param($Text)
    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host " $Text" -ForegroundColor White
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Remove-FolderContents {
    param($Path, $Desc)

    # SAFETY GUARD: Prevent running on empty paths or root drives (e.g. C:\)
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path.Length -lt 5) {
        Write-Warning "Safety Guard Triggered: Skipping unsafe path '$Path'"
        return
    }

    if (Test-Path $Path) {
        Write-Host "Cleaning $Desc..." -ForegroundColor Yellow -NoNewline
        try {
            Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host " [OK]" -ForegroundColor Green
        } catch {
            Write-Host " - Some files locked." -ForegroundColor Red
        }
    } else {
        Write-Host "Skipping $Desc (Not Found)" -ForegroundColor DarkGray
    }
}

# =============================================================================
# DETECTION MODULES
# =============================================================================

function Get-SteamLibraries {
    $Libraries = @()
    # 1. Registry Lookup for Base Steam Path
    try {
        $SteamPath = Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Valve\Steam" -Name "InstallPath" -ErrorAction Stop | Select-Object -ExpandProperty InstallPath
        $Libraries += $SteamPath
    } catch {
        Write-Warning "Steam Registry Key not found."
    }

    # 2. VDF Parsing for Custom Libraries
    if ($SteamPath) {
        $VdfPath = Join-Path $SteamPath "steamapps\libraryfolders.vdf"
        if (Test-Path $VdfPath) {
            $Content = Get-Content $VdfPath -Raw
            # FIXED REGEX: Captures the path inside the quotes properly
            $Regex = [regex]'"path"\s+"(.+?)"'
            $Matches = $Regex.Matches($Content)
            foreach ($Match in $Matches) {
                # FIXED LOGIC: Use Group[1] to get the captured path
                $Path = $Match.Groups[1].Value.Replace("\\", "\")
                if ($Libraries -notcontains $Path) { $Libraries += $Path }
            }
        }
    }
    return $Libraries
}

function Find-SoT-Steam {
    $Libs = Get-SteamLibraries
    foreach ($Lib in $Libs) {
        $Manifest = Join-Path $Lib "steamapps\appmanifest_1172620.acf"
        if (Test-Path $Manifest) {
            return $Lib 
        }
    }
    return $null
}

# =============================================================================
# CORE REMEDIATION LOGIC
# =============================================================================

function Clear-SystemShaders {
    Write-Header "CLEARING SYSTEM & GPU SHADERS"
    
    # NVIDIA
    Remove-FolderContents "$env:ProgramData\NVIDIA Corporation\NV_Cache" "NVIDIA System Cache"
    Remove-FolderContents "$env:LOCALAPPDATA\NVIDIA\DXCache" "NVIDIA DXCache"
    Remove-FolderContents "$env:LOCALAPPDATA\NVIDIA\GLCache" "NVIDIA GLCache"
    
    # AMD
    Remove-FolderContents "$env:LOCALAPPDATA\AMD\DxCache" "AMD DxCache"
    Remove-FolderContents "$env:LOCALAPPDATA\AMD\DxcCache" "AMD DxcCache"
    
    # DIRECTX
    Remove-FolderContents "$env:LOCALAPPDATA\D3DSCache" "Windows D3D Cache"
}

function Clear-Athena-Local-Cache {
    Write-Header "CLEARING LOCAL ATHENA CACHE (Precache)"
    $AthenaPath = "$env:LOCALAPPDATA\Athena"
    
    if (Test-Path $AthenaPath) {
        Write-Host "Scanning $AthenaPath for .upsoprecache and .ushaderprecache..." -ForegroundColor Yellow
        try {
            # Target both .upsoprecache AND .ushaderprecache files recursively
            $Files = Get-ChildItem -Path $AthenaPath -Include "*.upsoprecache", "*.ushaderprecache" -Recurse -Force -ErrorAction SilentlyContinue
            
            if ($Files) {
                $Files | Remove-Item -Force -ErrorAction SilentlyContinue
                Write-Host "Removed $($Files.Count) cache file(s)." -ForegroundColor Green
            } else {
                Write-Host "No local precache files found." -ForegroundColor DarkGray
            }
        } catch {
            Write-Host " - Error accessing some files." -ForegroundColor Red
        }
    } else {
        Write-Host "Athena Local Folder not found (Skipping)." -ForegroundColor DarkGray
    }
}

function Clear-Steam-Data {
    param($LibraryPath)
    Write-Header "CLEARING STEAM DATA"
    if (-not $LibraryPath) { 
        Write-Warning "Steam Library not provided."
        return 
    }

    # 1. Shader Depot (AppID 1172620)
    $ShaderPath = Join-Path $LibraryPath "steamapps\shadercache\1172620"
    Remove-FolderContents $ShaderPath "Steam Pre-Compiled Shaders (AppID 1172620)"

    # 2. Game Internal PSO
    $GamePath = Join-Path $LibraryPath "steamapps\common\Sea of Thieves\Athena\Config\PSOCache"
    Remove-FolderContents $GamePath "Internal PSO Cache (upsoprecache)"
}

function Clear-Store-Data {
    Write-Header "CLEARING WINDOWS STORE DATA"
    # LocalCache
    $PkgPath = Get-ChildItem "$env:LOCALAPPDATA\Packages" -Filter "Microsoft.SeaofThieves*" | Select-Object -ExpandProperty FullName -First 1
    
    if ($PkgPath) {
        $LocalCache = Join-Path $PkgPath "LocalCache"
        Remove-FolderContents $LocalCache "Windows Store LocalCache"
    } else {
        Write-Warning "Sea of Thieves (Store Version) package directory not found in AppData."
    }
}

function Write-Configs {
    param($TargetFolder)
    Write-Header "WRITING CONFIGURATION FILES"
    
    # Ensure directory exists
    if (-not (Test-Path $TargetFolder)) {
        New-Item -ItemType Directory -Force -Path $TargetFolder | Out-Null
    }

    $EnginePath = Join-Path $TargetFolder "Engine.ini"
    $UserPath = Join-Path $TargetFolder "GameUserSettings.ini"

    # Unlock files if they exist (Reset ReadOnly attribute) & Create Backup
    foreach ($FilePath in @($EnginePath, $UserPath)) {
        if (Test-Path $FilePath) { 
            $Item = Get-Item $FilePath
            if ($Item.IsReadOnly) { $Item.IsReadOnly = $false }
            
            # Backup Logic
            Copy-Item $FilePath "$FilePath.bak" -Force
            Write-Host "Created Backup: $(Split-Path $FilePath -Leaf).bak" -ForegroundColor DarkGray
        }
    }

    # Write Content
    try {
        Set-Content -Path $EnginePath -Value $Global:NewEngineIni -Force -Encoding UTF8
        Set-Content -Path $UserPath -Value $Global:NewGameUserSettingsIni -Force -Encoding UTF8
        Write-Host "Written: Engine.ini" -ForegroundColor Green
        Write-Host "Written: GameUserSettings.ini" -ForegroundColor Green

        # Lock Files (Set ReadOnly attribute)
        $E = Get-Item $EnginePath
        $E.IsReadOnly = $true
        $U = Get-Item $UserPath
        $U.IsReadOnly = $true
        Write-Host "Attributes set to READ-ONLY for data persistence." -ForegroundColor Magenta
    } catch {
        Write-Error "Failed to write config files: $_"
    }
}

# =============================================================================
# INTERACTIVE MENU SYSTEM
# =============================================================================

function Show-Menu {
    Clear-Host
    Write-Host "SEA OF THIEVES OPTIMIZER - PRODUCTION SUITE v4.4" -ForegroundColor Cyan
    Write-Host "-----------------------------------------------"
    Write-Host "1. Auto-Detect and Clean (Steam & Store & Local)"
    Write-Host "2. Specify Custom Steam Library Location"
    Write-Host "3. Clear Only System/GPU Shaders"
    Write-Host "4. Apply Optimized Config Files Only"
    Write-Host "Q. Quit"
    Write-Host "-----------------------------------------------"
}

# Main Loop
do {
    Show-Menu
    $Choice = Read-Host "Select an option"
    
    switch ($Choice) {
        "1" {
            # FULL AUTO
            Clear-SystemShaders
            Clear-Athena-Local-Cache
            
            # Steam Auto
            $SteamLib = Find-SoT-Steam
            if ($SteamLib) { 
                Write-Host "Detected Steam Install at: $SteamLib" -ForegroundColor Green
                Clear-Steam-Data -LibraryPath $SteamLib
            } else {
                Write-Warning "Steam installation not auto-detected."
            }

            # Store Auto
            Clear-Store-Data
            
            # Write Configs to User Requested Path
            $BasePath = "$env:LOCALAPPDATA\Athena\Saved\Config"
            Write-Configs -TargetFolder (Join-Path $BasePath "WindowsClient")
            Write-Configs -TargetFolder (Join-Path $BasePath "WinGDK")
            
            Write-Host "`nOptimization Complete. Please restart your system." -ForegroundColor Cyan
            Pause
        }

        "2" {
            # CUSTOM PATH
            Write-Host "`nPlease enter the full path to your Steam Library folder."
            Write-Host "Example: D:\Games\Steam"
            $CustomPath = Read-Host "Path"
            
            if (Test-Path $CustomPath) {
                if (Test-Path (Join-Path $CustomPath "steamapps")) {
                    Clear-Steam-Data -LibraryPath $CustomPath
                    
                    # Also do configs
                    $BasePath = "$env:LOCALAPPDATA\Athena\Saved\Config"
                    Write-Configs -TargetFolder (Join-Path $BasePath "WindowsClient")
                } else {
                    Write-Error "Invalid Steam Library (No 'steamapps' folder found)."
                }
            } else {
                Write-Error "Path does not exist."
            }
            Pause
        }

        "3" {
            Clear-SystemShaders
            Clear-Athena-Local-Cache
            Pause
        }

        "4" {
            $BasePath = "$env:LOCALAPPDATA\Athena\Saved\Config"
            Write-Configs -TargetFolder (Join-Path $BasePath "WindowsClient")
            Write-Configs -TargetFolder (Join-Path $BasePath "WinGDK")
            Pause
        }
    }
} until ($Choice -eq "Q")