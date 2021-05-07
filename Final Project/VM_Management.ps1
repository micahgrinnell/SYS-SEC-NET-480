#Before running the file, you must first edit the server variable at the bottom 
$myConfig = Get-Content -Raw -Path ".\my_config.json" | ConvertFrom-Json
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
                setNetwork $vmName $numInterface $preferredNetwork #Sets the network adapter
            }
            #get details 
            3 {
                Write-Host "Enter VM name"
                $vmName = Read-Host
                Get-NetworkAdapter -VM $vmName -ErrorAction Ignore #Returns all details about specified VM
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
        Write-Host ($t).guest.ipaddress[0] hostname=$t
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
    Write-Host "    [4] Clone VM from Base"
    Write-Host "    [R] Return to main menu"
    Write-Host "    [Q] Quit"
    Write-Host "-------------------------------------------------`nSelect an option:"
    $option = Read-Host 

    switch ($option) {
    
        #create new switch
        1 { 
            Write-Host "Enter switch name"
            $switchName = Read-Host
            Write-Host "Enter esxi host name or ip"
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
        # Clone bases
        4 {
            cloneBases
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

function cloneBases {
	
		#once connected display all base-vms
		Write-Host "Displaying all BASE-VMS:"
		$baseVMS = Get-VM -Location $myConfig.base_folder | ForEach-Object {$_.Name}
		$t = 0
		foreach ($n in $baseVMS) {
			Write-Host "[$t] "  $baseVMS[$t]
			$t = $t + 1
		}

		#Choose base vm and clone type
		Write-Host "Which VM do you want to clone? [x]"
		$index = 0
		$index = Read-Host
		Write-Host "You chose " $baseVMS[$index]
		Write-Host "[F]ull clone of Base or [L]inked clone of Base:"
		$cloneType = Read-Host

		#get details
		#new vm name
		write-host "Enter the name of the new vm"
		$newVMName = read-host
		$vmHost = Get-VMHost -Name $myconfig.vm_host -ErrorAction Inquire
		$dstore = Get-Datastore -Name $myconfig.preferred_datastore -ErrorAction Inquire
		$folder = Get-Folder -Name $myconfig.base_folder -ErrorAction Inquire
		$snapshot = Get-SnapShot -VM $baseVMS[$index] -Name $myconfig.preferred_snapshot -ErrorAction Inquire

		switch ($cloneType) {
			#full clone
			"F" { 
				#create temp VM
				$tempVMName = $newVMName + ".base.linked"
				$tempvm = New-VM -Name $tempVMName -VM $baseVMS[$index] -LinkedClone -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $dstore -Location $folder -ErrorAction Inquire
				#create full VM from temp
				$newFullVM = New-VM -Name $newVMName -VM $tempvm -VMHost $vmhost -Datastore $dstore -ErrorAction Inquire
				#delete temp VM
				Remove-VM $tempVMName -ErrorAction Inquire
				$newFullVM
			 }
			 #linked clone
			"L" {
				$newLinkedVM = New-VM -Name $newVMName -VM $baseVMS[$index] -LinkedClone -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $dstore -Location $folder -ErrorAction Inquire
				$newLinkedVM
			}
		}
        Start-Sleep -Seconds 5
		configNetworks
		}
	


#Try to connect to Server
$c = Connect-VIServer -Server $myconfig.vcenter_server -ErrorAction Inquire
if ($c) {
	configNetworks
}
else {
	Write-Host "Could not connect to server please try again"
	break
}

