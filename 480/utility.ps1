function configNetworks {
        Clear-Host
        #if connected then do stuff:
        #Network Configuration Option Menu:
        Write-Host "Network Configuration Menu`n-------------------------------------------------"
        Write-Host "    [1] Create objects"
        Write-Host "    [2] Set existing network adapter to network"
        Write-Host "    [3] Get network adapter details"
        Write-Host "    [4] Get IP address of VM"
        Write-Host "    [5] Delete objects"
        Write-Host "    [Q] Quit"
        Write-Host "-------------------------------------------------`nSelect an option:"
        $option = Read-Host 

        switch ($option) {
            #create objects function
            1 {
                objectCreate
            }
            #Set existing network adapter to network
            2 {
                Write-Host "Enter VM name"
                $vmName = Read-Host
                Write-Host "Enter network"
                $preferredNetwork = Read-Host
                Write-Host "Network Adapters:"
                Get-NetworkAdapter -VM $vmName -ErrorAction Ignore
                Write-Host "Enter adapter number (e.g. Network adapter [X])"
                $numInterface = Read-Host
                setNetwork $vmName $numInterface $preferredNetwork
            }
            #get details
            3 {
                Write-Host "Enter VM name"
                $vmName = Read-Host
                Get-NetworkAdapter -VM $vmName -ErrorAction Ignore
                Start-Sleep -Seconds 5
            }
            #Get IP Address
            4 {
                Write-Host "Enter VM name"
                $vmName = Read-Host
                getIP($vmName)
            }
            #Delete Objects 
            5{
                objectDelete
            }
            #quit
            "Q" {
                exit
            }
        }
        configNetworks
        #gettips(wks)
}          

#Function for changing adapter network setting
#Parse in vmname, interface number, and preferred network
function setNetwork([string] $vmName, [int] $numInterface, [string] $preferredNetwork) {
    
    $interface = "Network adapter $numInterface"
    $vm = Get-VM -Name $vmName
    $networkAdapter = Get-NetworkAdapter -VM $vm -Name $interface -ErrorAction Ignore
    $setNetworkAdapter = Set-NetworkAdapter -NetworkAdapter $networkAdapter -NetworkName $preferredNetwork -ErrorAction Ignore
    $setNetworkAdapter
    Start-Sleep -Seconds 5
    configNetworks
}

#Function for getting Ansible friendly ip and hostname
#Parse in vmname
function getIP([string] $vmName) {
    $vm = Get-VM -Name $vmName
    foreach ($t in $vm) {
        Write-Host $t.Guest.IPAddress[0] hostname=$t
    }
    Write-Host "Press any key to continue...";
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    configNetworks
}

#Function for creating objects
function objectCreate {
    #menu for object creation
    Clear-Host
    Write-Host "Object Creation Menu`n-------------------------------------------------"
    Write-Host "    [1] Create virtual switch"
    Write-Host "    [2] Create virtual port group"
    Write-Host "    [3] Create network adapter"
    Write-Host "    [R] Return to main menu"
    Write-Host "    [Q] Quit"
    Write-Host "-------------------------------------------------`nSelect an option:"
    $option = Read-Host 

    switch ($option) {
    
        #create new switch
        1 { 
            Write-Host "Enter switch name"
            $switchName = Read-Host
            Write-Host "Enter esxi host name"
            $esxi_host = Read-Host
            $createSwitch = New-VirtualSwitch -VMHost $esxi_host -Name $switchName -ErrorAction Ignore
            $createSwitch 
            Start-Sleep -Seconds 5
            objectCreate
        }
        #Create new port group
        2 {
            Write-Host "Enter switch name"
            $switchName = Read-Host
            Write-Host "Enter the new port group name"
            $portGroupName = Read-Host
            $createPortGroup = New-VirtualPortGroup -VirtualSwitch $switchName -Name $portGroupName -ErrorAction Ignore
            $createPortGroup 
            Start-Sleep -Seconds 5
            objectCreate
        }
        #Create new network adapter
        3 {
            Write-Host "Enter VM name"
            $vmName = Read-Host
            Write-Host "Enter network"
            $networkName = Read-Host
            $newNetworkAdapter = New-NetworkAdapter -VM $vmName -NetworkName $networkName -ErrorAction Ignore
            $newNetworkAdapter
            Start-Sleep -Seconds 5
            objectCreate
        }
         #return to main menu
        "R" {
            configNetworks
        }
        #quit
        "Q" {
            exit
        }   
    }
}

function objectDelete {
    Clear-Host
    Write-Host "Delete Objects Menu`n-------------------------------------------------"
    Write-Host "    [1] Delete switch"
    Write-Host "    [2] Delete port group"
    Write-Host "    [3] Delete network adapter"
    Write-Host "    [R] Return to main menu"
    Write-Host "    [Q] Quit"
    Write-Host "-------------------------------------------------`nSelect an option:"
    $doption = Read-Host 

    switch ($doption) {
        #delete switch
        1 { 
            Write-Host "Enter switch name"
            $switchName = Read-Host
            $vswitch = Get-VirtualSwitch -Name $switchName -ErrorAction Ignore
            $switchRemove = Remove-VirtualSwitch -VirtualSwitch $vswitch -ErrorAction Ignore
            $switchRemove
            Start-Sleep -Seconds 5
            objectDelete
        }
        #delete port group 
        2 {
            Write-Host "Enter port group name"
            $portGroupName = Read-Host
            $vportgroup = Get-VirtualPortGroup -Name $portGroupName -ErrorAction Ignore
            $portGroupRemove = Remove-VirtualPortGroup -VirtualSwitch $vportgroup -ErrorAction Ignore
            $portGroupRemove
            Start-Sleep -Seconds 5
            objectDelete
        }
        #delete network adapter
        3 {
            Write-Host "Enter VM name"
            $vmName = Read-Host
            Write-Host "Network Adapters:"
            Get-NetworkAdapter -VM $vmName -ErrorAction Ignore
            Write-Host "Enter interface name to delete (e.g. Network adapter X)"
            $interfaceName = Read-Host
            $netAdapter = Get-NetworkAdapter -VM $vmName -Name $interfaceName
            $netAdapterRemove = Remove-NetworkAdapter -NetworkAdapter $netAdapter -ErrorAction Ignore
            $netAdapterRemove
            Start-Sleep -Seconds 5
            objectDelete
        }
        #return to main menu
        "R" {
            configNetworks
        }
        #quit
        "Q" {
            exit
        }   
    }
}

Clear-Host
$c = Connect-VIServer -Server "vcenter.micah.local"
#Test if connected to server
if($c){
    configNetworks
    }
else{
    Write-Host "Invalid Connection"
}
