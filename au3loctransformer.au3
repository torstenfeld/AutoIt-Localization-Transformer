

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

	Global $gMsgBoxTitle = "Au3 Localization Transformer"

	Global $gFileToTransform ; au3 file incl. path
	Global $gFileToWriteOutput ; copy of au3 file with exchanged strings

	Global $gaListOfStrings[1] ; list of strings found
	Global $gaListofFileLines ; stores the lines of $gFileToTransform

#EndRegion

#Region ### main

	_Main()

#EndRegion

Func _Main()

;~ 	_GetFileFromUser()
	$gFileToTransform = @ScriptDir & "\testfile.au3"

	_ReadAu3FileToArray()
;~ 	_ArrayDisplay($gaListofFileLines, "$gaListofFileLines")
	_GetStringsFromArray()
	_WriteStringToLocalizationIni()

EndFunc

Func _WriteStringToLocalizationIni()

	_WriteDebug("INFO;_WriteStringToLocalizationIni;_WriteStringToLocalizationIni started")

	for $i = 0 to UBound($gaListOfStrings)-1
		IniWrite($gFileIniWithStrings, "0000", "IDS_" & $i, $gaListOfStrings[$i])
	Next

	_WriteDebug("INFO;_WriteStringToLocalizationIni;_WriteStringToLocalizationIni ended")
EndFunc

Func _GetStringsFromArray()

	local $laStringsLine
	local $lStringMarker ; apostroph or double quote

	for $i = 1 to $gaListofFileLines[0]
		if StringInStr($gaListofFileLines[$i], '"') = 0 then ContinueLoop

		$lStringMarker = _CheckForStringMarker($gaListofFileLines[$i])

		Select
			case StringInStr($gaListofFileLines[$i], "MsgBox(")
			case StringInStr($gaListofFileLines[$i], "guictrlbutton(")
			case Else
				ContinueLoop
		EndSelect

		$laStringsLine = _StringBetween($gaListofFileLines[$i], $lStringMarker, $lStringMarker)
		if @error Then
			_WriteDebug("WARN;_GetStringsFromArray;_StringBetween returned with error: " & @error & " on string '" & StringReplace($gaListofFileLines[$i], ";", "") & "'")
			ContinueLoop
		EndIf

		for $j = 0 to UBound($laStringsLine)-1
			_ArrayAdd($gaListOfStrings, $laStringsLine[$j])
		Next
	Next
	_ArrayDelete($gaListOfStrings, 0) ; delete 0-index
;~ 	_ArrayDisplay($gaListOfStrings, "$gaListOfStrings")

EndFunc

Func _GuiListOfStrings()

	_WriteDebug("INFO;_GuiListOfStrings;_GuiListOfStrings started")

	#Region ### START Koda GUI section ### Form=
	$Form_ListStrings = GUICreate("Form1", 615, 377, 192, 124)
	$ListView_Strings = GUICtrlCreateListView("", 8, 64, 601, 233)
	GUICtrlSendMsg(-1, $LVM_SETCOLUMNWIDTH, 0, 50)
	$Label_Desc = GUICtrlCreateLabel("blablabla text", 8, 16, 66, 17)
	$Input_String = GUICtrlCreateInput("", 8, 312, 249, 21)
	$Button_Modify = GUICtrlCreateButton("Modify", 264, 312, 75, 25)
	$Button_Close = GUICtrlCreateButton("Close", 8, 344, 603, 25)
	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE, $Button_Close
				GUIDelete($Form_ListStrings)
				_WriteDebug("INFO;_GuiListOfStrings;$Form_ListStrings deleted")
				ExitLoop
			case $Button_Modify

		EndSwitch
	WEnd


	_WriteDebug("INFO;_GuiListOfStrings;_GuiListOfStrings ended")

EndFunc

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
