# REST to CARML

This module provides you with the ability to fetch data for the API specs by providing it with the desired Provider-Namespace / Resource-Type combination.

### _Navigation_

- [Usage](#usage)
- [In-scope](#in-scope)
- [Out-of-scope](#out-of-scope)

---


## Usage
- Import the module using the command `Import-Module './utilities/tools/AzureApiCrawler/AzureApiCrawler.psm1' -Force -Verbose`
- Invoke its primary function using the command `Invoke-AzureApiCrawler -ProviderNamespace '<ProviderNamespace>' -ResourceType '<ResourceType>' -Verbose -KeepArtifacts`
- For repeated runs it is recommended to append the `-KeepArtifacts` parameter as the function will otherwise repeatably download & eventually delete the required documentation

# In scope

- Fetch data for the resource type with parameters
- Stretch: Extension resources like RBAC, Private Endpoints, etc.?

# Out of scope

- ...
