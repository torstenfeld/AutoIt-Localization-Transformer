

#Region ### AutoIt Options

	Opt("MustDeclareVars", 1)

#EndRegion

#region ### includes

	#Include <File.au3>
	#Include <Array.au3>
	#Include <String.au3>

	#include <ButtonConstants.au3>
	#include <EditConstants.au3>
	#include <GUIConstantsEx.au3>
	#include <ListViewConstants.au3>
	#include <StaticConstants.au3>
	#include <WindowsConstants.au3>
	#include <GuiListView.au3>

#EndRegion

#region ### global variables

	Global $gDirTemp = @TempDir & "\au3loctranformer"
	Global $gDbgFile = $gDirTemp & "\au3loctranformer.log"
	Global $gFileIniWithStrings = @ScriptDir & "\localization.ini" ; ini file with strings and corresponding properties

;~ 	Global $gScriptAndIniFilePath ; path to the script chosen where ini will be stored

	Global $gMsgBoxTitle = "Au3 Localization Transformer"

	Global $gFileToTransform ; au3 file incl. path
	Global $gFileToWriteOutput ; copy of au3 file with exchanged strings

	Global $gaListOfStrings[1][2] ; list of strings found
	Global $gaListofFileLines ; stores the lines of $gFileToTransform

	Global $gListViewItemSelected ; index of the item selected in $ListView_Strings

	Global $ListView_Strings ; listview for strings and IDS in GUI
	global $Input_String ; input field for changing IDS of listview array

#EndRegion

#Region ### main

	if not FileExists($gDirTemp) then DirCreate($gDirTemp)
	if FileExists($gDbgFile) then FileDelete($gDbgFile)

	_Main()

#EndRegion

Func _Main()

	ConsoleWrite(@AutoItVersion & @CRLF)
	_GetFileFromUser()
;~ 	$gFileToTransform = @ScriptDir & "\testfile.au3"

	_ReadAu3FileToArray()
;~ 	_ArrayDisplay($gaListofFileLines, "$gaListofFileLines")
	_GetStringsFromArray()
	_GuiListOfStrings()

EndFunc

Func _WriteStringToLocalizationIni()

	_WriteDebug("INFO;_WriteStringToLocalizationIni;_WriteStringToLocalizationIni started")

	for $i = 1 to UBound($gaListOfStrings)-1 ; count from 1 as in 0 index is the amount of strings / array size
		IniWrite($gFileIniWithStrings, "0000", $gaListOfStrings[$i][0], $gaListOfStrings[$i][1])
	Next

	_WriteDebug("INFO;_WriteStringToLocalizationIni;_WriteStringToLocalizationIni ended")
EndFunc

Func _GetStringsFromArray()

	local $laStringsLine
	local $lStringMarker ; apostroph or double quote
	local $lFuncName = ""; the name of the function in which the string was found
	local $lFuncNameTemp = ""
	local $lCountForIds = 1

	for $i = 1 to $gaListofFileLines[0]

		$lStringMarker = _CheckForStringMarker($gaListofFileLines[$i])

		Select
			case StringRegExp($gaListofFileLines[$i], "^Func\s([_\w\d]*\(.*\))") ; check for line with func start and store name of func in $lFuncName
				$lFuncName = StringRegExpReplace($gaListofFileLines[$i], "^Func\s([_\w\d]*\(.*\)).*", "$1") ; get complete function name
				if StringRegExpReplace($lFuncName, ".*\((.*)\).*", "$1") <> "" then $lFuncName = StringReplace($lFuncName, StringRegExpReplace($lFuncName, ".*\((.*)\).*", "$1"), "") ; remove parameters of function name
				$lFuncName = StringReplace($lFuncName, "()", "") ; removes brackets of function name
				ContinueLoop
			case StringRegExp($gaListofFileLines[$i], "^;.*") ; if it's a comment
				ContinueLoop
			case StringInStr($gaListofFileLines[$i], "MsgBox(") ; search for msgbox strings
			case StringInStr($gaListofFileLines[$i], "guictrlbutton(") ; search for button labels
			case StringInStr($gaListofFileLines[$i], "GUICtrlSetTip(") ; search for gui tips
			case Else ; skip everything else
				ContinueLoop
		EndSelect

		$laStringsLine = _StringBetween($gaListofFileLines[$i], $lStringMarker, $lStringMarker) ; get all the strings between the markers ($lStringMarker)
		if @error Then
			_WriteDebug("WARN;_GetStringsFromArray;_StringBetween returned with error: " & @error & " on string '" & StringReplace($gaListofFileLines[$i], ";", "") & "'")
			ContinueLoop
		EndIf

		for $j = 0 to UBound($laStringsLine)-1
			if StringLeft($lFuncName, 1) = "_" Then $lFuncName = StringTrimLeft($lFuncName, 1) ; remove first _ from function name
			if $lFuncNameTemp = $lFuncName Then ; if $lFuncName is the same as in the previous step
				$lCountForIds += 1 ; increase $lCountForIds by 1
			Else ; if not
				$lFuncNameTemp = $lFuncName ; set $lFuncNameTemp with the new $lFuncName
				$lCountForIds = 1 ; reset to 1
			EndIf
			_Array2DAdd($gaListOfStrings, _CreateStringId($lFuncName, $lCountForIds) & "|" & $laStringsLine[$j])
		Next
	Next
	_ArrayDelete($gaListOfStrings, 0) ; delete 0-index
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _CreateStringId
; Description ...: creates the ID for the string written to array / ini file
; Syntax ........: _CreateStringId($lFuncName, $lNumber[, $lPrefix = "IDS_"])
; Parameters ....: $lFuncName           - name of the function in which the string occurs
;                  $lNumber             - auto incremented number if more than one string is found in a function
;                  $lPrefix             - [optional] Prefix for the String ID. Default is "IDS_".
; Return values .: complete string ID
; Author ........: Torsten Feld
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _CreateStringId($lFuncName, $lNumber, $lPrefix = "IDS_")

	Return $lPrefix & $lFuncName & "_" & $lNumber

EndFunc

Func _GuiListOfStrings()

	_WriteDebug("INFO;_GuiListOfStrings;_GuiListOfStrings started")

	#Region ### START Koda GUI section ### Form=
	local $Form_ListStrings = GUICreate($gMsgBoxTitle, 615, 377, 192, 124)
	$ListView_Strings = _GUICtrlListView_Create($Form_ListStrings, "", 8, 64, 601, 233, BitOR($LVS_REPORT, $LVS_SINGLESEL, $LVS_SHOWSELALWAYS))
	local $Label_Desc = GUICtrlCreateLabel("blablabla text", 8, 16, 66, 17)
	$Input_String = GUICtrlCreateInput("", 8, 312, 249, 21)
	local $Button_Modify = GUICtrlCreateButton("Modify", 264, 312, 75, 25)
	local $Button_Close = GUICtrlCreateButton("Close", 8, 344, 603, 25)
	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###

	local $nMsg
	GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")

	_GUICtrlListView_SetExtendedListViewStyle($ListView_Strings, BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT))

	_GUICtrlListView_InsertColumn($ListView_Strings, 0, "IDS", 200)
    _GUICtrlListView_InsertColumn($ListView_Strings, 1, "String", 380)
	_GUICtrlListView_AddArray($ListView_Strings, $gaListOfStrings)

	for $i = 0 to _GUICtrlListView_GetItemCount($ListView_Strings)
		_GUICtrlListView_SetItemChecked($ListView_Strings, $i)
	Next

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE, $Button_Close
				_RemoveUncheckedItemsOfListview()
				$gaListOfStrings = _GUICtrlListView_CreateArray($ListView_Strings)
				_WriteStringToLocalizationIni()
				GUIDelete($Form_ListStrings)
				_WriteDebug("INFO;_GuiListOfStrings;$Form_ListStrings deleted")
				ExitLoop
			case $Button_Modify
				_GUICtrlListView_SetItemText($ListView_Strings, $gListViewItemSelected, GUICtrlRead($Input_String))

		EndSwitch
	WEnd
	_WriteDebug("INFO;_GuiListOfStrings;_GuiListOfStrings ended")

EndFunc

Func _RemoveUncheckedItemsOfListview()

	for $i = _GUICtrlListView_GetItemCount($ListView_Strings) to 0 Step -1
		if not _GUICtrlListView_GetItemChecked($ListView_Strings, $i) then
			_GUICtrlListView_DeleteItem($ListView_Strings, $i)
			_WriteDebug("INFO;_RemoveUncheckedItemsOfListview;deleted item " & _GUICtrlListView_GetItemText($ListView_Strings, $i) & " with index " & $i)
		EndIf
	Next

EndFunc

Func WM_NOTIFY($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg, $iwParam
    Local $hWndFrom, $iIDFrom, $iCode, $tNMHDR, $hWndListView, $tInfo
;~  Local $tBuffer
    $hWndListView = $ListView_Strings
    local $hListView = $ListView_Strings
    If Not IsHWnd($hListView) Then $hWndListView = GUICtrlGetHandle($hListView)

    $tNMHDR = DllStructCreate($tagNMHDR, $ilParam)
    $hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
    $iIDFrom = DllStructGetData($tNMHDR, "IDFrom")
    $iCode = DllStructGetData($tNMHDR, "Code")
    Switch $hWndFrom
        Case $hWndListView
            Switch $iCode
;~              Case $LVN_BEGINDRAG ; A drag-and-drop operation involving the left mouse button is being initiated
;~                  $tInfo = DllStructCreate($tagNMLISTVIEW, $ilParam)
;~                  _DebugPrint("$LVN_BEGINDRAG" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode & @LF & _
;~                          "-->Item:" & @TAB & DllStructGetData($tInfo, "Item") & @LF & _
;~                          "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                          "-->NewState:" & @TAB & DllStructGetData($tInfo, "NewState") & @LF & _
;~                          "-->OldState:" & @TAB & DllStructGetData($tInfo, "OldState") & @LF & _
;~                          "-->Changed:" & @TAB & DllStructGetData($tInfo, "Changed") & @LF & _
;~                          "-->ActionX:" & @TAB & DllStructGetData($tInfo, "ActionX") & @LF & _
;~                          "-->ActionY:" & @TAB & DllStructGetData($tInfo, "ActionY") & @LF & _
;~                          "-->Param:" & @TAB & DllStructGetData($tInfo, "Param"))
;~                  ; No return value
;~              Case $LVN_BEGINLABELEDIT ; Start of label editing for an item
;~                  $tInfo = DllStructCreate($tagNMLVDISPINFO, $ilParam)
;~                  _DebugPrint("$LVN_BEGINLABELEDIT" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode & @LF & _
;~                          "-->Mask:" & @TAB & DllStructGetData($tInfo, "Mask") & @LF & _
;~                          "-->Item:" & @TAB & DllStructGetData($tInfo, "Item") & @LF & _
;~                          "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                          "-->State:" & @TAB & DllStructGetData($tInfo, "State") & @LF & _
;~                          "-->StateMask:" & @TAB & DllStructGetData($tInfo, "StateMask") & @LF & _
;~                          "-->Image:" & @TAB & DllStructGetData($tInfo, "Image") & @LF & _
;~                          "-->Param:" & @TAB & DllStructGetData($tInfo, "Param") & @LF & _
;~                          "-->Indent:" & @TAB & DllStructGetData($tInfo, "Indent") & @LF & _
;~                          "-->GroupID:" & @TAB & DllStructGetData($tInfo, "GroupID") & @LF & _
;~                          "-->Columns:" & @TAB & DllStructGetData($tInfo, "Columns") & @LF & _
;~                          "-->pColumns:" & @TAB & DllStructGetData($tInfo, "pColumns"))
;~                  Return False ; Allow the user to edit the label
;~                  ;Return True  ; Prevent the user from editing the label
;~              Case $LVN_BEGINRDRAG ; A drag-and-drop operation involving the right mouse button is being initiated
;~                  $tInfo = DllStructCreate($tagNMLISTVIEW, $ilParam)
;~                  _DebugPrint("$LVN_BEGINRDRAG" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode & @LF & _
;~                          "-->Item:" & @TAB & DllStructGetData($tInfo, "Item") & @LF & _
;~                          "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                          "-->NewState:" & @TAB & DllStructGetData($tInfo, "NewState") & @LF & _
;~                          "-->OldState:" & @TAB & DllStructGetData($tInfo, "OldState") & @LF & _
;~                          "-->Changed:" & @TAB & DllStructGetData($tInfo, "Changed") & @LF & _
;~                          "-->ActionX:" & @TAB & DllStructGetData($tInfo, "ActionX") & @LF & _
;~                          "-->ActionY:" & @TAB & DllStructGetData($tInfo, "ActionY") & @LF & _
;~                          "-->Param:" & @TAB & DllStructGetData($tInfo, "Param"))
;~                  ; No return value
;~              Case $LVN_BEGINSCROLL ; A scrolling operation starts, Minium OS WinXP
;~                  $tInfo = DllStructCreate($tagNMLVSCROLL, $ilParam)
;~                  _DebugPrint("$LVN_BEGINSCROLL" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode & @LF & _
;~                          "-->DX:" & @TAB & DllStructGetData($tInfo, "DX") & @LF & _
;~                          "-->DY:" & @TAB & DllStructGetData($tInfo, "DY"))
;~                  ; No return value
                Case $LVN_COLUMNCLICK ; A column was clicked
                    $tInfo = DllStructCreate($tagNMLISTVIEW, $ilParam)
                    _DebugPrint("$LVN_COLUMNCLICK" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
                            "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
                            "-->Code:" & @TAB & $iCode & @LF & _
                            "-->Item:" & @TAB & DllStructGetData($tInfo, "Item") & @LF & _
                            "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
                            "-->NewState:" & @TAB & DllStructGetData($tInfo, "NewState") & @LF & _
                            "-->OldState:" & @TAB & DllStructGetData($tInfo, "OldState") & @LF & _
                            "-->Changed:" & @TAB & DllStructGetData($tInfo, "Changed") & @LF & _
                            "-->ActionX:" & @TAB & DllStructGetData($tInfo, "ActionX") & @LF & _
                            "-->ActionY:" & @TAB & DllStructGetData($tInfo, "ActionY") & @LF & _
                            "-->Param:" & @TAB & DllStructGetData($tInfo, "Param"))
                    ; No return value
;~              Case $LVN_DELETEALLITEMS ; All items in the control are about to be deleted
;~                  $tInfo = DllStructCreate($tagNMLISTVIEW, $ilParam)
;~                  _DebugPrint("$LVN_DELETEALLITEMS" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode & @LF & _
;~                          "-->Item:" & @TAB & DllStructGetData($tInfo, "Item") & @LF & _
;~                          "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                          "-->NewState:" & @TAB & DllStructGetData($tInfo, "NewState") & @LF & _
;~                          "-->OldState:" & @TAB & DllStructGetData($tInfo, "OldState") & @LF & _
;~                          "-->Changed:" & @TAB & DllStructGetData($tInfo, "Changed") & @LF & _
;~                          "-->ActionX:" & @TAB & DllStructGetData($tInfo, "ActionX") & @LF & _
;~                          "-->ActionY:" & @TAB & DllStructGetData($tInfo, "ActionY") & @LF & _
;~                          "-->Param:" & @TAB & DllStructGetData($tInfo, "Param"))
;~                  Return True ; To suppress subsequent $LVN_DELETEITEM messages
;~                  ;Return False ; To receive subsequent $LVN_DELETEITEM messages
;~              Case $LVN_DELETEITEM ; An item is about to be deleted
;~                  $tInfo = DllStructCreate($tagNMLISTVIEW, $ilParam)
;~                  _DebugPrint("$LVN_DELETEITEM" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode & @LF & _
;~                          "-->Item:" & @TAB & DllStructGetData($tInfo, "Item") & @LF & _
;~                          "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                          "-->NewState:" & @TAB & DllStructGetData($tInfo, "NewState") & @LF & _
;~                          "-->OldState:" & @TAB & DllStructGetData($tInfo, "OldState") & @LF & _
;~                          "-->Changed:" & @TAB & DllStructGetData($tInfo, "Changed") & @LF & _
;~                          "-->ActionX:" & @TAB & DllStructGetData($tInfo, "ActionX") & @LF & _
;~                          "-->ActionY:" & @TAB & DllStructGetData($tInfo, "ActionY") & @LF & _
;~                          "-->Param:" & @TAB & DllStructGetData($tInfo, "Param"))
;~                  ; No return value
;~              Case $LVN_ENDLABELEDIT ; The end of label editing for an item
;~                  $tInfo = DllStructCreate($tagNMLVDISPINFO, $ilParam)
;~                  $tBuffer = DllStructCreate("char Text[" & DllStructGetData($tInfo, "TextMax") & "]", DllStructGetData($tInfo, "Text"))
;~                  _DebugPrint("$LVN_ENDLABELEDIT" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode & @LF & _
;~                          "-->Mask:" & @TAB & DllStructGetData($tInfo, "Mask") & @LF & _
;~                          "-->Item:" & @TAB & DllStructGetData($tInfo, "Item") & @LF & _
;~                          "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                          "-->State:" & @TAB & DllStructGetData($tInfo, "State") & @LF & _
;~                          "-->StateMask:" & @TAB & DllStructGetData($tInfo, "StateMask") & @LF & _
;~                          "-->Text:" & @TAB & DllStructGetData($tBuffer, "Text") & @LF & _
;~                          "-->TextMax:" & @TAB & DllStructGetData($tInfo, "TextMax") & @LF & _
;~                          "-->Image:" & @TAB & DllStructGetData($tInfo, "Image") & @LF & _
;~                          "-->Param:" & @TAB & DllStructGetData($tInfo, "Param") & @LF & _
;~                          "-->Indent:" & @TAB & DllStructGetData($tInfo, "Indent") & @LF & _
;~                          "-->GroupID:" & @TAB & DllStructGetData($tInfo, "GroupID") & @LF & _
;~                          "-->Columns:" & @TAB & DllStructGetData($tInfo, "Columns") & @LF & _
;~                          "-->pColumns:" & @TAB & DllStructGetData($tInfo, "pColumns"))
;~                  ; If Text is not empty, return True to set the item's label to the edited text, return false to reject it
;~                  ; If Text is empty the return value is ignored
;~                  Return True
;~              Case $LVN_ENDSCROLL ; A scrolling operation ends, Minium OS WinXP
;~                  $tInfo = DllStructCreate($tagNMLVSCROLL, $ilParam)
;~                  _DebugPrint("$LVN_ENDSCROLL" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode & @LF & _
;~                          "-->DX:" & @TAB & DllStructGetData($tInfo, "DX") & @LF & _
;~                          "-->DY:" & @TAB & DllStructGetData($tInfo, "DY"))
;~                  ; No return value
;~              Case $LVN_GETDISPINFO ; Provide information needed to display or sort a list-view item
;~                  $tInfo = DllStructCreate($tagNMLVDISPINFO, $ilParam)
;~                  $tBuffer = DllStructCreate("char Text[" & DllStructGetData($tInfo, "TextMax") & "]", DllStructGetData($tInfo, "Text"))
;~                  _DebugPrint("$LVN_GETDISPINFO" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode & @LF & _
;~                          "-->Mask:" & @TAB & DllStructGetData($tInfo, "Mask") & @LF & _
;~                          "-->Item:" & @TAB & DllStructGetData($tInfo, "Item") & @LF & _
;~                          "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                          "-->State:" & @TAB & DllStructGetData($tInfo, "State") & @LF & _
;~                          "-->StateMask:" & @TAB & DllStructGetData($tInfo, "StateMask") & @LF & _
;~                          "-->Text:" & @TAB & DllStructGetData($tBuffer, "Text") & @LF & _
;~                          "-->TextMax:" & @TAB & DllStructGetData($tInfo, "TextMax") & @LF & _
;~                          "-->Image:" & @TAB & DllStructGetData($tInfo, "Image") & @LF & _
;~                          "-->Param:" & @TAB & DllStructGetData($tInfo, "Param") & @LF & _
;~                          "-->Indent:" & @TAB & DllStructGetData($tInfo, "Indent") & @LF & _
;~                          "-->GroupID:" & @TAB & DllStructGetData($tInfo, "GroupID") & @LF & _
;~                          "-->Columns:" & @TAB & DllStructGetData($tInfo, "Columns") & @LF & _
;~                          "-->pColumns:" & @TAB & DllStructGetData($tInfo, "pColumns"))
;~                  ; No return value
;~              Case $LVN_GETINFOTIP ; Sent by a large icon view list-view control that has the $LVS_EX_INFOTIP extended style
;~                  $tInfo = DllStructCreate($tagNMLVGETINFOTIP, $ilParam)
;~                  $tBuffer = DllStructCreate("char Text[" & DllStructGetData($tInfo, "TextMax") & "]", DllStructGetData($tInfo, "Text"))
;~                  _DebugPrint("$LVN_GETINFOTIP" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode & @LF & _
;~                          "-->Flags:" & @TAB & DllStructGetData($tInfo, "Flags") & @LF & _
;~                          "-->Text:" & @TAB & DllStructGetData($tBuffer, "Text") & @LF & _
;~                          "-->TextMax:" & @TAB & DllStructGetData($tInfo, "TextMax") & @LF & _
;~                          "-->Item:" & @TAB & DllStructGetData($tInfo, "Item") & @LF & _
;~                          "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                          "-->lParam:" & @TAB & DllStructGetData($tInfo, "lParam"))
;~                  ; No return value
;~              Case $LVN_HOTTRACK ; Sent by a list-view control when the user moves the mouse over an item
;~                  $tInfo = DllStructCreate($tagNMLISTVIEW, $ilParam)
;~                  _DebugPrint("$LVN_HOTTRACK" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode & @LF & _
;~                          "-->Item:" & @TAB & DllStructGetData($tInfo, "Item") & @LF & _
;~                          "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                          "-->NewState:" & @TAB & DllStructGetData($tInfo, "NewState") & @LF & _
;~                          "-->OldState:" & @TAB & DllStructGetData($tInfo, "OldState") & @LF & _
;~                          "-->Changed:" & @TAB & DllStructGetData($tInfo, "Changed") & @LF & _
;~                          "-->ActionX:" & @TAB & DllStructGetData($tInfo, "ActionX") & @LF & _
;~                          "-->ActionY:" & @TAB & DllStructGetData($tInfo, "ActionY") & @LF & _
;~                          "-->Param:" & @TAB & DllStructGetData($tInfo, "Param"))
;~                  Return 0 ; allow the list view to perform its normal track select processing.
;~                  ;Return 1 ; the item will not be selected.
;~              Case $LVN_INSERTITEM ; A new item was inserted
;~                  $tInfo = DllStructCreate($tagNMLISTVIEW, $ilParam)
;~                  _DebugPrint("$LVN_INSERTITEM" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode & @LF & _
;~                          "-->Item:" & @TAB & DllStructGetData($tInfo, "Item") & @LF & _
;~                          "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                          "-->NewState:" & @TAB & DllStructGetData($tInfo, "NewState") & @LF & _
;~                          "-->OldState:" & @TAB & DllStructGetData($tInfo, "OldState") & @LF & _
;~                          "-->Changed:" & @TAB & DllStructGetData($tInfo, "Changed") & @LF & _
;~                          "-->ActionX:" & @TAB & DllStructGetData($tInfo, "ActionX") & @LF & _
;~                          "-->ActionY:" & @TAB & DllStructGetData($tInfo, "ActionY") & @LF & _
;~                          "-->Param:" & @TAB & DllStructGetData($tInfo, "Param"))
;~                  ; No return value
;~              Case $LVN_ITEMACTIVATE ; Sent by a list-view control when the user activates an item
;~                  $tInfo = DllStructCreate($tagNMITEMACTIVATE, $ilParam)
;~                  _DebugPrint("$LVN_ITEMACTIVATE" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode & @LF & _
;~                          "-->Index:" & @TAB & DllStructGetData($tInfo, "Index") & @LF & _
;~                          "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                          "-->NewState:" & @TAB & DllStructGetData($tInfo, "NewState") & @LF & _
;~                          "-->OldState:" & @TAB & DllStructGetData($tInfo, "OldState") & @LF & _
;~                          "-->Changed:" & @TAB & DllStructGetData($tInfo, "Changed") & @LF & _
;~                          "-->ActionX:" & @TAB & DllStructGetData($tInfo, "ActionX") & @LF & _
;~                          "-->ActionY:" & @TAB & DllStructGetData($tInfo, "ActionY") & @LF & _
;~                          "-->lParam:" & @TAB & DllStructGetData($tInfo, "lParam") & @LF & _
;~                          "-->KeyFlags:" & @TAB & DllStructGetData($tInfo, "KeyFlags"))
;~                  Return 0
;~              Case $LVN_ITEMCHANGED ; An item has changed
;~                  $tInfo = DllStructCreate($tagNMLISTVIEW, $ilParam)
;~                  _DebugPrint("$LVN_ITEMCHANGED" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode & @LF & _
;~                          "-->Item:" & @TAB & DllStructGetData($tInfo, "Item") & @LF & _
;~                          "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                          "-->NewState:" & @TAB & DllStructGetData($tInfo, "NewState") & @LF & _
;~                          "-->OldState:" & @TAB & DllStructGetData($tInfo, "OldState") & @LF & _
;~                          "-->Changed:" & @TAB & DllStructGetData($tInfo, "Changed") & @LF & _
;~                          "-->ActionX:" & @TAB & DllStructGetData($tInfo, "ActionX") & @LF & _
;~                          "-->ActionY:" & @TAB & DllStructGetData($tInfo, "ActionY") & @LF & _
;~                          "-->Param:" & @TAB & DllStructGetData($tInfo, "Param"))
;~                  ; No return value
;~              Case $LVN_ITEMCHANGING ; An item is changing
;~                  $tInfo = DllStructCreate($tagNMLISTVIEW, $ilParam)
;~                  _DebugPrint("$LVN_ITEMCHANGING" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode & @LF & _
;~                          "-->Item:" & @TAB & DllStructGetData($tInfo, "Item") & @LF & _
;~                          "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                          "-->NewState:" & @TAB & DllStructGetData($tInfo, "NewState") & @LF & _
;~                          "-->OldState:" & @TAB & DllStructGetData($tInfo, "OldState") & @LF & _
;~                          "-->Changed:" & @TAB & DllStructGetData($tInfo, "Changed") & @LF & _
;~                          "-->ActionX:" & @TAB & DllStructGetData($tInfo, "ActionX") & @LF & _
;~                          "-->ActionY:" & @TAB & DllStructGetData($tInfo, "ActionY") & @LF & _
;~                          "-->Param:" & @TAB & DllStructGetData($tInfo, "Param"))
;~                  Return True ; prevent the change
;~                  ;Return False ; allow the change
;~                 Case $LVN_KEYDOWN ; A key has been pressed
;~                     $tInfo = DllStructCreate($tagNMLVKEYDOWN, $ilParam)
;~                     _DebugPrint("$LVN_KEYDOWN" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                             "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                             "-->Code:" & @TAB & $iCode & @LF & _
;~                             "-->VKey:" & @TAB & DllStructGetData($tInfo, "VKey") & @LF & _
;~                             "-->Flags:" & @TAB & DllStructGetData($tInfo, "Flags"))
                    ; No return value
;~              Case $LVN_MARQUEEBEGIN ; A bounding box (marquee) selection has begun
;~                  _DebugPrint("$LVN_MARQUEEBEGIN" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode)
;~                  Return 0 ; accept the message
;~                  ;Return 1 ; quit the bounding box selection
;~              Case $LVN_SETDISPINFO ; Update the information it maintains for an item
;~                  $tInfo = DllStructCreate($tagNMLVDISPINFO, $ilParam)
;~                  $tBuffer = DllStructCreate("char Text[" & DllStructGetData($tInfo, "TextMax") & "]", DllStructGetData($tInfo, "Text"))
;~                  _DebugPrint("$LVN_SETDISPINFO" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode & @LF & _
;~                          "-->Mask:" & @TAB & DllStructGetData($tInfo, "Mask") & @LF & _
;~                          "-->Item:" & @TAB & DllStructGetData($tInfo, "Item") & @LF & _
;~                          "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                          "-->State:" & @TAB & DllStructGetData($tInfo, "State") & @LF & _
;~                          "-->StateMask:" & @TAB & DllStructGetData($tInfo, "StateMask") & @LF & _
;~                          "-->Text:" & @TAB & DllStructGetData($tBuffer, "Text") & @LF & _
;~                          "-->TextMax:" & @TAB & DllStructGetData($tInfo, "TextMax") & @LF & _
;~                          "-->Image:" & @TAB & DllStructGetData($tInfo, "Image") & @LF & _
;~                          "-->Param:" & @TAB & DllStructGetData($tInfo, "Param") & @LF & _
;~                          "-->Indent:" & @TAB & DllStructGetData($tInfo, "Indent") & @LF & _
;~                          "-->GroupID:" & @TAB & DllStructGetData($tInfo, "GroupID") & @LF & _
;~                          "-->Columns:" & @TAB & DllStructGetData($tInfo, "Columns") & @LF & _
;~                          "-->pColumns:" & @TAB & DllStructGetData($tInfo, "pColumns"))
;~                  ; No return value
                Case $NM_CLICK ; Sent by a list-view control when the user clicks an item with the left mouse button
                    $tInfo = DllStructCreate($tagNMITEMACTIVATE, $ilParam)
					$gListViewItemSelected = DllStructGetData($tInfo, "Index")
					GUICtrlSetData($Input_String, _GUICtrlListView_GetItemText($ListView_Strings, $gListViewItemSelected))
;~                     _DebugPrint("$NM_CLICK" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                             "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                             "-->Code:" & @TAB & $iCode & @LF & _
;~                             "-->Index:" & @TAB & DllStructGetData($tInfo, "Index") & @LF & _
;~                             "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                             "-->NewState:" & @TAB & DllStructGetData($tInfo, "NewState") & @LF & _
;~                             "-->OldState:" & @TAB & DllStructGetData($tInfo, "OldState") & @LF & _
;~                             "-->Changed:" & @TAB & DllStructGetData($tInfo, "Changed") & @LF & _
;~                             "-->ActionX:" & @TAB & DllStructGetData($tInfo, "ActionX") & @LF & _
;~                             "-->ActionY:" & @TAB & DllStructGetData($tInfo, "ActionY") & @LF & _
;~                             "-->lParam:" & @TAB & DllStructGetData($tInfo, "lParam") & @LF & _
;~                             "-->KeyFlags:" & @TAB & DllStructGetData($tInfo, "KeyFlags"))
                    ; No return value
;~                 Case $NM_DBLCLK ; Sent by a list-view control when the user double-clicks an item with the left mouse button
;~                     $tInfo = DllStructCreate($tagNMITEMACTIVATE, $ilParam)
;~                     _DebugPrint("$NM_DBLCLK" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                             "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                             "-->Code:" & @TAB & $iCode & @LF & _
;~                             "-->Index:" & @TAB & DllStructGetData($tInfo, "Index") & @LF & _
;~                             "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                             "-->NewState:" & @TAB & DllStructGetData($tInfo, "NewState") & @LF & _
;~                             "-->OldState:" & @TAB & DllStructGetData($tInfo, "OldState") & @LF & _
;~                             "-->Changed:" & @TAB & DllStructGetData($tInfo, "Changed") & @LF & _
;~                             "-->ActionX:" & @TAB & DllStructGetData($tInfo, "ActionX") & @LF & _
;~                             "-->ActionY:" & @TAB & DllStructGetData($tInfo, "ActionY") & @LF & _
;~                             "-->lParam:" & @TAB & DllStructGetData($tInfo, "lParam") & @LF & _
;~                             "-->KeyFlags:" & @TAB & DllStructGetData($tInfo, "KeyFlags"))
                    ; No return value
;~              Case $NM_HOVER ; Sent by a list-view control when the mouse hovers over an item
;~                  _DebugPrint("$NM_HOVER" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                          "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                          "-->Code:" & @TAB & $iCode)
;~                  Return 0 ; process the hover normally
;~                  ;Return 1 ; prevent the hover from being processed
;~                 Case $NM_KILLFOCUS ; The control has lost the input focus
;~                     _DebugPrint("$NM_KILLFOCUS" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                             "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                             "-->Code:" & @TAB & $iCode)
;~                     ; No return value
;~                 Case $NM_RCLICK ; Sent by a list-view control when the user clicks an item with the right mouse button
;~                     $tInfo = DllStructCreate($tagNMITEMACTIVATE, $ilParam)
;~                     _DebugPrint("$NM_RCLICK" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                             "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                             "-->Code:" & @TAB & $iCode & @LF & _
;~                             "-->Index:" & @TAB & DllStructGetData($tInfo, "Index") & @LF & _
;~                             "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                             "-->NewState:" & @TAB & DllStructGetData($tInfo, "NewState") & @LF & _
;~                             "-->OldState:" & @TAB & DllStructGetData($tInfo, "OldState") & @LF & _
;~                             "-->Changed:" & @TAB & DllStructGetData($tInfo, "Changed") & @LF & _
;~                             "-->ActionX:" & @TAB & DllStructGetData($tInfo, "ActionX") & @LF & _
;~                             "-->ActionY:" & @TAB & DllStructGetData($tInfo, "ActionY") & @LF & _
;~                             "-->lParam:" & @TAB & DllStructGetData($tInfo, "lParam") & @LF & _
;~                             "-->KeyFlags:" & @TAB & DllStructGetData($tInfo, "KeyFlags"))
;~                     ;Return 1 ; not to allow the default processing
;~                     Return 0 ; allow the default processing
;~                 Case $NM_RDBLCLK ; Sent by a list-view control when the user double-clicks an item with the right mouse button
;~                     $tInfo = DllStructCreate($tagNMITEMACTIVATE, $ilParam)
;~                     _DebugPrint("$NM_RDBLCLK" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                             "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                             "-->Code:" & @TAB & $iCode & @LF & _
;~                             "-->Index:" & @TAB & DllStructGetData($tInfo, "Index") & @LF & _
;~                             "-->SubItem:" & @TAB & DllStructGetData($tInfo, "SubItem") & @LF & _
;~                             "-->NewState:" & @TAB & DllStructGetData($tInfo, "NewState") & @LF & _
;~                             "-->OldState:" & @TAB & DllStructGetData($tInfo, "OldState") & @LF & _
;~                             "-->Changed:" & @TAB & DllStructGetData($tInfo, "Changed") & @LF & _
;~                             "-->ActionX:" & @TAB & DllStructGetData($tInfo, "ActionX") & @LF & _
;~                             "-->ActionY:" & @TAB & DllStructGetData($tInfo, "ActionY") & @LF & _
;~                             "-->lParam:" & @TAB & DllStructGetData($tInfo, "lParam") & @LF & _
;~                             "-->KeyFlags:" & @TAB & DllStructGetData($tInfo, "KeyFlags"))
;~                     ; No return value
;~                 Case $NM_RETURN ; The control has the input focus and that the user has pressed the ENTER key
;~                     _DebugPrint("$NM_RETURN" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                             "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                             "-->Code:" & @TAB & $iCode)
;~                     ; No return value
;~                 Case $NM_SETFOCUS ; The control has received the input focus
;~                     _DebugPrint("$NM_SETFOCUS" & @LF & "--> hWndFrom:" & @TAB & $hWndFrom & @LF & _
;~                             "-->IDFrom:" & @TAB & $iIDFrom & @LF & _
;~                             "-->Code:" & @TAB & $iCode)
;~                     ; No return value
            EndSwitch
    EndSwitch
    Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_NOTIFY

Func _DebugPrint($s_text, $line = @ScriptLineNumber)
    ConsoleWrite( _
            "!===========================================================" & @LF & _
            "+======================================================" & @LF & _
            "-->Line(" & StringFormat("%04d", $line) & "):" & @TAB & $s_text & @LF & _
            "+======================================================" & @LF)
EndFunc   ;==>_DebugPrint

; #FUNCTION# ====================================================================================================================
; Name ..........: _CheckForStringMarker
; Description ...: checks if apostrophe or double quote is the first string marker in that line
; Syntax ........: _CheckForStringMarker($lStringToTest)
; Parameters ....: $lStringToTest       - An unknown value.
; Return values .: empty, if neither apostrophe nor double quote was found
;					char which was found first
; Author ........: Torsten Feld
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _CheckForStringMarker($lStringToTest)

	local $lStringLength = StringLen($lStringToTest) ; get length of string

	local $lPositionApostropheFound = StringInStr($lStringToTest, "'") ; search for first occurence of apostrophe
	if $lPositionApostropheFound = 0 then $lPositionApostropheFound = $lStringLength + 1 ; if apostrophe not found, set occurence to string lenght +1

	local $lPositionQuoteFound = StringInStr($lStringToTest, '"') ; search for first occurence of double quote
	if $lPositionQuoteFound = 0 then $lPositionQuoteFound = $lStringLength + 1 ; if double quote not found, set occurence to string lenght +1

	Select
		case $lPositionApostropheFound = $lPositionQuoteFound ; if neither apostrophe nor double quote was found
			Return "" ; return empty string
		case $lPositionApostropheFound > $lPositionQuoteFound ; if double quote occurs earlier than apostrophe
			Return '"' ; return double quote
		case $lPositionApostropheFound < $lPositionQuoteFound ; if apostrophe occurs earlier than double quote
			Return "'" ; return apostrophe
		case Else ; if something weird happend
			Return "" ; return empty string
	EndSelect

EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GetFileFromUser
; Description ...: Asks user for au3 file which is stored to $gFileToTransform
; Syntax ........: _GetFileFromUser()
; Parameters ....:
; Return values .: None
; Author ........: Torsten Feld
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _GetFileFromUser()

	$gFileToTransform = FileOpenDialog($gMsgBoxTitle, "", "AutoIT Script (*.au3)", 3) ; ask for au3 file
	if @error Then ; if error occurs in FileOpenDialog
		_WriteDebug("ERR ;_GetFileFromUser;FileOpenDialog failed with error: " & @error & " - exiting") ; write debug entry
		Exit 1 ; exit with code 1
	EndIf

	$gFileToTransform = @ScriptDir & "\testfile.au3"

	local $szDrive, $szDir, $szFName, $szExt
	_PathSplit($gFileToTransform, $szDrive, $szDir, $szFName, $szExt)
	$gFileIniWithStrings = $szDrive & $szDir & $szFName & "_StringTable.ini"

EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _ReadAu3FileToArray
; Description ...: reads lines of $gFileToTransform to $gaListofFileLines
; Syntax ........: _ReadAu3FileToArray()
; Parameters ....:
; Return values .: None
; Author ........: Torsten Feld
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _ReadAu3FileToArray()

	_WriteDebug("INFO;_ReadAu3FileToArray;_ReadAu3FileToArray started")

	_FileReadToArray($gFileToTransform, $gaListofFileLines) ; read all lines of file to $gaListofFileLines
	if @error Then ; if error in _FileReadToArray occurs
		_WriteDebug("ERR ;_ReadAu3FileToArray;_FileReadToArray returned error: " & @error & " - exiting") ; write debug line
		Exit 2 ; exit with code 2
	EndIf

	_WriteDebug("INFO;_ReadAu3FileToArray;_ReadAu3FileToArray ended")

EndFunc

; #FUNCTION# =========================================================================================================
; Name...........: _GUICtrlListView_CreateArray()
; Description ...: Creates a 2-dimensional array from a lisview.
; Syntax.........: _GUICtrlListView_CreateArray($hListView, [$sDelimeter = "|"])
; Parameters ....: $hListView - Handle of the ListView.
;                  [Optional] $sDelimeter - One or more characters to use as delimiters (case sensitive). Default = "|"
; Requirement(s).: v3.2.12.1 or higher & GUIListView.au3.
; Return values .: Success - The array returned is two-dimensional and is made up as follows:
;                                $aArray[0][0] = Number of rows
;                                $aArray[0][1] = Number of columns
;                                $aArray[0][3] = Delimited string of the column name(s) e.g. Column 1|Column 2|Column 3|Column nth
;                                $aArray[1][0] = 1st row, 1st column
;                                $aArray[1][1] = 1st row, 2nd column
;                                $aArray[n][0] = nth row, 1st column
;                                $aArray[n][1] = nth row, 2nd column
;                                $aArray[n][1] = nth row, 3rd column
;                  Failure - Returns array with @error = 1 if the number of rows is equal to 0
; Author ........: guinness
; Example........; Yes
;=====================================================================================================================
Func _GUICtrlListView_CreateArray($hListView, $sDelimeter = "|")
    Local $aColumns, $iDim = 0, $iError = 0, $sIndex, $sSubItem
    Local $iColumnCount = _GUICtrlListView_GetColumnCount($hListView)
    Local $iItemCount = _GUICtrlListView_GetItemCount($hListView)
    If $iColumnCount < 3 Then
        $iDim = 3 - $iColumnCount
    EndIf
    Local $aReturn[$iItemCount + 1][$iColumnCount + $iDim] = [[$iItemCount, $iColumnCount, ""]]

    For $A = 0 To $iColumnCount - 1
        $aColumns = _GUICtrlListView_GetColumn($hListView, $A)
        If $A = $iColumnCount - 1 Then
            $sDelimeter = ""
        EndIf
        $aReturn[0][2] &= $aColumns[5] & $sDelimeter
    Next

    For $A = 0 To $iItemCount - 1
        $sIndex = _GUICtrlListView_GetItemText($hListView, $A)
        $aReturn[$A + 1][0] = $sIndex
        If $iColumnCount > 0 Then
            For $B = 1 To $iColumnCount - 1
                $sSubItem = _GUICtrlListView_GetItemText($hListView, $A, $B)
                $aReturn[$A + 1][$B] = $sSubItem
            Next
        EndIf
    Next
    If $aReturn[0][0] = 0 Then
        $iError = 1
    EndIf
    Return SetError($iError, 0, $aReturn)
EndFunc   ;==>_GUICtrlListView_CreateArray

Func _Array2DAdd(ByRef $avArray, $sValue = '')
;~ 	Return 			Succes -1
;~ 	Failure			0 and set @error
;~ 	@error = 1		given array is not array
;~ 	@error = 2		given parts of Element too less/much

	If (Not IsArray($avArray)) Then
		SetError(1)
		Return 0
	EndIf
	Local $UBound2nd = UBound($avArray, 2)
	If @error = 2 Then
		ReDim $avArray[UBound($avArray) + 1]
		$avArray[UBound($avArray) - 1] = $sValue
	Else
		Local $arValue
		ReDim $avArray[UBound($avArray) + 1][$UBound2nd]
		If $sValue = '' Then
			For $i = 0 To $UBound2nd - 2
				$sValue &= '|'
			Next
		EndIf
		$arValue = StringSplit($sValue, '|')
		If $arValue[0] <> $UBound2nd Then
			SetError(2)
			Return 0
		EndIf
		For $i = 0 To $UBound2nd - 1
			$avArray[UBound($avArray) - 1][$i] = $arValue[$i + 1]
		Next
	EndIf
	Return -1
EndFunc   ;==>_Array2DAdd

Func _WriteDebug($lParam) ; $lType, $lFunc, $lString) ; creates debuglog for analyzing problems
	Local $lArray[4]
	Local $lResult

;~ 	$lArray[0] bleibt leer
;~ 	$lArray[1] = "Type: "
;~ 	$lArray[2] = "Func: "
;~ 	$lArray[3] = "Desc: "

	Local $lArrayTemp = StringSplit($lParam, ";")
	If @error Then
		Dim $lArrayTemp[4]
;~ 		$lArrayTemp[0] bleibt leer
		$lArrayTemp[1] = "ERR "
		$lArrayTemp[2] = "_WriteDebug"
		$lArrayTemp[3] = "StringSplit failed"
	EndIf

	For $i = 1 To $lArrayTemp[0]
		If $i > 1 Then $lResult = $lResult & @CRLF
		$lResult = $lResult & $lArray[$i] & $lArrayTemp[$i]
	Next

	FileWriteLine($gDbgFile, @MDAY & @MON & @YEAR & " " & @HOUR & ":" & @MIN & ":" & @SEC & "." & @MSEC & " - " & $lArrayTemp[1] & " - " & $lArrayTemp[2] & " - " & $lArrayTemp[3])
;~ 	FileWriteLine($gDbgFile, @HOUR & ":" & @MIN & ":" & @SEC & "." & @MSEC & " - " & $lType & " - " & $lFunc & " - " & $lString)
EndFunc   ;==>_WriteDebug
