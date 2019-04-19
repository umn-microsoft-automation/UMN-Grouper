#region License
    # Copyright 2017 University of Minnesota, Office of Information Technology

    # This program is free software: you can redistribute it and/or modify
    # it under the terms of the GNU General Public License as published by
    # the Free Software Foundation, either version 3 of the License, or
    # (at your option) any later version.

    # This program is distributed in the hope that it will be useful,
    # but WITHOUT ANY WARRANTY; without even the implied warranty of
    # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    # GNU General Public License for more details.

    # You should have received a copy of the GNU General Public License
    # along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
#endregion

#region New-GrouperHeader
    function New-GrouperHeader
    {
        <#
            .SYNOPSIS
                Create Header to be consumed by all other functions

            .DESCRIPTION
                Create Header to be consumed by all other functions

            .PARAMETER psCreds
                PScredential composed of your username/password to Server

            .NOTES
                Author: Travis Sobeck
                LASTEDIT: 6/20/2018

            .EXAMPLE

        #>
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory)]
            [System.Management.Automation.PSCredential]$psCreds
        )
        $auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($psCreds.UserName+':'+$psCreds.GetNetworkCredential().Password))
        return (@{"Authorization" = "Basic $auth"})
    }
#endregion

#region Get-GrouperGroup
    function Get-GrouperGroup
    {
        <#
            .SYNOPSIS
                Get Grouper Group(s)

            .DESCRIPTION
                Get Grouper Group(s)

            .PARAMETER uri
                Full path to Server plus path to API
                Example "https://<FQDN>/grouper-ws/servicesRest/json/v2_2_100"

            .PARAMETER header
                Use New-Header to get this

            .PARAMETER contentType
                Set Content Type, currently 'text/x-json;charset=UTF-8'

            .PARAMETER groupName
                Use this if you know the exact name

            .PARAMETER stemName
                Use this to get a list of groups in a specific stem.  Use Get-GrouperStem to find stem
            
            .PARAMETER subjectId
                Set this to a username to search as that user if you have access to

            .NOTES
                Author: Travis Sobeck
                LASTEDIT: 7/30/2018

            .EXAMPLE
        #>
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory)]
            [string]$uri,

            [Parameter(Mandatory)]
            [System.Collections.Hashtable]$header,

            [string]$contentType = 'text/x-json;charset=UTF-8',

            [Parameter(Mandatory,ParameterSetName='groupName')]
            [string]$groupName,

            [Parameter(Mandatory,ParameterSetName='stemName')]
            [string]$stemName,

            [string]$subjectId
        )

        Begin{}

        Process
        {
            if ($groupName)
            {
                Write-Warning "This Option has not been coded yet"
            }
            else
            {
                $uri = "$uri/groups"
                $groupName = "$stemName`:"
                $body = @{
                        WsRestFindGroupsRequest = @{
                            wsQueryFilter = @{groupName = $groupName;queryFilterType = 'FIND_BY_GROUP_NAME_APPROXIMATE'}
                        }
                } 
                if ($subjectId)
                {
                    
                    $body['WsRestFindGroupsRequest']['actAsSubjectLookup'] = @{subjectId = $subjectId};
                }
                $body = $body | ConvertTo-Json -Depth 5
                $response = Invoke-WebRequest -Uri $uri -Headers $header -Method Post -Body $body -UseBasicParsing -ContentType $contentType
                return ($response.Content | ConvertFrom-Json).WsFindGroupsResults.groupResults
            }
        }

        End{}
    }
#endregion

#region Get-GrouperGroupMembers
    function Get-GrouperGroupMembers
    {
        <#
            .SYNOPSIS
                Get List of Members in a Group

            .DESCRIPTION
                Get List of Members in a Group

            .PARAMETER uri
                Full path to Server plus path to API
                Example "https://<FQDN>/grouper-ws/servicesRest/json/v2_2_100"

            .PARAMETER header
                Use New-Header to get this

            .PARAMETER contentType
                Set Content Type, currently 'text/x-json;charset=UTF-8'

            .PARAMETER groupName
                This represents the identifier for the group, it should look like 'stemname:group'
                Example: stem1:substem:supergroup

            .NOTES
                Author: Travis Sobeck
                LASTEDIT: 7/30/2018

            .EXAMPLE
        #>
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory)]
            [string]$uri,

            [Parameter(Mandatory)]
            [System.Collections.Hashtable]$header,

            [string]$contentType = 'text/x-json;charset=UTF-8',

            [Parameter(Mandatory)]
            [string]$groupName
        )

        Begin{}

        Process
        {
            $uri = "$uri/groups"
            $body = @{
                WsRestGetMembersRequest = @{
                    subjectAttributeNames = @("description","name")
                    wsGroupLookups = @(@{groupName = $groupName})
                }
            } | ConvertTo-Json -Depth 5
            $response = Invoke-WebRequest -Uri $uri -Headers $header -Method Post -Body $body -UseBasicParsing -ContentType $contentType
            return ($response.Content | ConvertFrom-Json).WsGetMembersResults.results.wsSubjects
        }

        End{}
    }
#endregion

#region Get-GrouperPrivileges
function Get-GrouperPrivileges
{
    <#
        .SYNOPSIS
            Get Grouper Privileges

        .DESCRIPTION
            Get Grouper Privileges

        .PARAMETER uri
            Full path to Server plus path to API
            Example "https://<FQDN>/grouper-ws/servicesRest/json/v2_2_100"

        .PARAMETER header
            Use New-Header to get this

        .PARAMETER contentType
            Set Content Type, currently 'text/x-json;charset=UTF-8'

        .PARAMETER stemName
            stemName
        
        .PARAMETER subjectId
            Filter result for a specific user

        .PARAMETER actAsSubjectId
            User security context to restrict search to.  ie search as this user

        .NOTES
            Author: Travis Sobeck
            LASTEDIT: 7/30/2018

        .EXAMPLE
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$uri,

        [Parameter(Mandatory)]
        [System.Collections.Hashtable]$header,

        [string]$contentType = 'text/x-json;charset=UTF-8',

        [Parameter(Mandatory,ParameterSetName='stem')]
        [string]$stemName,

        [Parameter(Mandatory,ParameterSetName='group')]
        [string]$groupName,

        [string]$actAsSubjectId,

        [string]$subjectId
    )

    Begin{}
    Process
    {
        $uri = "$uri/grouperPrivileges"
        $body = @{
            WsRestGetGrouperPrivilegesLiteRequest = @{}
        } 
        if ($subjectId)
        {
            
            $body['WsRestGetGrouperPrivilegesLiteRequest']['actAsSubjectId'] = $subjectId
        }
        if ($actAsSubjectId)
        {
            
            $body['WsRestGetGrouperPrivilegesLiteRequest']['actAsSubjectId'] = $actAsSubjectId
        }
        if ($groupName)
        {
            
            $body['WsRestGetGrouperPrivilegesLiteRequest']['groupName'] = $groupName
        }
        if ($stemName)
        {
            
            $body['WsRestGetGrouperPrivilegesLiteRequest']['stemName'] = $stemName
        }
        
        $body = $body | ConvertTo-Json -Depth 5
        $response = Invoke-WebRequest -Uri $uri -Headers $header -Method Post -Body $body -UseBasicParsing -ContentType $contentType
        return ($response.Content | ConvertFrom-Json).WsGetGrouperPrivilegesLiteResult.privilegeResults
        if (($response.Content | ConvertFrom-Json).WsFindStemsResults.stemResults.count -gt 0)
        {
            ($response.Content | ConvertFrom-Json).WsFindStemsResults.stemResults
        }
        else {
            Write-Verbose "NO results found"
        }
    }
    End{}
}
#endregion

#region Get-GrouperStem
    function Get-GrouperStem
    {
        <#
            .SYNOPSIS
                Get Grouper Stem(s)

            .DESCRIPTION
                Get a Grouper Stem or use the -search switch to get all Grouper Stem(s) that match stem pattern
                From API docs -- find by approx name, pass the name in. stem name is required

            .PARAMETER uri
                Full path to Server plus path to API
                Example "https://<FQDN>/grouper-ws/servicesRest/json/v2_2_100"

            .PARAMETER header
                Use New-Header to get this

            .PARAMETER contentType
                Set Content Type, currently 'text/x-json;charset=UTF-8'

            .PARAMETER stemName
                stemName
            
            .PARAMETER search
                Switch to do a search.  Use with the caution, results from grouper API are not very reliable

            .PARAMETER subjectId
                Set this to a username to search as that user if you have access to

            .NOTES
                Author: Travis Sobeck
                LASTEDIT: 7/30/2018

            .EXAMPLE
        #>
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory)]
            [string]$uri,

            [Parameter(Mandatory)]
            [System.Collections.Hashtable]$header,

            [string]$contentType = 'text/x-json;charset=UTF-8',

            [Parameter(Mandatory)]
            [string]$stemName,
            
            [switch]$search,

            [string]$subjectId
        )

        Begin{}

        Process
        {
            $uri = "$uri/stems"
            $body = @{
                    WsRestFindStemsRequest = @{
                        wsStemQueryFilter = @{stemName = $stemName}
                    }
            }

            if ($search){$body['WsRestFindStemsRequest']['wsStemQueryFilter']['stemQueryFilterType'] = 'FIND_BY_STEM_NAME_APPROXIMATE'}
            else{$body['WsRestFindStemsRequest']['wsStemQueryFilter']['stemQueryFilterType'] = 'FIND_BY_STEM_NAME'}

            if ($subjectId)
            {                
                $body['WsRestFindStemsRequest']['actAsSubjectLookup'] = @{subjectId = $subjectId};
            }
            $body = $body | ConvertTo-Json -Depth 5
            $response = Invoke-WebRequest -Uri $uri -Headers $header -Method Post -Body $body -UseBasicParsing -ContentType $contentType
            if (($response.Content | ConvertFrom-Json).WsFindStemsResults.stemResults.count -gt 0)
            {
                ($response.Content | ConvertFrom-Json).WsFindStemsResults.stemResults
            }
            else {
                Write-Verbose "NO results found"
            }
        }

        End{}
    }
#endregion

#region Get-GrouperStemByParent
    function Get-GrouperStemByParent
    {
        <#
            .SYNOPSIS
                Get Grouper child Stem(s) of a parent stem

            .DESCRIPTION
                Get Grouper child Stem(s) of a parent stem

            .PARAMETER uri
                Full path to Server plus path to API
                Example "https://<FQDN>/grouper-ws/servicesRest/json/v2_2_100"

            .PARAMETER header
                Use New-Header to get this

            .PARAMETER contentType
                Set Content Type, currently 'text/x-json;charset=UTF-8'

            .PARAMETER parentStemName
                stemName of Parent
            
            .PARAMETER noRecursion
                By default the function will recursivly search for all sub-stems, use this switch to only get stems one level below the parent stem
            
            .PARAMETER subjectId
                Set this to a username to search as that user if you have access to

            .NOTES
                Author: Travis Sobeck
                LASTEDIT: 7/30/2018

            .EXAMPLE
        #>
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory)]
            [string]$uri,

            [Parameter(Mandatory)]
            [System.Collections.Hashtable]$header,

            [string]$contentType = 'text/x-json;charset=UTF-8',

            [Parameter(Mandatory)]
            [string]$parentStemName,

            [switch]$noRecursion,

            [string]$subjectId
        )

        Begin{}

        Process
        {
            $uri = "$uri/stems"
            $body = @{
                    WsRestFindStemsRequest = @{
                        wsStemQueryFilter = @{parentStemName = $parentStemName;stemQueryFilterType = 'FIND_BY_PARENT_STEM_NAME'}
                    }
            }
            if($noRecursion){$body['WsRestFindStemsRequest']['wsStemQueryFilter']["parentStemNameScope"] = 'ONE_LEVEL'}
            else{$body['WsRestFindStemsRequest']['wsStemQueryFilter']["parentStemNameScope"] = 'ALL_IN_SUBTREE'}

            if ($subjectId)
            {
                
                $body['WsRestFindStemsRequest']['actAsSubjectLookup'] = @{subjectId = $subjectId};
            }
            $body = $body | ConvertTo-Json -Depth 5
            Write-Verbose -Message $body
            $response = Invoke-WebRequest -Uri $uri -Headers $header -Method Post -Body $body -UseBasicParsing -ContentType $contentType
            if (($response.Content | ConvertFrom-Json).WsFindStemsResults.stemResults.count -gt 0)
            {
                ($response.Content | ConvertFrom-Json).WsFindStemsResults.stemResults
            }
            else {
                Write-Verbose "NO results found"
            }
        }

        End{}
    }
#endregion

#region Get-GrouperStemByUUID
function Get-GrouperStemByUUID
{
    <#
        .SYNOPSIS
            Get a Grouper Stem by its UUID

        .DESCRIPTION
            Get a Grouper Stem by its UUID

        .PARAMETER uri
            Full path to Server plus path to API
            Example "https://<FQDN>/grouper-ws/servicesRest/json/v2_2_100"

        .PARAMETER header
            Use New-Header to get this

        .PARAMETER contentType
            Set Content Type, currently 'text/x-json;charset=UTF-8'

        .PARAMETER uuid
            UUID of the stem to retrieve

        .PARAMETER subjectId
            Set this to a username to search as that user if you have access to

        .NOTES
            Author: Travis Sobeck
            LASTEDIT: 7/30/2018

        .EXAMPLE
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$uri,

        [Parameter(Mandatory)]
        [System.Collections.Hashtable]$header,

        [string]$contentType = 'text/x-json;charset=UTF-8',

        [Parameter(Mandatory)]
        [string]$uuid,

        [string]$subjectId
    )

    Begin{}

    Process
    {
        $uri = "$uri/stems"
        $body = @{
                WsRestFindStemsRequest = @{
                    wsStemQueryFilter = @{stemUuid = $uuid;stemQueryFilterType = 'FIND_BY_STEM_UUID'}
                }
        }

        if ($subjectId)
        {
            
            $body['WsRestFindStemsRequest']['actAsSubjectLookup'] = @{subjectId = $subjectId};
        }
        $body = $body | ConvertTo-Json -Depth 5
        $response = Invoke-WebRequest -Uri $uri -Headers $header -Method Post -Body $body -UseBasicParsing -ContentType $contentType
        if (($response.Content | ConvertFrom-Json).WsFindStemsResults.stemResults.count -gt 0)
        {
            ($response.Content | ConvertFrom-Json).WsFindStemsResults.stemResults
        }
        else {
            Write-Verbose "NO results found"
        }
    }

    End{}
}
#endregion

#region New-GrouperGroup
    function New-GrouperGroup
    {
        <#
            .SYNOPSIS
                Create new Group in Grouper

            .DESCRIPTION
                Create new Group in Grouper

            .PARAMETER uri
                Full path to Server plus path to API
                Example "https://<FQDN>/grouper-ws/servicesRest/json/v2_2_100"

            .PARAMETER header
                Use New-Header to get this

            .PARAMETER contentType
                Set Content Type, currently 'text/x-json;charset=UTF-8'

            .PARAMETER groupName
                This represents the identifier for the group, it should look like 'stemname:group'
                Example: stem1:substem:supergroup

            .PARAMETER description
                The description represents the the Name in the form users in the UI will see the group

            .NOTES
                Author: Travis Sobeck
                LASTEDIT: 7/30/2018

            .EXAMPLE
        #>
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory)]
            [string]$uri,

            [Parameter(Mandatory)]
            [System.Collections.Hashtable]$header,

            [string]$contentType = 'text/x-json;charset=UTF-8',

            [Parameter(Mandatory)]
            [string]$groupName,

            [Parameter(Mandatory)]
            [string]$description
        )

        Begin{}

        Process
        {
            $uri = "$uri/groups"
            $body = @{
                WsRestGroupSaveRequest = @{
                    wsGroupToSaves = @(@{wsGroup = @{description = $description;displayExtension = $description;extension = $description;name = $groupName};wsGroupLookup = @{groupName = $groupName}})
                }
            } | ConvertTo-Json -Depth 5
            ($response = Invoke-WebRequest -Uri $uri -Headers $header -Method Post -Body $body -UseBasicParsing -ContentType $contentType)
            return ($response.Content | ConvertFrom-Json).WsGroupSaveResults.results.wsGroup
        }

        End{}
    }
#endregion

#region New-GrouperGroupMember
    function New-GrouperGroupMember
    {
        <#
            .SYNOPSIS
                Add a user to a Group

            .DESCRIPTION
                Add a user to a Group

            .PARAMETER uri
                Full path to Server plus path to API
                Example "https://<FQDN>/grouper-ws/servicesRest/json/v2_2_100"

            .PARAMETER header
                Use New-Header to get this

            .PARAMETER contentType
                Set Content Type, currently 'text/x-json;charset=UTF-8'

            .PARAMETER groupName
                This represents the identifier for the group, it should look like 'stemname:group'
                Example: stem1:substem:supergroup

            .PARAMETER subjectId

            .PARAMETER subjectSourceId
                Source location of subjectId, ie ldap
            .NOTES
                Author: Travis Sobeck
                LASTEDIT: 7/30/2018

            .EXAMPLE
        #>
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory)]
            [string]$uri,

            [Parameter(Mandatory)]
                [System.Collections.Hashtable]$header,

            [string]$contentType = 'text/x-json;charset=UTF-8',

            [Parameter(Mandatory)]
            [string]$groupName,

            [Parameter(Mandatory)]
            [string]$subjectId,

            [string]$subjectSourceId
        )

        Begin{}

        Process
        {
            $uri = "$uri/groups"
            $subjectLookups = @(@{subjectId = $subjectId})
            if ($subjectSourceId){$subjectLookups[0]['subjectSourceId'] = $subjectSourceId}
                $body = @{
                    WsRestAddMemberRequest = @{
                        subjectLookups = $subjectLookups
                        wsGroupLookup = @{groupName = $groupName}
                    }
                } | ConvertTo-Json -Depth 5
                $response = Invoke-WebRequest -Uri $uri -Headers $header -Method Post -Body $body -UseBasicParsing -ContentType $contentType
                return @(($response.Content | ConvertFrom-Json).WsAddMemberResults.results.wsSubject,($response.Content | ConvertFrom-Json).WsAddMemberResults.wsGroupAssigned)
        }

        End{}
    }
#endregion

#region New-GrouperPrivileges
function New-GrouperPrivileges
{
    <#
        .SYNOPSIS
            Set Grouper Privileges

        .DESCRIPTION
            Set Grouper Privileges)

        .PARAMETER uri
            Full path to Server plus path to API
            Example "https://<FQDN>/grouper-ws/servicesRest/json/v2_2_100"

        .PARAMETER header
            Use New-Header to get this

        .PARAMETER contentType
            Set Content Type, currently 'text/x-json;charset=UTF-8'

        .PARAMETER stemName
            stemName
        
        .PARAMETER subjectId
            User to apply Privilege to 

        .PARAMETER actAsSubjectId
            User security context to use to apply change

        .PARAMETER privilegeName
            Name of privilege to apply, see Get-GrouperPrivileges for examples

        .PARAMETER subjectIdIsAGroup
            Use this switch (set to true) if the subjectID is actually a GroupName.  The default assumption is that the subjectID is a users ID

        .NOTES
            Author: Travis Sobeck
            LASTEDIT: 7/30/2018

        .EXAMPLE
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$uri,

        [Parameter(Mandatory)]
        [System.Collections.Hashtable]$header,

        [string]$contentType = 'text/x-json;charset=UTF-8',

        [Parameter(Mandatory,ParameterSetName='stem')]
        [string]$stemName,

        [Parameter(Mandatory,ParameterSetName='group')]
        [string]$groupName,

        [string]$actAsSubjectId,

        [Parameter(Mandatory)]
        [string]$subjectId,

        [switch]$subjectIdIsAGroup = $false,

        [Parameter(Mandatory)]
        [string]$privilegeName
    )

    Begin{}
    Process
    {
        $uri = "$uri/grouperPrivileges"
        $body = @{
            WsRestAssignGrouperPrivilegesLiteRequest = @{
                allowed = 'T'
                privilegeName = $privilegeName                
            }
        }
        if ($subjectIdIsAGroup)
        {
            $body['WsRestAssignGrouperPrivilegesLiteRequest']['subjectIdentifier'] = $subjectId
            $body['WsRestAssignGrouperPrivilegesLiteRequest']['subjectSourceId'] = "g:gsa"
        }
        else {$body['WsRestAssignGrouperPrivilegesLiteRequest']['subjectId'] = $subjectId}

        if ($actAsSubjectId)
        {
            
            $body['WsRestAssignGrouperPrivilegesLiteRequest']['actAsSubjectId'] = $actAsSubjectId
        }
        if ($groupName)
        {
            
            $body['WsRestAssignGrouperPrivilegesLiteRequest']['groupName'] = $groupName
            $body['WsRestAssignGrouperPrivilegesLiteRequest']['privilegeType'] = 'access'
        }
        if ($stemName)
        {
            
            $body['WsRestAssignGrouperPrivilegesLiteRequest']['stemName'] = $stemName
            $body['WsRestAssignGrouperPrivilegesLiteRequest']['privilegeType'] = 'naming'
        }
        
        $body = $body | ConvertTo-Json -Depth 5
        #Write-Debug $body
        $response = Invoke-WebRequest -Uri $uri -Headers $header -Method Post -Body $body -UseBasicParsing -ContentType $contentType
        return ($response.Content | ConvertFrom-Json).WsGetGrouperPrivilegesLiteResult.privilegeResults
        if (($response.Content | ConvertFrom-Json).WsFindStemsResults.stemResults.count -gt 0)
        {
            ($response.Content | ConvertFrom-Json).WsFindStemsResults.stemResults
        }
        else {
            Write-Verbose "NO results found"
        }
    }
    End{}
}
#endregion

#region New-GrouperStem
    function New-GrouperStem
    {
        <#
            .SYNOPSIS
                Create new Stem in Grouper

            .DESCRIPTION
                Create new Stem in Grouper

            .PARAMETER uri
                Full path to Server plus path to API
                Example "https://<FQDN>/grouper-ws/servicesRest/json/v2_2_100"

            .PARAMETER header
                Use New-Header to get this

            .PARAMETER contentType
                Set Content Type, currently 'text/x-json;charset=UTF-8'

            .PARAMETER stemName
                This represents the identifier for the stem, it should look like 'stemParentA:stemParentB:stemname'
                Example: stem1:substem:newstem

            .PARAMETER description
                The description represents the the Name in the form users in the UI will see the group 

            .NOTES
                Author: Travis Sobeck
                LASTEDIT: 7/30/2018

            .EXAMPLE
        #>
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory)]
            [string]$uri,

            [Parameter(Mandatory)]
            [System.Collections.Hashtable]$header,

            [string]$contentType = 'text/x-json;charset=UTF-8',

            [Parameter(Mandatory)]
            [string]$stemName,

            [Parameter(Mandatory)]
            [string]$description
        )

        Begin{}

        Process
        {
            $uri = "$uri/stems"
            $body = @{
                WsRestStemSaveRequest = @{
                    wsStemToSaves = @(@{wsStem = @{description = $description;displayExtension = $description;name = $stemName};wsStemLookup = @{stemName = $stemName}})
                }
            } | ConvertTo-Json -Depth 5
            ($response = Invoke-WebRequest -Uri $uri -Headers $header -Method Post -Body $body -UseBasicParsing -ContentType $contentType)
            return ($response.Content | ConvertFrom-Json).WsStemSaveResults.results.wsStem
        }

        End{}
    }
#endregion

#region Remove-GrouperGroup
    function Remove-GrouperGroup
    {
        <#
            .SYNOPSIS
                Remove a Grouper Group

            .DESCRIPTION
                Remove a Grouper Group

            .PARAMETER uri
                Full path to Server plus path to API
                Example "https://<FQDN>/grouper-ws/servicesRest/json/v2_2_100"

            .PARAMETER header
                Use New-Header to get this

            .PARAMETER contentType
                Set Content Type, currently 'text/x-json;charset=UTF-8'

            .PARAMETER groupName
                The groupName, use Get-GrouperGroup to the get the "name" field

            .NOTES
                Author: Travis Sobeck
                LASTEDIT: 7/30/2018

            .EXAMPLE
        #>
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory)]
            [string]$uri,

            [Parameter(Mandatory)]
            [System.Collections.Hashtable]$header,

            [string]$contentType = 'text/x-json;charset=UTF-8',

            [Parameter(Mandatory)]
            [string[]]$groupName
        )

        Begin{}

        Process
        {
            $uri = "$uri/groups"
            <# This didn't seem to work :()
                foreach ($gn in $groupName)
                {
                    $gnArray = $gnArray + @{groupName = $gn}
                }
                $body = @{
                    WsRestGroupDeleteRequest = @{
                        wsGroupLookups = $gnArray
                    }
                } | ConvertTo-Json -Depth 5
            #>
            foreach ($gn in $groupName)
            {
                $body = @{
                    WsRestGroupDeleteRequest = @{
                        wsGroupLookups = @(@{groupName = $gn})
                    }
                } | ConvertTo-Json -Depth 5
                $response = Invoke-WebRequest -Uri $uri -Headers $header -Method Post -Body $body -UseBasicParsing -ContentType $contentType
                $deletedGroups = ($response.Content | ConvertFrom-Json).WsGroupDeleteResults.results.wsGroup
                $deletedGroups
            }
            
            #return ($response.Content | ConvertFrom-Json).WsGroupDeleteResults.results.resultMetadata.resultCode
        }

        End{}
    }
#endregion

#region Remove-GrouperStem
    function Remove-GrouperStem
    {
        <#
            .SYNOPSIS
                Remove a Grouper Stem

            .DESCRIPTION
                Remove a Grouper Stem

            .PARAMETER uri
                Full path to Server plus path to API
                Example "https://<FQDN>/grouper-ws/servicesRest/json/v2_2_100"

            .PARAMETER header
                Use New-Header to get this

            .PARAMETER contentType
                Set Content Type, currently 'text/x-json;charset=UTF-8'

            .PARAMETER stemName
                Use Get-GrouperStem to find name

            .PARAMETER removeGroups
                Grouper will not remove a Stem with other Stems or Groups in it. Set this to remove all the groups first

            .PARAMETER recursive
                Recursively remove all child stems

            .NOTES
                Author: Travis Sobeck
                LASTEDIT: 7/30/2018

            .EXAMPLE
        #>
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory)]
            [string]$uri,

            [Parameter(Mandatory)]
            [System.Collections.Hashtable]$header,

            [string]$contentType = 'text/x-json;charset=UTF-8',

            [Parameter(Mandatory)]
            [string]$stemName,

            [switch]$removeGroups,

            [switch]$recursive
        )

        Begin{}

        Process
        {
            if ($recursive)
            {
                $stemNames = (Get-GrouperStemByParent -uri $uri -header $header -parentStemName $stemName -noRecursion).Name
                foreach ($stem in $stemNames)
                {
                    (Remove-GrouperStem -uri $uri -header $header -stemName $stem -removeGroups:$removeGroups -recursive:$recursive).name
                }
            }
            if ($removeGroups)
            {
                # Get all the groups
                $groupNames = (Get-GrouperGroup -uri $uri -header $header -stemName $stemName).name
                # Remove the groups
                if ($groupNames)
                {
                    $null = Remove-GrouperGroup -uri $uri -header $header -groupName $groupNames
                    Start-Sleep -Seconds 3
                }                
            }
            $uri = "$uri/stems"
            $body = @{
                WsRestStemDeleteRequest = @{
                    wsStemLookups = @(@{stemName = $stemName})
                }
            } | ConvertTo-Json -Depth 5
            $response = Invoke-WebRequest -Uri $uri -Headers $header -Method Post -Body $body -UseBasicParsing -ContentType $contentType
            $removedStems = ($response.Content | ConvertFrom-Json).WsStemDeleteResults.results.wsStem
            return $removedStems
            #($response.Content | ConvertFrom-Json).WsStemDeleteResults.results.resultMetadata.resultCode
        }

        End{}
    }
#endregion
