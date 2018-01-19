[CmdletBinding()]
Param (
    $ClientID, $ClientSecret, $TenantID
)
function GetAuthToken {
    [CmdletBinding()]
    Param (
        $ClientID, $ClientSecret, $TenantID 
    )
    

    $TokenEndpoint = {https://login.windows.net/ {0}/oauth2/token} -f $TenantID 
    $ARMResource = "https://management.core.windows.net/";
    
    $Body = @{
        'resource'      = $ARMResource
        'client_id'     = $ClientID
        'grant_type'    = 'client_credentials'
        'client_secret' = $ClientSecret
    }
    
    $params = @{
        ContentType = 'application/x-www-form-urlencoded'
        Headers     = @{'accept' = 'application/json'}
        Body        = $Body
        Method      = 'Post'
        URI         = $TokenEndpoint
    }
    
    $token = Invoke-RestMethod @params
    
    return $token
}
 
# Getting authentication token
$token = GetAuthToken -ClientID $ClientID -ClientSecret $ClientSecret -TenantID $TenantID

Add-AzureRMAccount -AccessToken $token.Access_Token -AccountId $TenantID | Out-Null

$resources = Find-AzureRmResource -ResourceType "Microsoft.Network/virtualNetworks"

$usageArray = @()
foreach ($resource in $resources) {
    $usage = Get-AzureRmVirtualNetworkUsageList -ResourceGroupName $resource.ResourceGroupName -Name $resource.ResourceName
     
    if ($usage -is [System.Array]) {
        foreach ($u in $usage) {
            if (!($u.Id.Split("/")[-1] -match "GatewaySubnet")) {
                [int]$AvailableAddresses = $u.Limit - $u.CurrentValue
                $obj = [pscustomobject]@{
                    VirtualNetworkName = $u.Id.Split("/")[-3]
                    SubnetName         = $u.Id.Split("/")[-1]
                    TotalAddresses     = $u.Limit
                    UsedAddresses      = $u.CurrentValue
                    AvailableAddresses = $AvailableAddresses
                }
                $usageArray += $obj
                $obj = $null    
            }
        }
    }
    else {
        if (!($usage.Id.Split("/")[-1] -match "GatewaySubnet")) {
            [int]$AvailableAddresses = $usage.Limit - $usage.CurrentValue
            $obj = [pscustomobject]@{
                VirtualNetworkName = $usage.Id.Split("/")[-3]
                SubnetName         = $usage.Id.Split("/")[-1]
                TotalAddresses     = $usage.Limit
                UsedAddresses      = $usage.CurrentValue
                AvailableAddresses = $AvailableAddresses
            }
            $usageArray += $obj
            $obj = $null 
        }
    }
    
}

$usageArray | Format-Table