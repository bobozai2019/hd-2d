@echo off
setlocal
set "RENDERDOC_BRIDGE_BOOTSTRAPPED=1"
set "RENDERDOC_BRIDGE_PROJECT=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\renderdoc_bridge\start_renderdoc_godot.ps1" -GodotExe "D:/godot/Godot_v4.6.2/godot.exe" -ProjectRoot "D:/godot/project/hd-2d/" -RenderDocCmd "D:/other_software/RenderDoc/renderdoccmd.exe"
endlocal
