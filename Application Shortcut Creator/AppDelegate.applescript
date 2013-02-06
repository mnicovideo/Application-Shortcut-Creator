--
--  AppDelegate.applescript
--  Application Shortcut Creator
--
--  Created by mii on 2013/02/04.
--  Copyright (c) 2013 mii. All rights reserved.
--

script GenericScript
	property parent : AppleScript
	
	on make
		set a_class to me
		script Instance
            property parent : a_class
        end script
    end make

    on isExistItem_(thePosixPath)
        try
            set theFilePath to thePosixPath as POSIX file
            set theAliasPath to theFilePath as alias
            return true
        on error
            return false
        end try
    end isExistItem_

    on isNotExistItem_(thePosixPath)
        return not isExistItem_(thePosixPath)
    end isNotExistItem_

    on pathRemoveBackslash_(aData)
        if last character of aData = "/" then
            set cn to the (length of aData) - 1
            return characters 1 thru cn of aData as string
        end if
        return aData
    end pathRemoveBackslash_

    on pathToTemporary_()
        return POSIX path of (path to temporary items from user domain)
    end pathToTemporary_

    on pathToLibrary_()
        return POSIX path of (path to library folder from user domain)
    end pathToLibrary_

    on getLastLayerOfDirData_(aData)
        set aColon to ":" as Unicode text
        copy aData to bData
        if bData ends with ":" then
            set bData to text 1 thru -2 of bData
        end if
        set aLen to length of bData
        set rData to reverse of (characters of bData)
        set rData to rData as string
        set dPos to offset of aColon in rData
        set resData to text (aLen - dPos + 2) thru -1 of bData
        return resData
    end getLastLayerOfDirData_

    script RecordUtility
        on keyValue_(a_record, a_key)
            run script "
            on value_of(obj)
                obj's |" & a_key & "|
            end
            me"
            result's value_of(a_record)
        end keyValue_
        on setKeyValue_(a_record, a_key, a_value)
            run script "
            on set_value(obj, v)
                try
                    set obj's |" & a_key & "| to v
                    obj
                    on error number -10006
                    obj & {|" & a_key & "|:v}
                end try
            end
            me"
            result's set_value(a_record, a_value)
        end setKeyValue_
        on recordFromKeyList_(keys, val)
            set rec to {}
            repeat with i in keys
                set rec to setKeyValue_(rec, i, val)
            end repeat
            return rec
        end recordFromKeyList_
    end script

end script

script CocoaGenericScript
	property parent : GenericScript
	
	on make
		set self to continue make
		script SubClassInstance
            property parent : self
        end script
    end make

    on recordOpenPanelProperties(aData)
        set keyList to {"title", "message", "directoryURL", "allowedFileTypes", "showsHiddenFiles", "canChooseFiles", "canChooseDirectories", "allowsMultipleSelection"}
        set rec to recordFromKeyList_(keyList, false) of my RecordUtility
        set title of rec to ""
        set message of rec to ""
        set directoryURL of rec to missing value
        set allowedFileTypes of rec to missing value
        repeat with i in keyList
            try
                set rec to my RecordUtility's setKeyValue_(rec, i, my RecordUtility's keyValue_(aData, i))
            end try
        end repeat
        return rec
    end recordOpenPanelProperties
    
    on openPanel_(aData)
        set p to recordOpenPanelProperties(aData)
        set myFile to {}
        set thePanel to current application's NSOpenPanel's openPanel()
        set productFolder to POSIX path of (path to home folder)
        set myDirectoryPath to current application's |NSURL|'s fileURLWithPath_(productFolder)
        tell thePanel
            setTitle_(p's title)
            setMessage_(p's message)
            setDirectoryURL_(p's directoryURL)
            setAllowedFileTypes_(p's allowedFileTypes)
            setShowsHiddenFiles_(p's showsHiddenFiles)
            setCanChooseFiles_(p's canChooseFiles)
            setCanChooseDirectories_(p's canChooseDirectories)
            setAllowsMultipleSelection_(p's allowsMultipleSelection)
            set returnCode to runModal()
        end tell
        set returnCode to returnCode as integer
        if returnCode = (current application's NSFileHandlingPanelOKButton) as integer then
            set theURLs to thePanel's URLs() as list
            set progressCount to count of theURLs
            repeat with i from 1 to count of theURLs
                tell item i of theURLs to set thePosixPath to |path|()
                set hfsPath to (((thePosixPath as text) as POSIX file) as text)
                set end of myFile to hfsPath
            end repeat
        else
            -- log "Cancel pressed"
            error -128
        end if
        return myFile
    end openPanel_

end script

script GoogleChromeApplicationShortcutCreator
	property parent : GenericScript
	
	on make
		set self to continue make
		script SubClassInstance
            property parent : self
            property appName : "" as string
            property appUrl : "" as string
            property appIconLocation : ""
            property appLocation : POSIX path of (path to home folder) & "Applications/" as string
            property theChrome : "/Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome" as string
            property PROFILES_DIR : POSIX path of (path to library folder from user domain) & "Application Support/GoogleChromeApplicationShortcutCreator/Profiles/"
        end script
    end make
    
    on create_()
		if isNotExistItem_(my appLocation) and my appLocation is not "/Applications/" then
			do shell script "mkdir -p '" & my appLocation & "'; touch '" & my appLocation & ".localized'"
		end if
		
		set appProfiles to my PROFILES_DIR & my appName & "/" as string
		set appResources to my appLocation & my appName & ".app/Contents/Resources/" as string
		set appMacOSofContents to my appLocation & my appName & ".app/Contents/MacOS/" as string
		set appInfo_plst to my appLocation & my appName & ".app/Contents/Info.plist" as string
		
		do shell script "mkdir -p '" & appProfiles & "'"
		do shell script "mkdir -p '" & appResources & "'"
		do shell script "mkdir -p '" & appMacOSofContents & "'"
		
		do shell script "touch '" & appMacOSofContents & my appName & "'"
		do shell script "chmod +x '" & appMacOSofContents & my appName & "'"
		do shell script "echo '#!/bin/sh\nexec " & my theChrome & "  --app=\"" & my appUrl & "\" --user-data-dir=\"" & appProfiles & "\" \"$@\"' >> '" & appMacOSofContents & my appName & "'"
		
		do shell script "touch '" & appInfo_plst & "'"
        do shell script "echo '<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" “http://www.apple.com/DTDs/PropertyList-1.0.dtd”>\n<plist version=”1.0″>\n<dict>\n<key>CFBundleExecutable</key>\n<string>" & my appName & "</string>\n<key>CFBundleIconFile</key>\n<string>icon</string>\n</dict>\n</plist>' >> '" & appInfo_plst & "'"
		
		if my appIconLocation is not "" then
			set _tmp to my pathToTemporary_()
			do shell script "sips -s format tiff '" & my appIconLocation & "' --out '" & _tmp & "icon.tiff' --resampleWidth 128"
			do shell script "tiff2icns -noLarge '" & _tmp & "icon.tiff'"
			do shell script "mv '" & _tmp & "icon.tiff' '" & appResources & "icon.tiff'"
			do shell script "mv '" & _tmp & "icon.icns' '" & appResources & "icon.icns'"
		end if
    end create_

    on openLocationFolder_()
        try
            do shell script "open '" & my appLocation & "'"
        on error
            do shell script "mkdir -p '" & my appLocation & "' && touch '" & my appLocation & ".localized' && open '" & my appLocation & "'"
        end try
    end openLocationFolder_

    on openPreferenceFolder_()
        try
            do shell script "open '" & my PROFILES_DIR & "'"
        on error
            do shell script "mkdir -p '" & my PROFILES_DIR & "' && open '" & my PROFILES_DIR & "'"
        end try
    end openPreferenceFolder_
    
end script

script AppDelegate
	property parent : class "NSObject"
	property cgs : make CocoaGenericScript
	property shortcutCreator : make GoogleChromeApplicationShortcutCreator
	property iconView : missing value
	property appName : missing value
	property appUrl : missing value
	property appLocation : missing value
	
	on chooseIcon_(sender)
		set filePath to item 1 of openPanel_({canChooseFiles:true, allowedFileTypes:{"png", "tiff", "jpg"}}) of cgs as string
		tell class "NSImage" of current application
			set iconImage to its alloc()'s initWithContentsOfFile_(POSIX path of filePath)
		end tell
		iconView's setImage_(iconImage)
		set appIconLocation of shortcutCreator to POSIX path of filePath
	end chooseIcon_
	
	on clearIcon_(sender)
		iconView's setImage_(missing value)
	end clearIcon_
	
	on chooseLocation_(sender)
		set _loc to appLocation's indexOfSelectedItem() as integer
		if _loc = 0 then
			-- nothing to do.
        else if _loc = 2 then
            set appLocation of shortcutCreator to POSIX path of (path to home folder) & "Applications/"
            changeSelectedItemOfchooseLocation_("Applications (Home Folder) ")
        else if _loc = 3 then
            set appLocation of shortcutCreator to POSIX path of (path to desktop)
            changeSelectedItemOfchooseLocation_("Desktop ")
        else
            try
                set filePathItem to item 1 of openPanel_({canChooseDirectories:true}) of cgs
            on error
                appLocation's selectItemAtIndex_(0)
                return
            end try
            set filePath to POSIX path of filePathItem as string
            set appLocation of shortcutCreator to filePath & "/"
            changeSelectedItemOfchooseLocation_(getLastLayerOfDirData_(filePathItem) of shortcutCreator)
        end if
	end chooseLocation_
	
	on changeSelectedItemOfchooseLocation_(title)
		appLocation's removeItemAtIndex_(0)
		appLocation's insertItemWithTitle_atIndex_(title, 0)
		appLocation's selectItemAtIndex_(0)
	end changeSelectedItemOfchooseLocation_
	
	on createShortcut_(sender)
        if appName's stringValue() as string is "" then
            display alert "Enter Application's Name" as warning
            return
        end if
        if appUrl's stringValue() as string is "" then
            display alert "Enter Application's URL" as warning
            return
        end if
        set shortcutCreator's appName to appName's stringValue() as string
        set shortcutCreator's appUrl to appUrl's stringValue() as string
        create_() of shortcutCreator
	end createShortcut_
	
	on openLocationFolder_(sender)
        openLocationFolder_() of shortcutCreator
	end openLocationFolder_
	
	on openPreferenceFolder_(sender)
        openPreferenceFolder_() of shortcutCreator
	end openPreferenceFolder_
	
	on applicationWillFinishLaunching_(aNotification)
		-- Insert code here to initialize your application before any files are opened
	end applicationWillFinishLaunching_
	
	on applicationShouldTerminate_(sender)
		-- Insert code here to do any housekeeping before your application quits 
		return current application's NSTerminateNow
	end applicationShouldTerminate_
	
	on applicationShouldTerminateAfterLastWindowClosed_(sender)
		return current application's NSTerminateNow
	end applicationShouldTerminateAfterLastWindowClosed_
	
end script


