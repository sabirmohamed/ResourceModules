# Virtual Hub Route Table `[Microsoft.Network/virtualHubs/hubRouteTables]`

This module deploys virtual hub route tables.

## Navigation

- [Virtual Hub Route Table `[Microsoft.Network/virtualHubs/hubRouteTables]`](#virtual-hub-route-table-microsoftnetworkvirtualhubshubroutetables)
  - [Navigation](#navigation)
  - [Resource Types](#resource-types)
  - [Parameters](#parameters)
  - [Outputs](#outputs)
  - [Cross-referenced modules](#cross-referenced-modules)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Network/virtualHubs/hubRouteTables` | [2022-05-01](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Network/2022-05-01/virtualHubs/hubRouteTables) |

## Parameters

**Required parameters**

| Parameter Name | Type | Description |
| :-- | :-- | :-- |
| `name` | string | The route table name. |

**Conditional parameters**

| Parameter Name | Type | Description |
| :-- | :-- | :-- |
| `virtualHubName` | string | The name of the parent virtual hub. Required if the template is used in a standalone deployment. |

**Optional parameters**

| Parameter Name | Type | Default Value | Description |
| :-- | :-- | :-- | :-- |
| `enableDefaultTelemetry` | bool | `True` | Enable telemetry via the Customer Usage Attribution ID (GUID). |
| `labels` | array | `[]` | List of labels associated with this route table. |
| `routes` | array | `[]` | List of all routes. |


## Outputs

| Output Name | Type | Description |
| :-- | :-- | :-- |
| `name` | string | The name of the deployed virtual hub route table. |
| `resourceGroupName` | string | The resource group the virtual hub route table was deployed into. |
| `resourceId` | string | The resource ID of the deployed virtual hub route table. |

## Cross-referenced modules

_None_
