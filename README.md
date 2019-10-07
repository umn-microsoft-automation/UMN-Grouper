# UMN-Grouper
This Powershell module is a collection of function to interact with the Internet2 grouper rest API 
https://github.com/Internet2/grouper
https://spaces.internet2.edu/display/Grouper/Grouper+Web+Services

## Update '1.0.9'
Add new function Get-GrouperGroupsForMember and improved search in Get-GrouperGroup

## Update '1.0.8'
Add recursion to function Remove-GrouperGroup.
Change Write-Warnings to Write-Verbose

## Update '1.0.7'
Add function Get-GrouperStemByParent for improved searches of Stems.  Default with search for stems only one level below parent stem.  Add the -recursive flag to search recursively
Also add the function Get-GrouperStemByUUID to get stems by their UUID

## Update '1.0.6'
Update subjectSourceID to search grouper groups when setting priviledges

## Update '1.0.4'
Update function New-GrouperPrivileges to be able to apply a Grouper Group to Privileges

## Update '1.0.3'
Add functions New-GrouperPrivileges and Get-GrouperPrivileges

## Update '1.0.2'
Add functions New-GrouperGroupMember and Get-GrouperGrouperMembers 

## Update '1.0.1'
Fix bugs