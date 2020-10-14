#Cloning function, parse in script variables
function cloneBases {

	#Get and connect to vcenter server
	write-host "Enter the VIServer name"
	$viserver = read-host 
	Connect-VIServer -Server $viserver -ErrorAction Inquire
	
	#parent vm name
	write-host "Enter the name of the vm you'd like to clone"
	$basevm = read-host
	
	#new vm name
	write-host "Enter the name of the new vm"
	$vmname = read-host
	
	#vmhost / esxi server
	write-host "What ESXI server will this vm run on?"
	$vmhost = read-host
	$vmhost = Get-VMHost -Name $vmhost -ErrorAction Inquire
	
	#datastore 
	write-host "Enter the name of the datastore where this vm will be stored"
	$dstore = read-host
	$dstore = Get-Datastore -Name $dstore -ErrorAction Inquire
	
	#snapshot folder 
	write-host "Enter the name of the folder where the basevms are stored"
	$folder = read-host 
	$folder = Get-Folder -Name $folder -ErrorAction Inquire
	
	#snapshot 
	write-host "Enter the name of the snapshot that will be cloned "
	$snapshot = read-host			
	$snapshot = Get-SnapShot -VM $basevm -Name $snapshot -ErrorAction Inquire
	
	#what type of clone 
	write-host "What type of clone do you want to make: Linked (1) or Full (2)?"
	$cloneType = read-host 
	
	#switch statement for both types of clones
	switch ($cloneType) {
	
		#Linked Clone
		1 {
	
			$newLinkedVM = New-VM -Name $vmname -VM $basevm -LinkedClone -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $dstore -Location $folder -ErrorAction Inquire
			$newvm
		}	
	
		#Full clone
		2 {
			
			#create temp VM
			$tempVMName = $vmname + ".base.linked"
			$tempvm = New-VM -Name $tempVMName -VM $basevm -LinkedClone -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $dstore -Location $folder -ErrorAction Inquire
			#create full VM from temp
			$newFullVM = New-VM -Name $vmname -VM $tempvm -VMHost $vmhost -Datastore $dstore -ErrorAction Inquire
			#delete temp VM
			Remove-VM $tempVMName -ErrorAction Inquire
			$newFullVM
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

cloneBases
	






