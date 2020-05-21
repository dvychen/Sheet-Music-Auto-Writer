#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

currentBarBeats := 0 ; Global variable

controlOctave(currNote, currOctave, prevNote, prevOctave)
{
	;; Because the scientific pitch notation changes octave at every C and not A, I will manually 'move' A and B to be after G
	currNoteVal := Asc(currNote)
	prevNoteVal := Asc(prevNote)
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

controlAccidental(accidental)
{
	Switch accidental
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

;; enterNote is going to press the keys to enter the note into Noteflight AND return a bool value for whether or not the note entered was the last note in the bar
enterNote(currentNote, currentOctave, accidental, currentNoteLength, currentDotted, previousNote, previousOctave, previousNoteLength, previousDotted, timeSigTop, timeSigBottom)
{
	;; Determine if the current note is the last note in the bar
	newBeatAddition := 1 / currentNoteLength
	if (currentDotted == 1)
		newBeatAddition *= 1.5
	global currentBarBeats ; reference the global variable
	currentBarBeats += newBeatAddition
	isLastNote := (currentBarBeats == (timeSigTop / timeSigBottom)) ; The current note was the last note in the bar
	;; Determine Noteflight's expected note length for the note
	if (!isLastNote)
	{
		previousNoteLengthValue := 1 / previousNoteLength
		if (previousDotted == 1)
			previousNoteLengthValue *= 1.5
		if (currentBarBeats - newBeatAddition + previousNoteLengthValue > (timeSigTop / timeSigBottom))
		{
			previousNoteLength := timeSigBottom
			previousDotted := 0
			;; MsgBox % "currentBarBeats: " . currentBarBeats . " newBeatAddition: " . newBeatAddition . " previousNoteLengthValue: " . previousNoteLengthValue
		}
	}
	;; Letter pitch
	Send % currentNote
	;; Octave
	controlOctave(currentNote, currentOctave, previousNote, previousOctave)
	;; Accidental
	controlAccidental(accidental)
	;; Base Note Length & Dotted Note Length
	if !(isLastNote && currentNoteLength > previousNoteLength && currentDotted != 1) ; No need to control note length if it's the last note
	{
		controlBaseNoteLength(currentNoteLength, previousNoteLength)
		if (currentDotted != previousDotted)
			Send, .
	}
	;; Diagnostic: MsgBox % "isLastNote: " . isLastNote . " currentNoteLength: " . currentNoteLength . " previousNoteLength: " . previousNoteLength . " currentDotted: " . currentDotted " because currentBarBeats: " . currentBarBeats . " and (timeSigTop / timeSigBottom): " . (timeSigTop / timeSigBottom)
	return isLastNote
}

;; "Main function"
^j::
;; These defaults are based on Noteflight defaults
previousNote := "g"
previousOctave := 4
previousNoteLength := 4
previousDotted := 0

timeSigTop := 4
timeSigBottom := 4
global currentBarBeats
currentBarBeats := 0
isLastNote := false

;;TODO: Add a isNote variable to detect time signature change OR note entry ?

Loop, Read, SMAW_FINAL_note_sample_v1.csv
{
	;; A_LoopReadLine is a variable containing contents of current line
	;; A_Index is a variable containing the line number
	timeSigChange := false
	Loop, Parse, A_LoopReadLine, CSV
	{
		;; A_LoopField is a variable containing the contents of the field
		;; A_Index is a variable containing the field number
		Switch A_Index
		{
			Case 1: ; Letter pitch
				if (Asc(A_LoopField) > 48) && (Asc(A_LoopField) <= 57) ; If the input is a number, then it will indicate a time signature change
				{
					timeSigChange := true
					timeSigTop := A_LoopField
				}
				else
					currentNote := A_LoopField
			Case 2: ; Octave
				if (timeSigChange)
					timeSigBottom := A_LoopField
				else
					currentOctave := A_LoopField
			Case 3: ; Accidental
				accidental := A_LoopField
			Case 4: ; Base note length
				currentNoteLength := A_LoopField
			Case 5: ; Dotted note length
				currentDotted := A_LoopField
		}
	}
	if (!timeSigChange)
	{
		isLastNote := enterNote(currentNote, currentOctave, accidental, currentNoteLength, currentDotted, previousNote, previousOctave, previousNoteLength, previousDotted, timeSigTop, timeSigBottom)
		if (isLastNote)
			currentBarBeats := 0
		previousNote := currentNote
		previousOctave := currentOctave
		previousNoteLength := currentNoteLength
		previousDotted := currentDotted
	}
	else
	{
		MsgBox % "Time signature change to: " . timeSigTop . "/" . timeSigBottom . " has been detected. Please manually change the time signature in Noteflight now."
		; Whenever the time signature is changed in Noteflight, the default note duration reverted to exactly one beat
		previousNoteLength := timeSigBottom
		previousDotted := 0
	}
}
return
