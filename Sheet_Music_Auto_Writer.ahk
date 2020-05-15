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

controlBaseNoteLength(currNoteLength, prevNoteLength)
{
	expectedNoteLength := prevNoteLength
	while (expectedNoteLength < currNoteLength) ; The greater the number, the shorter the note length
	{
		Send, [
		expectedNoteLength *= 2
	}
	while (expectedNoteLength > currNoteLength)
	{
		Send, ]
		expectedNoteLength := expectedNoteLength // 2
	}
}


;; TODO: NEED TO INCOPORATE TIME SIGNATURE TO UNDERSTAND NOTEFLIGHT'S AUTO-COMPLETE NOTE LENGTH FUNCTION - WOULD HAVE TO COUNT THE BEATS IN A BAR --> CAN IMPLEMENT BASIC VERSION FOR ONLY BASE 4 --> 4/4, 3/4, 2/4, etc.


;; "Main function"
^j::
;; These defaults are based on Noteflight defaults
previousNote := "g"
previousOctave := 4
previousNoteLength := 4
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
			Case 1: ; Letter pitch
				currentNote := A_LoopField
				Send, %currentNote%
			Case 2: ; Octave
				currentOctave := A_LoopField
				controlOctave(currentNote, currentOctave, previousNote, previousOctave)
			Case 3: ; Accidental
				Switch A_LoopField
				{
					Case -2:
						Send, _
					Case -1:
						Send, -
					Case 0:
						Send, =
					Case 1:
						Send, {+}
					Case 2:
						Send, *
				}
			Case 4: ; Base note length
				currentNoteLength := A_LoopField
				controlBaseNoteLength(currentNoteLength, previousNoteLength)
			Case 5: ; Dotted note length
				currentDotted := A_LoopField
				if (currentDotted != previousDotted)
					Send, .
		}
	}
	previousNote := currentNote
	previousOctave := currentOctave
	previousNoteLength := currentNoteLength
	previousDotted := currentDotted
}
return
