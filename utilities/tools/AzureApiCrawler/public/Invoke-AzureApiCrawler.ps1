<#
.SYNOPSIS
Get module configuration data based on the latest API information available

.DESCRIPTION
Get module configuration data based on the latest API information available

.PARAMETER ProviderNamespace
Mandatory. The provider namespace to query the data for

.PARAMETER ResourceType
Mandatory. The resource type to query the data for

.PARAMETER IncludePreview
Mandatory. Include preview API versions

.PARAMETER KeepArtifacts
Optional. Skip the removal of downloaded/cloned artifacts (e.g. the API-Specs repository). Useful if you want to run the function multiple times in a row.

.EXAMPLE
Invoke-AzureApiCrawler -ProviderNamespace 'Microsoft.Keyvault' -ResourceType 'vaults'

Get the data for [Microsoft.Keyvault/vaults]

.EXAMPLE
Invoke-AzureApiCrawler -ProviderNamespace 'Microsoft.AVS' -ResourceType 'privateClouds' -Verbose -KeepArtifacts

Get the data for for [Microsoft.AVS/privateClouds] and do not delete any downloaded/cloned artifact.
#>
function Invoke-AzureApiCrawler {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ProviderNamespace,

        [Parameter(Mandatory = $true)]
        [string] $ResourceType,

        [Parameter(Mandatory = $false)]
        [switch] $IncludePreview,

        [Parameter(Mandatory = $false)]
        [switch] $KeepArtifacts
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)

        Write-Verbose ('Processing module [{0}/{1}]' -f $ProviderNamespace, $ResourceType) -Verbose

        $initialLocation = (Get-Location).Path
    }

    process {

        #########################################
        ##   Temp Clone API Specs Repository   ##
        #########################################
        $repoUrl = $script:CONFIG.url_CloneRESTAPISpecRepository
        $repoName = Split-Path $repoUrl -LeafBase

        # Clone repository
        ## Create temp folder
        if (-not (Test-Path $script:temp)) {
            $null = New-Item -Path $script:temp -ItemType 'Directory'
        }
        ## Switch to temp folder
        Set-Location $script:temp

        ## Clone repository into temp folder
        if (-not (Test-Path (Join-Path $script:temp $repoName))) {
            git clone --depth=1 --single-branch --branch=main --filter=tree:0 $repoUrl
        } else {
            Write-Verbose "Repository [$repoName] already cloned"
        }

        Set-Location $initialLocation

        try {
            ###########################
            ##   Fetch module data   ##
            ###########################
            $getPathDataInputObject = @{
                ProviderNamespace = $ProviderNamespace
                ResourceType      = $ResourceType
                RepositoryPath    = Join-Path $script:temp $repoName
                IncludePreview    = $IncludePreview
            }
            $pathData = Get-ServiceSpecPathData @getPathDataInputObject

            $resolveInputObject = @{
                JSONFilePath = $pathData.jsonFilePath
                JSONKeyPath  = $pathData.jsonKeyPath
                ResourceType = $ResourceType
            }
            $moduleData = Resolve-ModuleData @resolveInputObject

            #######################
            ##   Create output   ##
            #######################
            $moduleData
            # TODO: Continue

        } catch {
            throw $_
        } finally {
            ##########################
            ##   Remove Artifacts   ##
            ##########################
            if (-not $KeepArtifacts) {
                Write-Verbose ('Deleting temp folder [{0}]' -f $script:temp)
                $null = Remove-Item $script:temp -Recurse -Force
            }
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
