Clear-Host

$emails = "email1@email.com", "email2@email.com"

$users = "uniqueID1", "uniqueID2"

class UserInfo{
    [string]$user
    [string]$email
    [string]$groupCode
}

$UserInfos = New-Object System.Collections.Generic.List[UserInfo]
$GroupCode = "GroupCode"

for($i = 0; $i -lt $users.Count; $i++){

    $UserInfo = New-Object UserInfo
    $UserInfo.email = $emails[$i]
    $UserInfo.user = $users[$i]
    $UserInfo.groupCode = $GroupCode

    $UserInfos.Add($UserInfo)
}

$UserInfos | ForEach-Object -Process {
        $email = $_.email
        $user = $_.user
        $groupCode = $_.groupCode
        
        Start-Job -ScriptBlock { 

            function Generate-FileName{
                param($Prefix, $GroupCode, $username)

                $DateNow = [DateTime]::Now
    
                $Year = $DateNow.Year
                $MonthString = $DateNow.ToString("MM")
                $DayString = $DateNow.ToString("dddd")
                $Day = $DateNow.Day
                $Month = Add-Zero -Number $DateNow.Month
                $Hour = Add-Zero -Number $DateNow.Hour
                $Minute = Add-Zero -Number $DateNow.Minute
                $Second = Add-Zero -Number $DateNow.Second
                $MilliSec = Add-Zero -Number $DateNow.Millisecond
    
                return "$Prefix-$GroupCode-$username-$Year$MonthString$Day$Hour$Minute$Second$MilliSec"
            }

            # Adding zero to have a 2 digit number
            function Add-Zero{
                param($Number)
    
                if($Number -le 9){
                    return '0' + $Number.ToString()
                }else{
                    return $Number.ToString()
                }
            }
            
            $resourceGroupName = Generate-FileName -Prefix "AS" -GroupCode $args[2] -username $args[0]

            if([bool](New-AzureRmResourceGroup -Name $resourceGroupName -Location "southeastasia")){
                New-AzureRmRoleAssignment `
                    -ResourceGroupName $resourceGroupName `
                    -SignInName $args[1] `
                    -RoleDefinitionName Owner | Out-Null
                $resourceGroupName
            }

        } -ArgumentList $user, $email, $groupCode;
        Start-Sleep -s 5 
        # Azure gets very upset if you slam too much work at it and randomly decides not to accept the request.
        # Therefore you need to put a delay with at least 5 seconds.
}
Get-Job | Wait-Job | Receive-Job

#Get-AzureRmResourceGroup | Select-Object -Property "ResourceGroupName" | Where-Object {$_.ResourceGroupName -like "AS-$GroupCode-*"}

#(Get-AzureRmResourceGroup | Select-Object -Property "ResourceGroupName" | Where-Object {$_.ResourceGroupName -like "AS-$GroupCode-*"}).Count
