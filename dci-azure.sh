#!/bin/sh

#DCIHOME="/home/docker/dci-for-azure-2.0.0-tp1"

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

    sshPublicKey=$8
    echo "SSH Public Key: $sshPublicKey"
 
    ucpversion=$9
    echo "DCI UCP Version: $ucpversion"

    dtrversion=${10}
    echo "DCI DTR Version: $dtrversion"

    dockerlicense=${11}
    echo "License: $dockerlicense"

    managerCount=${12}
    echo "Manager Count: $managerCount"

    managerVMSize=${13}
    echo "Manager VM Size: $managerVMSize"

    linuxwrkCount=${14}
    echo "Linux Worker Count: $linuxwrkCount"

    linuxwrkVMSize=${15}
    echo "Linux Worker VM Size: $linuxwrkVMSize"

    dtrCount=${16}
    echo "Linux Worker Count: $dtrCount"

    dtrVMSize=${17}
    echo "Linux Worker VM Size: $dtrVMSize"

    winwrkCount=${18}
    echo "Windows Worker Count: $winwrkCount"

    winwrkVMSize=${19}
    echo "Windows Worker VM Size: $winwrkVMSize"

    linuxOS=${20}
    echo "linuxOS: $linuxOS"

    ucpadminpasswd=${21}

    dciVersion=${22}
    echo "DCI Version= $dciVersion"

    dcideploymentName=${23}
    echo "Deployment Name= $dcideploymentName"
    
    hubUsername=${24}
    hubPassword=${25}

    windows_admin_password=${26}
    echo "Windows Admin Password= $windows_admin_password"
    
    sshPrivKey=${27}
    echo "Key: $sshPrivKey"

    echo "Great you're all set"
    echo "Remove .SETUP_COMPLETED if you want to re-run setup"

    touch ".SETUP_COMPLETED"

    DCIHOME="/home/docker/dci-for-azure-$dciVersion"
    HOME="/home/docker"

    #login to Store
    docker login -p $hubPassword -u $hubUsername

    #docker run --rm --name dci -v "$DCIHOME/:/home" "docker/certified-infrastructure:azure-latest" cp -r . /home
    cd $HOME && curl -fsSL https://download.docker.com/dci/for/azure.sh | sh

    lic_dir=$DCIHOME/docker_subscription.lic
    echo "$dockerlicense" > "$lic_dir"

    cp $DCIHOME/examples/terraform.tfvars.$linuxOS.example $DCIHOME/terraform.tfvars
    cd $DCIHOME

    # edit terraform.tfvars
    sed -i -e '/deployment /s/ = "[^"]*"/= "'$dcideploymentName'"/' terraform.tfvars
    sed -i -e '/ucp_admin_password /s/ = "[^"]*"/= "'$ucpadminpasswd'"/' terraform.tfvars
    sed -i -e '/region /s/ = "[^"]*"/= '$dciAzureRegion'/' terraform.tfvars

    # update number of cluster nodes
    sed -i -e '/linux_ucp_manager_count /s/ = [0-9]$/= '$managerCount'/' terraform.tfvars
    sed -i -e '/linux_ucp_worker_count /s/ = [0-9]$/= '$linuxwrkCount'/' terraform.tfvars
    sed -i -e '/linux_dtr_count /s/ = [0-9]$/= '$dtrCount'/' terraform.tfvars
    sed -i -e '/windows_ucp_worker_count /s/ = [0-9]$/= '$winwrkCount'/' terraform.tfvars

    # update Azure AD Service Principal info
    sed -i -e '/client_id /s/ = "[^"][^"]*"/="'$dciAzureClientID'"/' terraform.tfvars
    sed -i -e '/client_secret /s/ = "[^"][^"]*"/="'$dciAzureClientSecret'"/' terraform.tfvars
    sed -i -e '/subscription_id /s/ = "[^"][^"]*"/="'$dciAzureSubscriptionID'"/' terraform.tfvars
    sed -i -e '/tenant_id /s/ = "[^"][^"]*"/="'$dciAzureTenantID'"/' terraform.tfvars

    # edit VM sizes
    sed -i -e '/linux_manager_instance_type /s/ = "[^"]*"/= "'$managerVMSize'"/' instances.auto.tfvars
    sed -i -e '/linux_worker_instance_type /s/ = "[^"]*"/= "'$linuxwrkVMSize'"/' instances.auto.tfvars
    sed -i -e '/windows_worker_instance_type /s/ = "[^"]*"/= "'$winwrkVMSize'"/' instances.auto.tfvars
    sed -i -e '/dtr_instance_type /s/ = "[^"]*"/= "'$dtrVMSize'"/' instances.auto.tfvars

    # enable Kubernetes Option to "true"
    sed -i -e '/enable_kubernetes_azure_disk /s/ = "[^"]*"/= "true"/' terraform.tfvars

    # set Windows Credendials
    if [[ $winwrkCount -gt 0 ]]; then
	echo "Setup credentials for Windows worker nodes"
    	sed -i -e '/windows_user/s/^# //' terraform.tfvars
    	sed -i -e '/windows_admin_password/s/^# //' terraform.tfvars
    	sed -i -e '/windows_admin_password /s/ = "[^"]*"/= "'$windows_admin_password'"/' terraform.tfvars
    fi

    # decode SSH private key and store in /home/docker/.ssh
    ssh_priv_dir=$HOME/.ssh/id_rsa
    echo -n  "$sshPrivKey" | base64 -d -i >> $ssh_priv_dir

    # SSH Public Key store in /home/docker/.ssh
    #ssh_pub_dir=$HOME/.ssh/id_rsa.pub
    #echo -n "$sshPublicKey" | base64 -d -i >> "$ssh_pub_dir"
    
    # parse EE subscription URL
    dockerEEsub="$(echo $dciDockerEESub | sed -e 's#.*/##')"
    echo $dockerEEsub

    # edit Docker EE subscriptions
    docker_ee_dir="inventory/2.config"

    if [[ $linuxOS == *"ubuntu"* ]]; then
        echo "Ubuntu"
        sed -i -e '/ docker_ee_subscriptions_ubuntu/s/^# //' $docker_ee_dir
        sed -i -e '/docker_ee_subscriptions_ubuntu/s/= [^"]*/= '$dockerEESub'/' $docker_ee_dir
        sed -i -e '/ docker_ee_package_version=3:17.06.2~ee~16~3-0~ubuntu/s/^# //' $docker_ee_dir
    elif [[ $linuxOS == *"rhel"* ]]; then
        echo "RHEL"
        sed -i -e '/ docker_ee_subscriptions_redhat/s/^# //' $docker_ee_dir
        sed -i -e '/docker_ee_subscriptions_redhat/s/= [^"]*/= '$dockerEESub'/' $docker_ee_dir
        sed -i -e '/ docker_ee_package_version= 17.06.2.ee.16-3.el7/s/^# //' $docker_ee_dir
    elif [[ $linuxOS == *"centos"* ]]; then
        sed -i -e '/ docker_ee_subscriptions_centos/s/^# //' $docker_ee_dir
        sed -i -e '/docker_ee_subscriptions_centos/s/= [^"]*/= '$dockerEESub'/' $docker_ee_dir
        sed -i -e '/ docker_ee_package_version= 17.06.2.ee.16-3.el7/s/^# //' $docker_ee_dir
    elif [[ $linuxOS == *"oraclelinux"* ]]; then
        sed -i -e '/ docker_ee_subscriptions_oracle/s/^# //' $docker_ee_dir
        sed -i -e '/docker_ee_subscriptions_oracle/s/= [^"]*/= '$dockerEESub'/' $docker_ee_dir
        sed -i -e '/ docker_ee_package_version= 17.06.2.ee.16-3.el7/s/^# //' $docker_ee_dir
    elif [[ $linuxOS == *"sles"* ]]; then
        sed -i -e '/ docker_ee_subscriptions_sles/s/^# //' $docker_ee_dir
        sed -i -e '/docker_ee_subscriptions_sles/s/= [^"]*/= '$dockerEESub'/' $docker_ee_dir
        sed -i -e '/ docker_ee_package_version= 2:17.06.2.ee.16-3/s/^# //' $docker_ee_dir
    fi

    #DCI_SSH_KEY="$HOME/.ssh/id_rsa"
    #DCI_CLOUD="azure"

    #./dci.sh create
else
    echo "updated terraform.tfvars and inventory/2.config files."
    echo "Remove .SETUP_COMPLETED if you want to updated configuration and re-run setup"
    echo "Exiting!\n"
    exit 0
fi
