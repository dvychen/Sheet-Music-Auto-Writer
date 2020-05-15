#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

controlOctave(currNote, currOctave, prevNote, prevOctave)
{
	;; Because the scientific pitch notation changes octave at every C and not A, I will have to manually 'move' A and B to be after G
	currNoteVal := Asc(currNote)
	prevNoteVal := Asc(prevNote)
	;; see drawing square brackets
	if (currNote == "a") || (currNote == "b")
		currNoteVal += 7
	if (prevNote == "a") || (prevNote == "b")
		prevNoteVal += 7
	;; To determine which octave of the given letter is the closest to the previous music note
	noteValDiff := currNoteVal - prevNoteVal
	if (noteValDiff > 3)
		expectedOctave := prevOctave - 1
	else if (noteValDiff < -3)
		expectedOctave := prevOctave + 1
	else
		expectedOctave := prevOctave
	;; Octave correction
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

Loop, Read, SMAW_note_test_v1.csv
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
