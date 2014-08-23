; install.nsi
; Installation script for Wrye Flash NSIS installer.


;-------------------------------- The Installation Sections:

    Section "Prerequisites" Prereq
        SectionIn RO

        ClearErrors
        
        ; Python version requires Python, wxPython, Python Comtypes and PyWin32.
        ${If} $PythonVersionInstall == $True
            ; Look for Python.
            ReadRegStr $Python_Path HKLM "SOFTWARE\Wow6432Node\Python\PythonCore\2.7\InstallPath" ""
            ${If} $Python_Path == $Empty
                ReadRegStr $Python_Path HKLM "SOFTWARE\Python\PythonCore\2.7\InstallPath" ""
            ${EndIf}
            ${If} $Python_Path == $Empty
                ReadRegStr $Python_Path HKCU "SOFTWARE\Wow6432Node\Python\PythonCore\2.7\InstallPath" ""
            ${EndIf}
            ${If} $Python_Path == $Empty
                ReadRegStr $Python_Path HKCU "SOFTWARE\Python\PythonCore\2.7\InstallPath" ""
            ${EndIf}

            ;Detect Python Components:
            ${If} $Python_Path != $Empty
                ;Detect Comtypes:
                ${If} ${FileExists} "$Python_Path\Lib\site-packages\comtypes\__init__.py"
                    FileOpen $2 "$Python_Path\Lib\site-packages\comtypes\__init__.py" r
                    FileRead $2 $1
                    FileRead $2 $1
                    FileRead $2 $1
                    FileRead $2 $1
                    FileRead $2 $1
                    FileRead $2 $1
                    FileClose $2
                    StrCpy $Python_Comtypes $1 5 -8
                    ${VersionConvert} $Python_Comtypes "" $Python_Comtypes
                    ${VersionCompare} $MinVersion_Comtypes $Python_Comtypes $Python_Comtypes
                ${EndIf}

                ; Detect wxPython.
                ReadRegStr $Python_wx HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\wxPython2.8-unicode-py27_is1" "DisplayVersion"
                ${If} $Python_wx == $Empty
                    ReadRegStr $Python_wx HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\wxPython2.8-unicode-py27_is1" "DisplayVersion"
                ${EndIf}
                ; Detect PyWin32.
                ReadRegStr $1         HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\pywin32-py2.7" "DisplayName"
                ${If} $1 == $Empty
                    ReadRegStr $1         HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\pywin32-py2.7" "DisplayName"
                ${EndIf}
                StrCpy $Python_pywin32 $1 3 -3

                ; Compare versions.
                ${VersionCompare} $MinVersion_pywin32 $Python_pywin32 $Python_pywin32
                ${VersionConvert} $Python_wx "+" $Python_wx
                ${VersionCompare} $MinVersion_wx $Python_wx $Python_wx
            ${EndIf}

            ; Download and install missing requirements.
            ${If} $Python_Path == $Empty
                SetOutPath "$TEMP\PythonInstallers"
                DetailPrint "Python 2.7.8 - Downloading..."
                inetc::get /NOCANCEL /RESUME "" "https://www.python.org/ftp/python/2.7.8/python-2.7.8.msi" "$TEMP\PythonInstallers\python-2.7.8.msi"
                Pop $R0
                ${If} $R0 == "OK"
                    DetailPrint "Python 2.7.8 - Installing..."
                    Sleep 2000
                    HideWindow
                    ExecWait '"msiexec" /i "$TEMP\PythonInstallers\python-2.7.8.msi"'
                    BringToFront
                    DetailPrint "Python 2.7.8 - Installed."
                ${Else}
                    DetailPrint "Python 2.7.8 - Download Failed!"
                    MessageBox MB_OK "Python download failed, please try running installer again or manually downloading."
                    Abort
                ${EndIf}
            ${Else}
                DetailPrint "Python 2.7 is already installed; skipping!"
            ${EndIf}
            ${If} $Python_wx == "1"
                SetOutPath "$TEMP\PythonInstallers"
                DetailPrint "wxPython 2.8.12.1 - Downloading..."
                NSISdl::download http://downloads.sourceforge.net/wxpython/wxPython2.8-win32-unicode-2.8.12.1-py27.exe "$TEMP\PythonInstallers\wxPython.exe"
                Pop $R0
                ${If} $R0 == "success"
                    DetailPrint "wxPython 2.8.12.1 - Installing..."
                    Sleep 2000
                    HideWindow
                    ExecWait '"$TEMP\PythonInstallers\wxPython.exe"'; /VERYSILENT'
                    BringToFront
                    DetailPrint "wxPython 2.8.12.1 - Installed."
                ${Else}
                    DetailPrint "wxPython 2.8.12.1 - Download Failed!"
                    MessageBox MB_OK "wxPython download failed, please try running installer again or manually downloading."
                    Abort
                ${EndIf}
            ${Else}
                DetailPrint "wxPython 2.8.12.1 is already installed; skipping!"
            ${EndIf}
            ${If} $Python_Comtypes == "1"
                SetOutPath "$TEMP\PythonInstallers"
                DetailPrint "Comtypes 0.6.2 - Downloading..."
                NSISdl::download http://downloads.sourceforge.net/project/comtypes/comtypes/0.6.2/comtypes-0.6.2.win32.exe "$TEMP\PythonInstallers\comtypes.exe"
                Pop $R0
                ${If} $R0 == "success"
                    DetailPrint "Comtypes 0.6.2 - Installing..."
                    Sleep 2000
                    HideWindow
                    ExecWait  '"$TEMP\PythonInstallers\comtypes.exe"'
                    BringToFront
                    DetailPrint "Comtypes 0.6.2 - Installed."
                ${Else}
                    DetailPrint "Comtypes 0.6.2 - Download Failed!"
                    MessageBox MB_OK "Comtypes download failed, please try running installer again or manually downloading: $0."
                    Abort
                ${EndIf}
            ${Else}
                DetailPrint "Comtypes 0.6.2 is already installed; skipping!"
            ${EndIf}
            ${If} $Python_pywin32 == "1"
                SetOutPath "$TEMP\PythonInstallers"
                DetailPrint "PyWin32 - Downloading..."
                NSISdl::download http://downloads.sourceforge.net/project/pywin32/pywin32/Build%20218/pywin32-218.win32-py2.7.exe "$TEMP\PythonInstallers\pywin32.exe"
                Pop $R0
                ${If} $R0 == "success"
                    DetailPrint "PyWin32 - Installing..."
                    Sleep 2000
                    HideWindow
                    ExecWait  '"$TEMP\PythonInstallers\pywin32.exe"'
                    BringToFront
                    DetailPrint "PyWin32 - Installed."
                ${Else}
                    DetailPrint "PyWin32 - Download Failed!"
                    MessageBox MB_OK "PyWin32 download failed, please try running installer again or manually downloading."
                    Abort
                ${EndIf}
            ${Else}
                DetailPrint "PyWin32 is already installed; skipping!"
            ${EndIf}
        ${EndIf}
    SectionEnd

    Section "Wrye Flash" Main
        SectionIn RO

        ${If} $CheckState_NV == ${BST_CHECKED}
            ; Install resources:
            ${If} Path_NV != $Empty
                !insertmacro InstallBashFiles "FalloutNV" "FalloutNV" "$Path_NV" $Reg_Value_NV_Py $Reg_Value_NV_Exe "FalloutNV Path" $CheckState_NV_Py $CheckState_NV_Exe true
            ${EndIf}
        ${EndIf}
        ; Write the uninstall keys for Windows
        SetOutPath "$COMMONFILES\Wrye FlashFO3"
        WriteRegStr HKLM "Software\Wrye FlashFO3" "Installer Path" "$EXEPATH"
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Wrye FlashFO3" "DisplayName" "Wrye FlashFO3"
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Wrye FlashFO3" "UninstallString" '"$COMMONFILES\Wrye FlashFO3\uninstall.exe"'
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Wrye FlashFO3" "URLInfoAbout" 'http://www.nexusmods.com/fallout3/mods/11336'
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Wrye FlashFO3" "HelpLink" 'http://forums.bethsoft.com/topic/1211142-relz-wrye-flash/'
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Wrye FlashFO3" "Publisher" 'Wrye & Wrye Flash Development Team'
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Wrye FlashFO3" "DisplayVersion" '${WB_FILEVERSION}'
        WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Wrye FlashFO3" "NoModify" 1
        WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Wrye FlashFO3" "NoRepair" 1
        CreateDirectory "$COMMONFILES\Wrye FlashFO3"
        WriteUninstaller "$COMMONFILES\Wrye FlashFO3\uninstall.exe"
    SectionEnd

    Section "Start Menu Shortcuts" Shortcuts_SM

        CreateDirectory "$SMPROGRAMS\Wrye FlashFO3"
        CreateShortCut "$SMPROGRAMS\Wrye FlashFO3\Uninstall.lnk" "$COMMONFILES\Wrye FlashFO3\uninstall.exe" "" "$COMMONFILES\Wrye FlashFO3\uninstall.exe" 0

        ${If} $CheckState_NV == ${BST_CHECKED}
            ${If} Path_NV != $Empty
                SetOutPath $Path_NV\Mopy
                ${If} $CheckState_NV_Py == ${BST_CHECKED}
                    CreateShortCut "$SMPROGRAMS\Wrye FlashFO3\Wrye FlashFO3 - FalloutNV.lnk" "$Path_NV\Mopy\Wrye Flash Launcher.pyw" "" "$Path_NV\Mopy\bash\images\bash_32.ico" 0
                    CreateShortCut "$SMPROGRAMS\Wrye FlashFO3\Wrye FlashFO3 - FalloutNV (Debug Log).lnk" "$Path_NV\Mopy\Wrye Flash Debug.bat" "" "$Path_NV\Mopy\bash\images\bash_32.ico" 0
                    ${If} $CheckState_NV_Exe == ${BST_CHECKED}
                        CreateShortCut "$SMPROGRAMS\Wrye FlashFO3\Wrye FlashFO3 (Standalone) - FalloutNV.lnk" "$Path_NV\Mopy\Wrye Flash.exe"
                        CreateShortCut "$SMPROGRAMS\Wrye FlashFO3\Wrye FlashFO3 (Standalone) - FalloutNV (Debug Log).lnk" "$Path_NV\Mopy\Wrye Flash.exe" "-d"
                    ${EndIf}
                ${ElseIf} $CheckState_NV_Exe == ${BST_CHECKED}
                    CreateShortCut "$SMPROGRAMS\Wrye FlashFO3\Wrye FlashFO3 - FalloutNV.lnk" "$Path_NV\Mopy\Wrye Flash.exe"
                    CreateShortCut "$SMPROGRAMS\Wrye FlashFO3\Wrye FlashFO3 - FalloutNV (Debug Log).lnk" "$Path_NV\Mopy\Wrye Flash.exe" "-d"
                ${EndIf}
            ${EndIf}
        ${EndIf}
    SectionEnd
