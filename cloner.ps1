$myConfig = Get-Content -Raw -Path "/home/micah/Scripts/cloner.json" | ConvertFrom-Json
function cloneBases {
	#Try to connect to Server
	$c = Connect-VIServer -Server $myconfig.vcenter_server -ErrorAction Inquire
	if ($c) {
		#once connected display all base-vms
		Write-Host "Displaying all BASE-VMS:"
		$baseVMS = Get-VM -Location $myConfig.base_folder | foreach {$_.Name}
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
		#run script again?
		write-host "Run script again? (y/n)"
		$scriptAgain = read-host
				
		switch ($scriptAgain) {
		
			"y" {
			
			cloneBases
			
			}
			
			"n" {

			Break
		
			}
		
		}
	}
}

cloneBases
	





#>
