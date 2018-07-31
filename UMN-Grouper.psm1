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

#region New-Header
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

#region Get-GrouperGrouper
    function Get-GrouperGrouper
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
            [string]$header,

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

#region Get-GrouperStem
    function Get-GrouperStem
    {
        <#
            .SYNOPSIS
                Get Grouper Stem(s)

            .DESCRIPTION
                Get Grouper Stem(s)

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
            [string]$header,

            [string]$contentType = 'text/x-json;charset=UTF-8',

            [Parameter(Mandatory)]
            [string]$stemName,

            [string]$subjectId
        )

        Begin{}

        Process
        {
            $uri = "$uri/stems"
            $body = @{
                    WsRestFindStemsRequest = @{
                        wsStemQueryFilter = @{stemName = $stemName;stemQueryFilterType = 'FIND_BY_STEM_NAME_APPROXIMATE'}
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
                Write-Warning "NO results found"
            }
        }

        End{}
    }
#endregion

#region New-GrouperGrouper
#endregion
#region New-GrouperStem
#endregion

#region Remove-GrouperGrouper
    function Remove-GrouperGrouper
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
                The groupName, use Get-GrouperGrouper to the get the "name" field

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
            [string]$header,

            [string]$contentType = 'text/x-json;charset=UTF-8',

            [Parameter(Mandatory)]
            [string[]]$groupName
        )

        Begin{}

        Process
        {
            $uri = "$uri/groups"
            [array]$gnArray = @()
            foreach ($gn in $groupName)
            {
                $gnArray = $gnArray + @{groupName = $gn}
            }
            $body = @{
                WsRestGroupDeleteRequest = @{
                    wsGroupLookups = $gnArray
                }
            } | ConvertTo-Json -Depth 5
            $response = Invoke-WebRequest -Uri $uri -Headers $header -Method Post -Body $body -UseBasicParsing -ContentType $contentType
            $deletedGroups = ($response.Content | ConvertFrom-Json).WsGroupDeleteResults.results.wsGroup
            return $deletedGroups
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
            [string]$header,

            [string]$contentType = 'text/x-json;charset=UTF-8',

            [Parameter(Mandatory)]
            [string]$stemName,

            [switch]$removeGroups
        )

        Begin{}

        Process
        {
            if ($removeGroups)
            {
                # Get all the groups
                #$groups = 

                # Remove the groups
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


    function Remove-GrouperGrouper
    {
        <#
            .SYNOPSIS
                

            .DESCRIPTION
                

            .PARAMETER uri
                Full path to Server plus path to API
                Example "https://<FQDN>/grouper-ws/servicesRest/json/v2_2_100"

            .PARAMETER header
                Use New-Header to get this

            .PARAMETER contentType
                Set Content Type, currently 'text/x-json;charset=UTF-8'

            .PARAMETER 

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
            [string]$header,

            [string]$contentType = 'text/x-json;charset=UTF-8',

            [Parameter(Mandatory)]
        )

        Begin{}

        Process
        {
            $uri = "$uri/"
        }

        End{}
    }
