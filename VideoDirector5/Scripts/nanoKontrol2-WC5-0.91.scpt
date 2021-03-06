#
# Wirecast 5 control panel script for Korg nanoKONTROL2
#
# By Richard Milewski -- richard@mozilla.com
# Rev 0.91  31 Dec 2013
# # This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
# 


# The Layer List is defined here
on layerList()
	return {"Titles", "Logos", "Cameras", "Audio", "Backgrounds"}
end layerList

# Main - Triggered by MidiPipe receiving a midi message
on runme(message)
	tell application "Finder"
		
		# The name of the Wirecast file containing the broadcast settings.
		# This file should be pre-configured with live camera shots and audio shots,
		# but nothing else.
		set Broadcast to "VideoDirector5.wcst" as text
		
		# The path to the media folder
		set ProjectFolder to folder "VideoDirector5" of folder "Documents" of home
		tell application "System Events"
			set pProjectFolder to "~/Documents/VideoDirector5/" as text
		end tell
		# We must set the POSIX path to the media folder separately because
		# Applescript lacks a way to coerce one path form into the other... 
		# and writing a handler that gets called only once seems silly.
		
		set scriptFolder to folder "Scripts" of ProjectFolder
		
		set btnLeft to 4 # Number of buttons in LEFT half of split rows
		#                  	S-buttons are split between Titles (left) and Logos (right) layers
		#                  	M-buttons are split between Cameras (left) and Audio (right) layers
		#                	R-buttons are all dedicated to the MediaPlayer layer
		
		set splitLeft to (btnLeft - 1) #Number to add to first button code to get last button code in left bank
		set splitRight to (7 - btnLeft) #Number to subtract from last button code to get first button code in right bank
		
		set L1_base to 32 #Layer 1 keys
		set L1_limit to L1_base + splitLeft
		
		set L2_limit to 39 #Layer 2 keys
		set L2_base to L2_limit - splitRight
		
		set L3_base to 48 #Layer 3 keys
		set L3_limit to L3_base + splitLeft
		
		set L4_limit to 55 #Layer 4 keys
		set L4_base to L4_limit - splitRight
		
		set L5_base to 64 #Layer 5 keys
		set L5_limit to 71
		
		set M1 to item 1 of message # Stuff the Midi message into simple variables
		set M2 to item 2 of message # to make the code below less verbose
		set M3 to item 3 of message
		
		if (M1 = 176) then
			
			#Stuff in this section runs external scripts (as yet undefined)  ##################
			
			if (M2 = 43) then # Rewind Button - Exit Sequence
				run script file "Outro.scpt" of scriptFolder as alias
				
			else if (M2 = 44) then # FFwd Button - Intro Sequence
				run script file "Intro.scpt" of scriptFolder as alias
				
				
				# Everything past here happens inside Wirecast   ########################
				
			else if (M2 = 42) then # Stop Button - Autolive toggle    
				# Note that Wirecast 5 does not update the GUI indicator (!!)
				tell application "Wirecast"
					activate
					set myDoc to last document
					if (M3 > 64) then
						set the auto live of myDoc to true
					else
						set the auto live of myDoc to false
					end if
				end tell
				
				
				# Track > Button - Open and Configure The Prototype Wirecast Document
			else if (M2 = 59) and (M3 > 100) then
				tell application "Wirecast"
					activate
					set myFile to (file Broadcast of ProjectFolder)
					open myFile as alias
					set myDoc to last document
					
					
					#This section does not seem to work - Isn't setting Layer names.
					repeat with myIndex from 1 to 5
						set myName to item myIndex of my layerList() as text
						set myLayer to layer myIndex of myDoc
						set name of myLayer to myName
					end repeat
					
					repeat with myIndex from 1 to 5
					tell application "System Events"
						set layerName to item myIndex of my layerList() as text
						set myList to POSIX path of disk items of folder (pProjectFolder & layerName & "/")
					end tell
					
					set myLayer to layer myIndex of myDoc
					repeat with aFile in myList
						if (aFile ≠ (pProjectFolder & layerName & "/.gitignore")) then
							AddShotWithMedia myLayer with posix_path aFile
						end if
					end repeat
					
				end repeat
				end tell
				
				# Track < Button - Remove Media from Current Wirecast Document
			else if (M2 = 58) and (M3 > 100) then
				tell application "Wirecast"
					activate
					set myDoc to last document
					set myLCount to count layers in myDoc
					repeat with myLayerIndex from 1 to count layers in myDoc
						set myLayer to layer myLayerIndex in myDoc
						set myLxCount to (count shots in myLayer)
						if myLxCount > 1 then
							repeat with myLayerIndex from 2 to myLxCount
								set myShot to shot 2 of myLayer
								RemoveShot myLayer with shot id of myShot
							end repeat
						end if
					end repeat
				end tell
				
				
			else if (M2 = 41) then # Play Button - Toggle Stream
				tell application "Wirecast"
					set myDoc to last document
					stop recording myDoc
					if (M3 > 64) then
						start broadcasting myDoc
					else
						stop broadcasting myDoc
					end if
				end tell
				
			else if (M2 = 45) then # Record Button - Toggle Recording
				tell application "Wirecast"
					set myDoc to last document
					stop recording myDoc
					if (M3 > 64) then
						start recording myDoc
					else
						stop recording myDoc
					end if
				end tell
				
			else if (M2 = 46) then # Cycle Button - Go (Take Shot)
				tell application "Wirecast"
					set myDoc to last document
					go myDoc
				end tell
				
				# Titles - Layer 1 
			else if (M2 ≥ L1_base) and (M2 ≤ L1_limit) and (M3 > 0) then # Preview Title
				tell application "System Events" to keystroke "T" using {command down, shift down}
				my SetShot(1, (M2 - L1_base + 1))
				
				# Logos  - Layer 2
			else if (M2 ≥ L2_base) and (M2 ≤ L2_limit) and (M3 > 0) then # Preview Logos
				tell application "System Events" to keystroke "F" using {command down, shift down}
				my SetShot(2, (M2 - L2_base + 1))
				
				# Cameras  -  Layer 3 
			else if (M2 ≥ L3_base) and (M2 ≤ L3_limit) and (M3 > 0) then # Preview Cameras
				tell application "System Events" to keystroke "N" using {command down, shift down}
				my SetShot(3, (M2 - L3_base + 1))
				
				# Audio  - Layer 4
			else if (M2 ≥ L4_base) and (M2 ≤ L4_limit) and (M3 > 0) then # Preview Cameras
				tell application "System Events" to keystroke "B" using {command down, shift down}
				my SetShot(4, (M2 - L4_base + 1))
				
				# Media Player  - Layer 5 
			else if (M2 ≥ L5_base) and (M2 ≤ L5_limit) and (M3 > 0) then # Preview Media
				tell application "System Events" to keystroke "A" using {command down, shift down}
				my SetShot(5, (M2 - L5_base + 1))
				
				# Transition Popup - Marker Buttons 
			else if (M2 = 61) or (M2 = 62) then
				tell application "Wirecast"
					set myDoc to last document
					set the active transition popup of myDoc to (M2 - 60)
				end tell
				
				# Transition Speed    
			else if (M2 = 16) or (M2 = 0) then
				set speedList to {"slowest", "slow", "normal", "fast", "fastest"}
				set mySpeed to item M3 of speedList
				tell application "Wirecast"
					set myDoc to last document
					set the transition speed of myDoc to mySpeed
				end tell
			end if
		end if
	end tell
end runme


# Handler to Set Shots
on SetShot(layerNumber, selectedShot)
	tell application "Wirecast"
		activate
		set myDoc to last document
		set myLayer to layer layerNumber of myDoc
		try #because all available slots my not be filled
			set the active shot of myLayer to shot selectedShot of myLayer
		end try
	end tell
	return
end SetShot

# Handler to do layerList position lookup
on LayerIndex(thisItem)
	repeat with i from 1 to count of my layerList()
		if item i of my layerList() is thisItem then return i
	end repeat
	return 0
end LayerIndex

