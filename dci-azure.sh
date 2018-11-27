#!/bin/sh

#install unzip
sudo apt-get install -y unzip
sudo apt-get install -y jq

#install docker engine
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install -y docker-ce

service docker restart

# provision and install EE
dci_create() {
    VOLUME_MOUNTED_KEY="$(basename "${DCI_SSH_KEY}")"
    TERRAFORM_OPTIONS="-var 'ssh_private_key_path=${VOLUME_MOUNTED_KEY}'"

    docker run --rm \
        -v "$(pwd):/dci/${DCI_CLOUD}/" \
        -v "${DCI_SSH_KEY}:/dci/${DCI_CLOUD}/${VOLUME_MOUNTED_KEY}" \
        "${DCI_REPOSITORY}/certified-infrastructure:${DCI_REFERENCE}" \
        sh -c "terraform init ${TERRAFORM_OPTIONS}; \
               terraform apply -auto-approve ${TERRAFORM_OPTIONS}"

    docker run --rm \
        -v "$(pwd):/dci/${DCI_CLOUD}/" \
        -v "${DCI_SSH_KEY}:/dci/${DCI_CLOUD}/${VOLUME_MOUNTED_KEY}" \
        "${DCI_REPOSITORY}/certified-infrastructure:${DCI_REFERENCE}" \
        ansible-playbook install.yml
}

if [ ! -f ".SETUP_COMPLETED" ]; then

    echo "Azure Setup\n"

    dciAzureClientID=$1
    echo "AzureClientID: $dciAzureClientID"

    dciAzureClientSecret=$2
    echo "Entered Azure Client Secret"

    dciAzureSubscriptionID=$3
    echo "Azure Subscription ID: $dciAzureSubscriptionID"

    dciAzureTenantID=$4
    echo "AzureTenantID: $dciAzureTenantID"

    dciAzureRegion=$5
    echo "AzureRegion: $dciAzureRegion"

    dciAzureResourceGroup=$6
    echo "AzureResourceGroup: $dciAzureResourceGroup"

    dciDockerEESub=$7
    echo "DockerEESubscription: $dciDockerEESub"

    ucpversion=$8
    echo "DCI UCP Version: $ucpversion"

    dtrversion=${9}
    echo "DCI DTR Version: $dtrversion"

    dockerlicense=${10}
    echo "License: $dockerlicense"

    managerCount=${11}
    echo "Manager Count: $managerCount"

    managerVMSize=${12}
    echo "Manager VM Size: $managerVMSize"

    linuxwrkCount=${13}
    echo "Linux Worker Count: $linuxwrkCount"

    linuxwrkVMSize=${14}
    echo "Linux Worker VM Size: $linuxwrkVMSize"

    dtrCount=${15}
    echo "DTR Count: $dtrCount"

    dtrVMSize=${16}
    echo "DTR VM Size: $dtrVMSize"

    winwrkCount=${17}
    echo "Windows Worker Count: $winwrkCount"

    winwrkVMSize=${18}
    echo "Windows Worker VM Size: $winwrkVMSize"

    linuxOS=${19}
    echo "linuxOS: $linuxOS"

    linuxuser=${20}

    dciVersion=${21}
    echo "DCI Version= $dciVersion"

    dcideploymentName=${22}
    echo "Deployment Name= $dcideploymentName"
    
    windowsOS=${23}
    echo "WindowsVersion= $windowsOS"

    ucpadminpasswd=${24}
    echo "Docker EE passwd = $ucpadminpasswd"

    hubUsername=${25}
    hubPassword=${26}

    windows_admin_password=${27}
    echo "Windows Admin Password= $windows_admin_password"
    
    sshPrivKey=${28}
    echo "Key: $sshPrivKey"

    echo "Great you're all set"
    echo "Remove .SETUP_COMPLETED if you want to re-run setup"

    touch ".SETUP_COMPLETED"

    DCIHOME="/home/docker/dci-for-azure-$dciVersion"
    HOME="/home/docker"

    #login to Store
    docker login -p $hubPassword -u $hubUsername

    #docker run --rm --name dci -v "$DCIHOME/:/home" "docker/certified-infrastructure:azure-latest" cp -r . /home
    docker pull docker/certified-infrastructure:azure-$dciVersion
    cd $HOME && curl -fsSL https://download.docker.com/dci/for/azure.sh | sh

    lic_dir=$DCIHOME/docker_subscription.lic
    echo "$dockerlicense" > "$lic_dir"

    cp $DCIHOME/examples/terraform.tfvars.$linuxOS.example $DCIHOME/terraform.tfvars
    cd $DCIHOME

    # edit terraform.tfvars

    # update ucp/dtr versions, deployment name and ucp passwd
    sed -i -e '/deployment /s/ = "[^"]*"/= "'$dcideploymentName'"/' terraform.tfvars
    sed -i -e '/docker_ucp_version /s/ = "[^"]*"/= "'$ucpversion'"/' terraform.tfvars
    sed -i -e '/docker_dtr_version /s/ = "[^"]*"/= "'$dtrversion'"/' terraform.tfvars
    sed -i -e '/ docker_ucp_admin_password/s/^# //' terraform.tfvars
    sed -i -e '/docker_ucp_admin_password /s/ = "[^"]*"/= "'$ucpadminpasswd'"/' terraform.tfvars
    sed -i -e '/region /s/ = "[^"]*"/= "'$dciAzureRegion'"/' terraform.tfvars

    # update number of cluster nodes
    sed -i -e '/linux_ucp_manager_count /s/ = [0-9]$/= '$managerCount'/' terraform.tfvars
    sed -i -e '/linux_ucp_worker_count /s/ = [0-9]$/= '$linuxwrkCount'/' terraform.tfvars
    sed -i -e '/linux_dtr_count /s/ = [0-9]$/= '$dtrCount'/' terraform.tfvars
    sed -i -e '/windows_ucp_worker_count /s/ = [0-9]$/= '$winwrkCount'/' terraform.tfvars

    # update Azure AD Service Principal info
    sed -i -e '/client_id /s/ = "[^"][^"]*"/= "'$dciAzureClientID'"/' terraform.tfvars
    sed -i -e '/client_secret /s/ = "[^"][^"]*"/= "'$dciAzureClientSecret'"/' terraform.tfvars
    sed -i -e '/subscription_id /s/ = "[^"][^"]*"/= "'$dciAzureSubscriptionID'"/' terraform.tfvars
    sed -i -e '/tenant_id /s/ = "[^"][^"]*"/= "'$dciAzureTenantID'"/' terraform.tfvars

    # edit VM sizes
    sed -i -e '/linux_manager_instance_type /s/ = "[^"]*"/= "'$managerVMSize'"/' instances.auto.tfvars
    sed -i -e '/linux_worker_instance_type /s/ = "[^"]*"/= "'$linuxwrkVMSize'"/' instances.auto.tfvars
    sed -i -e '/windows_worker_instance_type /s/ = "[^"]*"/= "'$winwrkVMSize'"/' instances.auto.tfvars
    sed -i -e '/dtr_instance_type /s/ = "[^"]*"/= "'$dtrVMSize'"/' instances.auto.tfvars

    # enable Kubernetes Option to "true"
    sed -i -e '/enable_kubernetes_azure_disk /s/ = false/ = true/' terraform.tfvars

    # set Linux user name
    sed -i -e '/linux_user /s/ = "[^"]*"/= "'$linuxuser'"/' terraform.tfvars

    # set Windows Credendials
    if [[ $winwrkCount -gt 0 ]]; then
	echo "Setup credentials for Windows worker nodes"
    	sed -i -e '/windows_user/s/^#//' terraform.tfvars
    	sed -i -e '/windows_user/s/^#//' terraform.tfvars
    	sed -i -e '/windows_user /s/ = "[^"]*"/= "'$linuxuser'"/' terraform.tfvars
    	sed -i -e '/windows_admin_password/s/^#//' terraform.tfvars
    	sed -i -e '/windows_admin_password /s/ = "[^"]*"/= "'$windows_admin_password'"/' terraform.tfvars
        if [[ $windowsOS == *"2016"* ]]; then
          echo "Windows 2016"
          sed -i -e  '/offer /s/ = "WindowsServer"/= "WindowsServer"/' terraform.tfvars
          sed -i -e  '/sku /s/ = "2016-DataCenter"/= "2016-DataCenter"/' terraform.tfvars
        elif [[ $windowsOS == *"1709"* ]]; then
          echo "Windows 1709"
          sed -i -e  '/offer /s/ = "WindowsServer"/= "WindowsServerSemiAnnual"/' terraform.tfvars
          sed -i -e  '/sku /s/ = "2016-DataCenter"/= "Datacenter-Core-1709-smalldisk"/' terraform.tfvars
        elif [[ $windowsOS == *"1803"* ]]; then
          echo "Windows 1803"
          sed -i -e  '/offer /s/ = "WindowsServer"/= "WindowsServerSemiAnnual"/' terraform.tfvars
          sed -i -e  '/sku /s/ = "2016-DataCenter"/= "Datacenter-Core-1803-with-Containers-smalldisk"/' terraform.tfvars
        fi
    fi

    # decode SSH private key and store in /home/docker/.ssh
    ssh_priv_dir=$HOME/.ssh/id_rsa
    echo -n  "$sshPrivKey" | base64 -d -i >> $ssh_priv_dir

    # parse EE subscription URL
    dockerEESub="$(echo $dciDockerEESub | sed -e 's#.*/##')"
    echo $dockerEESub

    # update OS specific Docker EE subscriptions info

    if [[ $linuxOS == *"ubuntu"* ]]; then
        echo "Ubuntu"
    #    sed -i -e '/ docker_ee_subscriptions_ubuntu/s/^# //' $docker_ee_dir
    #    sed -i -e '/docker_ee_subscriptions_ubuntu/s/= [^"]*/= '$dockerEESub'/' $docker_ee_dir
         echo "docker_ee_subscriptions_ubuntu= \"$dockerEESub\"" >> terraform.tfvars
    elif [[ $linuxOS == *"rhel"* ]]; then
        echo "RHEL"
    #    sed -i -e '/ docker_ee_subscriptions_redhat/s/^# //' $docker_ee_dir
    #    sed -i -e '/docker_ee_subscriptions_redhat/s/= [^"]*/= '$dockerEESub'/' $docker_ee_dir
         echo "docker_ee_subscriptions_redhat= \"$dockerEESub\"" >> terraform.tfvars
    elif [[ $linuxOS == *"centos"* ]]; then
        echo "CentOS"
    #    sed -i -e '/ docker_ee_subscriptions_centos/s/^# //' $docker_ee_dir
    #    sed -i -e '/docker_ee_subscriptions_centos/s/= [^"]*/= '$dockerEESub'/' $docker_ee_dir
         echo "docker_ee_subscriptions_centos= \"$dockerEESub\"" >> terraform.tfvars
    elif [[ $linuxOS == *"oraclelinux"* ]]; then
         echo "Oracle Linux"
    #    sed -i -e '/ docker_ee_subscriptions_oracle/s/^# //' $docker_ee_dir
    #    sed -i -e '/docker_ee_subscriptions_oracle/s/= [^"]*/= '$dockerEESub'/' $docker_ee_dir
         echo "docker_ee_subscriptions_oracle= \"$dockerEESub\"" >> terraform.tfvars
    elif [[ $linuxOS == *"sles"* ]]; then
         echo "Suse Linux"
    #    sed -i -e '/ docker_ee_subscriptions_sles/s/^# //' $docker_ee_dir
    #    sed -i -e '/docker_ee_subscriptions_sles/s/= [^"]*/= '$dockerEESub'/' $docker_ee_dir
         echo "docker_ee_subscriptions_sles= \"$dockerEESub\"" >> terraform.tfvars
    fi

    # set DCI parameters (Required)
    DCI_SSH_KEY="$HOME/.ssh/id_rsa"
    DCI_CLOUD="azure"

    # set DCI parameters (Optional)
    DCI_VERSION=${DCI_VERSION:-${dciVersion}}
    DCI_REPOSITORY=${DCI_REPOSITORY-"docker"}
    DCI_REFERENCE=${DCI_REFERENCE:-"${DCI_CLOUD}-${DCI_VERSION}"}
    echo "DCI_REFERENCE=$DCI_REFERENCE"

    echo "Executing dci script"
    dci_create

else
    echo "updated terraform.tfvars and inventory/2.config files."
    echo "Remove .SETUP_COMPLETED if you want to updated configuration and re-run setup"
    echo "Exiting!\n"
    exit 0
fi
