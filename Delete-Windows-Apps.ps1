# This script cleans out apps from the WindowsApps folder. For some reason,
# that folder accumulates dozens of old versions of Windows apps, which each
# consume hundreds of megabytes.
#
# You should use this script *after* you have uninstalled the apps you don't
# want using the official uninstallers.
#
# Simply edit the list labeled Topics below, in order to control the folders
# that are removed.
#
# Author: Jeff Booth
#
# Troubleshooting:
#
# You may see permission errors for program icons like the following:
# C:\Program Files\WindowsApps\Microsoft.ZuneMusic_11.2305.4.0_x64__8wekyb3d8bbwe\Assets\NoiseAsset_256X256_PNG.png
# You can use Process Explorer to figure out which program is still using
# the file. CalculatorApp.exe was the culprit in my experience, but you
# can't see the calculator on your screen: you'd have to open Task Manager
# or Process Explorer to see it.
#
# License: The Unlicense
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <https://unlicense.org>

# Substrings of program names to remove
# Edit this list to control what is removed.
$Topics = @(
    '3DBuilder'
    '3DViewer'
    'Disney'
    'Facebook' # this is Facebook Messenger
    'Phone'
    'Photos'
    'Skype'
    'Solitaire'
    'MSTeams'
    'Whiteboard'
    'XboxApp'
    'Zune'
    'windowscommunicationsapps'
)

# Administrators group to take ownership of the files
$Account = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'BUILTIN\Administrators'

# Gives full control of a file or directory to the administrators group.
function Give-Full-Control-To-Administrators {
    param( $ItemToFixACL )

    Write-Output ("Fixing permissions for " + $ItemToFixACL.FullName)

    $Acl = Get-Acl -Path $ItemToFixACL.FullName;

    # Administrators group takes ownership
    $Acl.SetOwner($Account);

    # Administrators group gets full control so it can delete the file
    $identity = "BUILTIN\Administrators"
    $fileSystemRights = "FullControl"
    $type = "Allow"
    $fileSystemAccessRuleArgumentList = $identity, $fileSystemRights, $type
    $fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
    $Acl.SetAccessRule($fileSystemAccessRule)

    Set-Acl -Path $ItemToFixACL.FullName -AclObject $Acl;
}

# Gives full control of a file or directory to the administrators group,
# recursing into directories *after* obtaining the full control.
function Give-Full-Control-To-Administrators-Recurse {
    param ($Item)

    Give-Full-Control-To-Administrators $Item

    if ($Item -is [System.IO.DirectoryInfo]) {
        $ItemsToFix = Get-ChildItem -Path $Item.FullName -Force;
        foreach ($ItemToFixACL in $ItemsToFix) {
            Give-Full-Control-To-Administrators-Recurse $ItemToFixACL
        }
    }
}

# Returns true if a program matches one of the topics in the global topics
# list.
function Program-Should-Be-Removed {
    param ( $ItemName )
    foreach ( $Topic in $Topics ) {
        if ($ItemName -match ".*$Topic.*") {
            Return $true
        }
    }
    Return $false
}

# Removes apps in the WindowsApps directory that match the topics in the
# global topics list.
function Remove-Windows-Apps {
    $ItemList = Get-ChildItem -Directory -Path 'C:\Program Files\WindowsApps'
    foreach ($Item in $ItemList) {
        if (Program-Should-Be-Removed $Item.Name) {
            Write-Output ("Removing " + $Item.FullName)
            Give-Full-Control-To-Administrators-Recurse $Item
            Remove-Item -Recurse -Force $Item.FullName
        }
    }
}

Remove-Windows-Apps

