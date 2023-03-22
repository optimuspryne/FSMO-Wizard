function FSMO-Selector {
     
    $all = New-Object System.Management.Automation.Host.ChoiceDescription '&All', 'Answer: All'
    $pdc = New-Object System.Management.Automation.Host.ChoiceDescription '&PDCEmulator', 'Answer: PDCEmulator'
    $rid = New-Object System.Management.Automation.Host.ChoiceDescription '&RIDMaster', 'Answer: RIDMaster'
    $inf = New-Object System.Management.Automation.Host.ChoiceDescription '&InfrastructureMaster', 'Answer: InfrastructureMaster'
    $scm = New-Object System.Management.Automation.Host.ChoiceDescription '&SchemaMaster', 'Answer: SchemaMaster'
    $dnm = New-Object System.Management.Automation.Host.ChoiceDescription '&DomainNamingMaster', 'Answer: DomainNamingMaster'
    $cancel = New-Object System.Management.Automation.Host.ChoiceDescription '&Cancel', 'Answer: Cancel'


    $options = [System.Management.Automation.Host.ChoiceDescription[]]($all, $pdc, $rid, $inf, $scm, $dnm,$cancel)
    $choice = $host.ui.PromptForChoice("FSMO Roles", "What FSMO Roles would you like to transfer?", $options, 0)

    switch ($choice) {
        0 {"all"; Break}
        1 { 0; Break}
        2 { 1; Break}
        3 { 2; Break}
        4 { 3; Break}
        5 { 4; Break}
        6 {"cancel"; Break}
    }

    return $choice

}

function YN-Menu {

    #This function takes two strings as parameters and uses them in the creation of a Yes/No prompt for the user.  This function should work for any Yes/No question you might need.

    #Takes two strings a parameter to build the menu
    param([string]$Title,[string]$Question)
    
    #Creating the two menu objects and adding them to an array.
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes', 'Answer: Yes'
    $no = New-Object System.Management.Automation.Host.ChoiceDescription '&No', 'Answer: No'
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    
    #Building the user prompt object using the two Parameters and the $options array.
    $choice = $host.ui.PromptForChoice($Title, $Question, $options, 0)

    #Yes is the default option
    switch ($choice) {
        0 {"Yes"; Break}
        1 {"No"; Break}
    }

}

function Transfer-Roles {

    param($Role, $Identity)

    if ($Role -eq 'all'){
         Move-ADDirectoryServerOperationMasterRole -Identity $Identity -OperationMasterRole 0,1,2,3,4
    }else {
         Move-ADDirectoryServerOperationMasterRole -Identity $Identity -OperationMasterRole $Role
    }


}

function Demote-DC {

$remove = YN-Menu -Title "Please Confirm" -Question "Do you wish to Demote the server you're currently working on as well?"

if($remove -eq "Yes"){
    Write-Host "Testing Demotion first, please fix any issues found before proceeding."
    Test-ADDSDomainControllerUninstallation -RemoveApplicationPartitions
    Read-Host "Testing complete, press ENTER to continue..."
    Uninstall-ADDSDomainController -RemoveApplicationPartitions -NoRebootOnCompletion -Confirm
    Uninstall-WindowsFeature AD-Domain-Services -IncludeManagementTools
}else{
    Break
}

}

do {
    Write-Host "This script will transfer the whatever FSMO roles you choose to the Server name provided. It's best to run this script from the DC you're transfering roles from. Proceed with caution."
    $serverName = Read-Host "Please enter the name of the server you would like to transfer roles to:  "
    Write-Host "Confirming Domain replication first..."
    repadmin /showrepl
    $confirm = YN-Menu -Title "Please Confirm." -Question "Does replication look good? Are you sure you would like to proceed?"

    if ($confirm -eq "Yes"){
        $choice = FSMO-Selector
        if ($choice -eq "cancel"){
          Break
        }else{
          Transfer-Roles -Role $choice -Identity $serverName
        }       
    }else{
        Break
    }

    if ($choice -eq "all"){
        Demote-DC
    }

    $end = YN-Menu -Title "Please Confirm" -Question "Do you need to do anything else?"

}until ($end -eq "No")

Suspend-BitLocker -MountPoint C: -RebootCount 2
Restart-Computer
