<#
.SYNOPSIS
Extract all parameters from the given API spec parameter root

.DESCRIPTION
Extract all parameters from the given API spec parameter root (e.g., PUT parameters)

.PARAMETER SpecificationData
Mandatory. The source content to crawl for data.

.PARAMETER RelevantParamRoot
Mandatory. The array of root parameters to process (e.g., PUT parameters).

.PARAMETER JSONKeyPath
Mandatory. The API Path in the JSON specification file to process

.PARAMETER ResourceType
Mandatory. The Resource Type to investigate

.EXAMPLE
Get-ParametersFromRoot -SpecificationData @{ paths = @(...); definitions = @{...} } -RelevantParamRoot @(@{ $ref: "../(...)"}) '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.KeyVault/vaults/{vaultName}' -ResourceType 'vaults'

Fetch all parameters (e.g., PUT) from the KeyVault REST path.
#>
function Get-ParametersFromRoot {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable] $SpecificationData,

        [Parameter(Mandatory = $true)]
        [array] $RelevantParamRoot,

        [Parameter(Mandatory = $true)]
        [string] $JSONKeyPath,

        [Parameter(Mandatory = $true)]
        [string] $ResourceType
    )

    $definitions = $specificationData.definitions
    $specParameters = $specificationData.parameters

    $templateData = @()

    $matchingPathObjectParametersRef = ($relevantParamRoot | Where-Object { $_.in -eq 'body' }).schema.'$ref'

    if (-not $matchingPathObjectParametersRef) {
        # If 'parameters' does not exist (as the API isn't consistent), we try the resource type instead
        $matchingPathObjectParametersRef = ($relevantParamRoot | Where-Object { $_.name -eq $ResourceType }).schema.'$ref'
    }
    if (-not $matchingPathObjectParametersRef) {
        # If even that doesn't exist (as the API is even more inconsistent), let's try a 'singular' resource type
        $matchingPathObjectParametersRef = ($relevantParamRoot | Where-Object { $_.name -eq ($ResourceType.Substring(0, $ResourceType.Length - 1)) }).schema.'$ref'
    }

    $outerParameters = $definitions[(Split-Path $matchingPathObjectParametersRef -Leaf)]

    # Handle resource name
    # --------------------
    # Note: The name can be specified in different locations like the PUT statement, but also in the spec's 'parameters' object as a reference
    # Case: The name in the url is also a parameter of the PUT statement
    $pathServiceName = (Split-Path $JSONKeyPath -Leaf) -replace '{|}', ''
    if ($relevantParamRoot.name -contains $pathServiceName) {
        $param = $relevantParamRoot | Where-Object { $_.name -eq $pathServiceName }

        $parameterObject = @{
            level       = 0
            name        = 'name'
            type        = 'string'
            description = $param.description
            required    = $true
        }

        $parameterObject = Set-OptionalParameter -SourceParameterObject $param -TargetObject $parameterObject
    } else {
        # Case: The name is a ref in the spec's 'parameters' object. E.g., { "$ref": "#/parameters/BlobServicesName" }
        # For this, we need to find the correct ref, as there can be multiple
        $nonDefaultParameter = $relevantParamRoot.'$ref' | Where-Object { $_ -like '#/parameters/*' } | Where-Object { $specParameters[(Split-Path $_ -Leaf)].name -eq $pathServiceName }
        if ($nonDefaultParameter) {
            $param = $specParameters[(Split-Path $nonDefaultParameter -Leaf)]

            $parameterObject = @{
                level       = 0
                name        = 'name'
                type        = 'string'
                description = $param.description
                required    = $true
            }

            $parameterObject = Set-OptionalParameter -SourceParameterObject $param -TargetObject $parameterObject
        }
    }

    $templateData += $parameterObject

    # Process outer properties
    # ------------------------
    foreach ($outerParameter in $outerParameters.properties.Keys | Where-Object { $_ -ne 'properties' -and -not $outerParameters.properties[$_].readOnly }) {
        $param = $outerParameters.properties[$outerParameter]
        $parameterObject = @{
            level       = 0
            name        = $outerParameter
            type        = $param.keys -contains 'type' ? $param.type : 'object'
            description = $param.description
            required    = $outerParameters.required -contains $outerParameter
        }

        $parameterObject = Set-OptionalParameter -SourceParameterObject $param -TargetObject $parameterObject

        $templateData += $parameterObject
    }

    # Special case: Location
    # The location parameter is not explicitely documented at this place (even though it should). It is however referenced as 'required' and must be included
    if ($outerParameters.required -contains 'location') {
        $parameterObject = @{
            level       = 0
            name        = 'location'
            type        = 'string'
            description = 'Location for all Resources.'
            required    = $false
            default     = ($JSONKeyPath -like '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/*') ? 'resourceGroup().location' : 'deployment().location'
        }

        # param location string = resourceGroup().location
        $templateData += $parameterObject
    }

    # Process inner properties
    # ------------------------
    $innerRef = $outerParameters.properties.properties.'$ref'
    $innerParameters = $definitions[(Split-Path $innerRef -Leaf)].properties

    foreach ($innerParameter in ($innerParameters.Keys | Where-Object { -not $innerParameters[$_].readOnly })) {
        $param = $innerParameters[$innerParameter]

        $innerParamInputObject = @{
            TemplateData              = $templateData
            Parameter                 = $param
            SpecificationData         = $SpecificationData
            Level                     = 1
            Name                      = $innerParameter
            Parent                    = ''
            RequiredParametersOnLevel = $innerParameters.required
        }
        $templateData = Get-InnerParameter @innerParamInputObject
    }

    return $templateData
}

function Get-InnerParameter {

    [CmdletBinding()]
    param (
        [Parameter()]
        [hashtable] $SpecificationData,

        [Parameter()]
        [array] $RequiredParametersOnLevel,

        [Parameter()]
        [array] $TemplateData,

        [Parameter()]
        [hashtable] $Parameter,

        [Parameter()]
        [string] $Name,

        [Parameter()]
        [string] $Parent,

        [Parameter(Mandatory)]
        [int] $Level
    )

    $specDefinitions = $specificationData.definitions
    $specParameters = $specificationData.parameters

    if ($Parameter.Keys -contains 'properties') {
        # Dealing with a sub-object - requires us to iterate
        foreach ($property in $Parameter['properties'].Keys) {
            $recursiveInputObject = @{
                TemplateData      = $TemplateData
                SpecificationData = $SpecificationData
                Parameter         = $Parameter['properties'][$property]
                Level             = $Level + 1
                Parent            = $Parent
                Name              = $property
            }
            $templateData += Get-InnerParameter @recursiveInputObject
        }
        return $TemplateData
    }

    if ($Parameter.Keys -contains '$ref') {

        # Dealing with an object
        $templateData += @{
            level       = $Level
            name        = $Name
            type        = $Parameter.keys -contains 'type' ? $Parameter.type : 'object'
            description = $Parameter.description
            required    = $RequiredParametersOnLevel -contains $Name
            Parent      = $Parent
        }

        switch (($Parameter.'$ref' -split '\/')[1]) {
            'definitions' {
                $recursiveInputObject = @{
                    TemplateData      = $TemplateData
                    SpecificationData = $SpecificationData
                    Parameter         = $specDefinitions[(Split-Path $Parameter.'$ref' -Leaf)]
                    Level             = $Level + 1
                    Parent            = Split-Path $Parameter.'$ref' -Leaf
                    Name              = Split-Path $Parameter.'$ref' -Leaf
                }
                $templateData += Get-InnerParameter @recursiveInputObject
            }
            'parameters' {
                $recursiveInputObject = @{
                    TemplateData      = $TemplateData
                    SpecificationData = $SpecificationData
                    Parameter         = $specParameters[(Split-Path $Parameter.'$ref' -Leaf)]
                    Level             = $Level + 1
                    Parent            = Split-Path $Parameter.'$ref' -Leaf
                    Name              = Split-Path $Parameter.'$ref' -Leaf

                }
                $templateData += Get-InnerParameter @recursiveInputObject
            }
        }
    } else {
        $parameterObject = @{
            level       = $Level
            name        = $Name
            type        = $Parameter.keys -contains 'type' ? $Parameter.type : 'object'
            description = $Parameter.description
            required    = $RequiredParametersOnLevel -contains $Name
            Parent      = $Parent
        }

        $parameterObject = Set-OptionalParameter -SourceParameterObject $Parameter -TargetObject $parameterObject

        $templateData += $parameterObject
    }

    return $TemplateData
}
