; pages.nsi
; Custom pages for the Wrye Flash NSIS installer / uninstaller


;---------------------------- Install Locations Page
    Function PAGE_INSTALLLOCATIONS
        !insertmacro MUI_HEADER_TEXT $(PAGE_INSTALLLOCATIONS_TITLE) $(PAGE_INSTALLLOCATIONS_SUBTITLE)
        GetFunctionAddress $Function_Browse OnClick_Browse
        ; GetFunctionAddress $Function_Extra OnClick_Extra
        nsDialogs::Create 1018
            Pop $Dialog

        ${If} $Dialog == error
            Abort
        ${EndIf}

        ${NSD_CreateLabel} 0 0 100% 24u "Select which Game(s)/Extra location(s) which you would like to install Wrye Flash for.$\nAlso select which version(s) to install (Standalone exe (default) and/or Python version)."
            Pop $Label
            IntOp $0 0 + 25
        ${If} $Path_FO3 != $Empty
            ${NSD_CreateCheckBox} 0 $0u 30% 13u "Install for FalloutNV"
                Pop $Check_FO3
                ${NSD_SetState} $Check_FO3 $CheckState_FO3
            ${NSD_CreateCheckBox} 30% $0u 40% 13u "Wrye Flash [Standalone]"
                Pop $Check_FO3_Exe
                ${NSD_AddStyle} $Check_FO3_Exe ${WS_GROUP}
                ${NSD_SetState} $Check_FO3_Exe  $CheckState_FO3_Exe
            ${NSD_CreateCheckBox} 70% $0u 30% 13u "Wrye Flash [Python]"
                Pop $Check_FO3_Py
;                ${NSD_SetState} $Check_FO3_Py  $CheckState_FO3_Py
            IntOp $0 $0 + 13
            ${NSD_CreateDirRequest} 0 $0u 90% 13u "$Path_FO3"
                Pop $PathDialogue_FO3
            ${NSD_CreateBrowseButton} -10% $0u 5% 13u "..."
                Pop $Browse_FO3
                nsDialogs::OnClick $Browse_FO3 $Function_Browse
            IntOp $0 $0 + 13
        ${EndIf}
        nsDialogs::Show
    FunctionEnd

    Function PAGE_INSTALLLOCATIONS_Leave
        # in case the user goes back to this page and changes selections
        StrCpy $PythonVersionInstall $Empty
        StrCpy $ExeVersionInstall $Empty

        ; Game paths
        ${NSD_GetText} $PathDialogue_FO3 $Path_FO3

        ; Game states
        ${NSD_GetState} $Check_FO3 $CheckState_FO3

        ; Python states
        ${NSD_GetState} $Check_FO3_Py $CheckState_FO3_Py
        ${If} $CheckState_FO3_Py == ${BST_CHECKED}
        ${AndIf} $CheckState_FO3 == ${BST_CHECKED}
            StrCpy $PythonVersionInstall $True
        ${Endif}

        ; Standalone states
        ${NSD_GetState} $Check_FO3_Exe $CheckState_FO3_Exe
        ${If} $CheckState_FO3_Exe == ${BST_CHECKED}
        ${AndIf} $CheckState_FO3 == ${BST_CHECKED}
            StrCpy $ExeVersionInstall $True
        ${Endif}
    FunctionEnd


;---------------------------- Check Locations Page
    Function PAGE_CHECK_LOCATIONS
        !insertmacro MUI_HEADER_TEXT $(PAGE_CHECK_LOCATIONS_TITLE) $(PAGE_CHECK_LOCATIONS_SUBTITLE)

        ; test for installation in program files
        StrCpy $1 $Empty
        ${If} $CheckState_FO3 == ${BST_CHECKED}
            ${StrLoc} $0 $Path_FO3 "$PROGRAMFILES\" ">"
            ${If} "0" == $0
                StrCpy $1 $True
            ${Endif}
        ${Endif}

        ${If} $1 == $Empty
            ; nothing installed in program files: skip this page
            Abort
        ${Endif}

        nsDialogs::Create 1018
            Pop $Dialog
        ${If} $Dialog == error
            Abort
        ${EndIf}

        ${NSD_CreateLabel} 0 0 100% 24u "You are attempting to install Wrye Flash into the Program Files directory."
        Pop $Label
        SetCtlColors $Label "FF0000" "transparent"

        ${NSD_CreateLabel} 0 24 100% 128u "This is a very common cause of problems when using Wrye Flash. Highly recommended that you stop this installation now, reinstall (FalloutNV/Skyrim/Steam) into another directory outside of Program Files, such as C:\Games\FalloutNV, and install Wrye Flash at that location.$\n$\nThe problems with installing in Program Files stem from a feature of Windows that did not exist when FalloutNV was released: User Access Controls (UAC).  If you continue with the install into Program Files, you may have trouble starting or using Wrye Flash, as it may not be able to access its own files."
        Pop $Label

        nsDialogs::Show
    FunctionEnd

    Function PAGE_CHECK_LOCATIONS_Leave
    FunctionEnd


;---------------------------- Finish Page
    Function PAGE_FINISH
        !insertmacro MUI_HEADER_TEXT $(PAGE_FINISH_TITLE) $(PAGE_FINISH_SUBTITLE)

        ReadRegStr $Path_FO3 HKLM "Software\Wrye FlashFO3" "FalloutNV Path"

        nsDialogs::Create 1018
            Pop $Dialog
        ${If} $Dialog == error
            Abort
        ${EndIf}

        IntOp $0 0 + 0
        ${NSD_CreateLabel} 0 0 100% 16u "Please select which Wrye Flash installation(s), if any, you would like to run right now:"
            Pop $Label
        IntOp $0 0 + 17
        ${If} $Path_FO3 != $Empty
            ${NSD_CreateCheckBox} 0 $0u 100% 8u "Fallout3"
                Pop $Check_FO3
            IntOp $0 $0 + 9
        ${EndIf}
        IntOp $0 $0 + 9
        IntOp $1 0 + 0
        ${NSD_CreateCheckBox} $1% $0u 25% 8u "View Readme"
            Pop $Check_Readme
            ${NSD_SetState} $Check_Readme ${BST_CHECKED}
            IntOp $1 $1 + 25
        ${NSD_CreateCheckBox} $1% $0u 75% 8u "Delete files from old Bash versions"
            Pop $Check_DeleteOldFiles
            ${NSD_SetState} $Check_DeleteOldFiles ${BST_CHECKED}
        nsDialogs::Show
    FunctionEnd

    Function PAGE_FINISH_Leave
        ${NSD_GetState} $Check_FO3 $CheckState_FO3

        ${If} $CheckState_FO3 == ${BST_CHECKED}
            SetOutPath "$Path_FO3\Mopy"
            ${If} $CheckState_FO3_Py == ${BST_CHECKED}
                ExecShell "open" '"$Path_FO3\Mopy\Wrye Flash Launcher.pyw"'
            ${ElseIf} $CheckState_FO3_Exe == ${BST_CHECKED}
                ExecShell "open" "$Path_FO3\Mopy\Wrye Flash.exe"
            ${EndIf}
        ${EndIf}
        ${NSD_GetState} $Check_Readme $0
        ${If} $0 == ${BST_CHECKED}
            ${If} $Path_FO3 != $Empty
                ExecShell "open" "$Path_FO3\Mopy\Wrye Flash.html"
            ${EndIf}
        ${EndIf}
        ${NSD_GetState} $Check_DeleteOldFiles $0
        ${If} $0 == ${BST_CHECKED}
            ${If} $Path_FO3 != $Empty
                !insertmacro RemoveOldFiles "$Path_FO3"
            ${EndIf}
        ${EndIf}
    FunctionEnd


;----------------------------- Custom Uninstallation Pages and their Functions:
    Function un.PAGE_SELECT_GAMES
        !insertmacro MUI_HEADER_TEXT $(PAGE_INSTALLLOCATIONS_TITLE) $(unPAGE_SELECT_GAMES_SUBTITLE)
        GetFunctionAddress $unFunction_Browse un.OnClick_Browse

        nsDialogs::Create 1018
            Pop $Dialog
        ${If} $Dialog == error
            Abort
            ${EndIf}

        ${NSD_CreateLabel} 0 0 100% 8u "Please select which game(s)/extra location(s) and version(s) to uninstall Wrye Flash from:"
        Pop $Label

        IntOp $0 0 + 9
        ${If} $Path_FO3 != $Empty
            ${NSD_CreateCheckBox} 0 $0u 100% 13u "&FalloutNV"
                Pop $Check_FO3
                ${NSD_SetState} $Check_FO3 $CheckState_FO3
            IntOp $0 $0 + 13
            ${NSD_CreateDirRequest} 0 $0u 90% 13u "$Path_FO3"
                Pop $PathDialogue_FO3
            ${NSD_CreateBrowseButton} -10% $0u 5% 13u "..."
                Pop $Browse_FO3
                nsDialogs::OnClick $Browse_FO3 $Function_Browse
            IntOp $0 $0 + 13
        ${EndIf}
        ;${NSD_CreateCheckBox} 0 $0u 100% 13u "Uninstall userfiles/Bash data."
        ;    Pop $Check_RemoveUserFiles
        ;    ${NSD_SetState} $Check_RemoveUserFiles ${BST_CHECKED}
        nsDialogs::Show
    FunctionEnd

    Function un.PAGE_SELECT_GAMES_Leave
        ${NSD_GetText} $PathDialogue_FO3 $Path_FO3
        ${NSD_GetState} $Check_FO3 $CheckState_FO3
    FunctionEnd
