# Sea of Thieves Advanced Optimization Suite

**Version:** 1.0
**Author:** Fizzbane

## ⚠️ DISCLAIMERS & WARNINGS

### 1. Liability
**I am not responsible for anything. Period.**
By using this script or following these instructions, you acknowledge that you are doing so entirely at your own risk. I accept no liability for any software instability, hardware issues, or account actions that may occur.

### 2. Sea of Thieves Enforcement Policy
Modifying game files (such as `Engine.ini`) can theoretically be flagged under the Sea of Thieves Support Enforcement Policy. While configuration tweaks are generally widely used, you must be aware of the rules.
**Read the policy here:** [Sea of Thieves Support Enforcement Policy Updates](https://support.seaofthieves.com/articles/24643308439314-Support-Enforcement-Policy-Updates)
**Use at your own risk.**

### 3. System-Wide Cache Cleaning
This suite clears **System-wide** shader caches (DirectX, NVIDIA, AMD).
* **Impact:** This will force *other games* on your system to re-compile their shaders the next time you launch them.
* **Result:** You may experience temporary stuttering in other games during their first launch after running this script. This is normal and often beneficial for clearing out old or corrupted shader data.

---

## 🚀 Overview
This suite is designed to eliminate stuttering, reduce input latency, and improve overall FPS stability in *Sea of Thieves*. It targets the common causes of performance degradation: bloated shader caches, unoptimized engine configuration (Unreal Engine 4), and sub-optimal driver handling.

**Supported Platforms:** Steam & Windows Store (Xbox App/Game Pass) & Battle.net (Manual Method only)

---

## 📥 Method 1: Automated Optimization (Recommended)
The provided PowerShell script (`sotoptimize.ps1`) handles all file operations safely and automatically.

### Usage
1.  Download the `sotoptimize.ps1` script to your PC.
2.  Right-click the file and select **Run with PowerShell**.
3.  **Administrator privileges** are required to clear system-level shader caches. Accept the elevation prompt.
4.  Follow the interactive menu:
    * **Option 1 (Auto-Detect):** Recommended. Cleans all caches and deploys optimized configs.
    * **Option 2 (Custom Steam Path):** Use this if your Steam library is on a custom drive.

> **Note:** The script automatically backs up your existing configuration files (`.bak`) before applying changes.

---

## 🛠️ Method 2: Manual Instructions
If you do not wish to use the automated script, follow these steps manually.

### 1. Clear Shader Caches
Delete the contents of the following folders (if they exist on your system):

**NVIDIA Users:**
* `%ProgramData%\NVIDIA Corporation\NV_Cache`
* `%LOCALAPPDATA%\NVIDIA\DXCache`
* `%LOCALAPPDATA%\NVIDIA\GLCache`

**AMD Users:**
* `%LOCALAPPDATA%\AMD\DxCache`
* `%LOCALAPPDATA%\AMD\DxcCache`

**General (All Users):**
* `%LOCALAPPDATA%\D3DSCache`
* `%LOCALAPPDATA%\Athena` (Search for and delete any `.upsoprecache` or `.ushaderprecache` files)

**Steam Users:**
* `<SteamLibrary>\steamapps\shadercache\1172620`

### 2. Update Configuration Files
Navigate to your config folder:
* **Steam:** `%LOCALAPPDATA%\Athena\Saved\Config\WindowsClient`
* **Windows Store:** `%LOCALAPPDATA%\Athena\Saved\Config\WinGDK`

**Instructions:**
1.  Open `Engine.ini` and `GameUserSettings.ini`.
2.  Replace their content with the blocks below.
3.  Save the files.
4.  **Right-click the files > Properties > Check "Read-only"**. (This prevents the game from resetting them).

#### Engine.ini
```ini
[Core.System]
Paths=../../../Engine/Content
Paths=../../../Athena/Content
Paths=../../../Engine/Plugins/2D/Paper2D/Content
Paths=../../../Engine/Plugins/Rare/RareShaderTest/Content
Paths=../../../Engine/Plugins/Runtime/Coherent/CoherentUIGTPlugin/Content

; --- ANTI-ALIASING ---
r.DefaultFeature.AntiAliasing=0
r.PostProcessAAQuality=0

; --- PERFORMANCE & MEMORY ---
r.Streaming.PoolSize=4096
r.Streaming.LimitPoolSizeToVRAM=1
r.TextureStreaming=1
r.CreateShadersOnLoad=1
r.XGEShaderCompile=1
s.ForceGCAfterLevelStreamedOut=0
s.ContinuouslyIncrementalGCWhileLevelsPendingPurge=0

; --- NETWORK OPTIMIZATION ---
ConfiguredInternetSpeed=100000
ConfiguredLanSpeed=100000
NetServerMaxTickRate=120
LanMaxClientRate=100000
InternetMaxClientRate=100000
TotalNetBandwidth=100000
MaxDynamicBandwidth=100000
MinDynamicBandwidth=20000

; --- INPUT LATENCY ---
r.OneFrameThreadLag=0
r.FinishCurrentFrame=0
m.MouseSmoothing=0

; --- VISUAL CLARITY ---
r.DefaultFeature.AntiAliasing=0
r.PostProcessAAQuality=0
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
r.ShadowQuality=0
r.Shadow.DistanceScale=0
r.ContactShadows=0
r.Shadow.CSM.MaxCascades=0
r.Shadow.MaxResolution=512
```
#### GameUserSettings.ini
```ini
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
SmoothFPS=False
HDR=False
Fullscreen=True
bUseVSync=False
D3DVersion=12
ParallelRendering=True
GpuCrashDetection=False
```
## ⚡ Launch Options (Required)
Add these arguments to force DirectX 12 and optimize memory allocation.

**Arguments:**
```
-dx12 -USEALLAVAILABLECORES -high -nothreadtimeout -NoVerifyGC -malloc=system
```
**Steam:**
Right-click *Sea of Thieves* > **Properties** > **General** > Paste into **Launch Options**.

**Windows Store / Xbox App:**
1.  Open Xbox App > Right-click *Sea of Thieves* > **Manage** > **Create Desktop Shortcut**.
2.  Go to Desktop > Right-click the new shortcut > **Properties**.
3.  Add the arguments to the very end of the **Target** field (ensure there is a space before the dash).
4.  **Always launch via this shortcut.**

**Battle.net:**
Click the **Gear Icon** next to Play > **Game Settings** > Check **Additional command line arguments** > Paste the arguments.

## 🟢 Nvidia Profile Inspector Tweaks
For advanced driver-level optimization, use [Nvidia Profile Inspector](https://github.com/Orbmu2k/nvidiaProfileInspector/releases).

1.  Open Profile Inspector.
2.  Select **Sea of Thieves** from the profile dropdown.
3.  Apply the exact settings below:

| Section | Setting | Value |
| :--- | :--- | :--- |
| **2 - Sync & Refresh** | Frame Rate Limiter V3 | `160 FPS` |
| **2 - Sync & Refresh** | Maximum Pre-rendered Frames | `1` |
| **2 - Sync & Refresh** | Vertical Sync | `Force Off` |
| **2 - Sync & Refresh** | Low Latency Mode | `On` |
| **4 - Texture Filtering** | Anisotropic filtering mode | `Off` |
| **5 - Common** | Power management mode | `Prefer maximum performance` |
| **5 - Common** | Shader cache | `Enabled` |
| **5 - Common** | Shader cache size | `Unlimited` |
| **5 - Common** | Threaded optimization | `On` |
| **5 - Common** | ReBar Feature | `Enabled` |
| **5 - Common** | ReBar Options | `0x00000001` |
| **5 - Common** | ReBar Size Limit | `0x00000004000000` |

4.  Click **Apply changes** (Top Right).
