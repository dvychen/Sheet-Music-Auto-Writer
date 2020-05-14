#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

controlOctave(currNote, currOctave, prevNote, prevOctave)
{
	noteValDiff := Asc(currNote) - Asc(prevNote)
	MsgBox % Asc(currNote) . "and" . Asc(prevNote)
	if (noteValDiff > 3)
		expectedOctave := prevOctave + 1
	else if (noteValDiff < -3)
		expectedOctave := prevOctave - 1
	else
	{
		;;MsgBox, else happened
		expectedOctave := prevOctave
	}

	while (expectedOctave < currOctave)
	{
		Send, ^{Up}
		expectedOctave++
	}
	while (expectedOctave > currOctave )
	{
		Send, ^{Down}
		expectedOctave--
	}
}

;; "Main function"
^j::
;; These defaults are based on Noteflight defaults
previousNote := "g"
previousOctave := 4
previousDotted := 0

Loop, Read, C:\Users\Dan\Documents\DavStuff\CAS_Project\SMAW_note_test.csv
{
	;; A_LoopReadLine is a variable containing contents of current line
	;; A_Index is a variable containing the line number
	Loop, Parse, A_LoopReadLine, CSV
	{
		;; A_LoopField is a variable containing the contents of the field
		;; A_Index is a variable containing the field number
		Switch A_Index
		{
			Case 1:
				currentNote := A_LoopField
				Send, %currentNote%
			Case 2:
				currentOctave := A_LoopField
				controlOctave(currentNote, currentOctave, previousNote, previousOctave)
		}
	}
	previousNote := currentNote
	previousOctave := currentOctave
	;; previousDotted := currentDotted
}
return
