#!/bin/sh

dciwd="/home/docker/dci-for-azure-2.0.0"
dcihome="/home/docker"

#install unzip
sudo apt-get install -y unzip

#install docker
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

#download azure setup
#docker run --rm --name dci -v "$(pwd)/:/home" "docker/certified-infrastructure:azure-latest" cp -r . /home
#docker run --rm --name dci -v "$(dciwd)/:/home" "docker/certified-infrastructure:azure-latest" cp -r . /home

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

    dciDockerEESubscription=$7
    echo "DockerEESubscription: $dciDockerEESubscription"

    dcidockeree=$8
    echo "dcidockeree: $dcidockeree"
 
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

    linuxOffer=${20}
    echo "linuxOffer: $linuxOffer"

    dciadminpass=${21}

    hubUsername=${22}
    hubPassword=${23}
    
    SSHPrivKey=${24}
    echo "Key: $SSHPrivKey"

    echo "Great you're all set"
    echo "Remove .SETUP_COMPLETED if you want to re-run setup"

    touch ".SETUP_COMPLETED"

    docker login -p $hubPassword -u $hubUsername
    #docker run --rm --name dci -v "$dciwd/:/home" "docker/certified-infrastructure:azure-latest" cp -r . /home
    cd /home/docker && curl -fsSL https://download.docker.com/dci/for/azure.sh | sh

    destfile=$dciwd/docker_subscription.lic
    echo "$dockerlicense" > "$destfile"

    cp $dciwd/examples/terraform.tfvars.$linuxOffer.example $dciwd/terraform.tfvars
    cd $dciwd

    # edit terraform.tfvars
    #sed -i -e '/deployment /s/ = "[^"]*"/= '$dcideploymentname'/' terraform.tfvars
    sed -i -e '/region /s/ = "[^"]*"/= '$dciAzureRegion'/' terraform.tfvars

    sed -i -e '/linux_ucp_manager_count /s/ = [0-9]$/= '$managerCount'/' terraform.tfvars
    sed -i -e '/linux_ucp_worker_count /s/ = [0-9]$/= '$linuxwrkCount'/' terraform.tfvars
    sed -i -e '/linux_dtr_count /s/ = [0-9]$/= '$dtrCount'/' terraform.tfvars
    sed -i -e '/windows_ucp_worker_count /s/ = [0-9]$/= '$winwrkCount'/' terraform.tfvars

    sed -i -e '/client_id /s/ = "[^"][^"]*"/="'$dciAzureClientID'"/' terraform.tfvars
    sed -i -e '/client_secret /s/ = "[^"][^"]*"/="'$dciAzureClientSecret'"/' terraform.tfvars
    sed -i -e '/subscription_id /s/ = "[^"][^"]*"/="'$dciAzureSubscriptionID'"/' terraform.tfvars
    sed -i -e '/tenant_id /s/ = "[^"][^"]*"/="'$dciAzureTenantID'"/' terraform.tfvars

    #edit instances.auto.tfvars
    sed -i -e '/linux_manager_instance_type /s/ = "[^"]*"/= '$managerVMSize'/' instances.auto.tfvars
    sed -i -e '/linux_worker_instance_type /s/ = "[^"]*"/= '$linuxwrkVMSize'/' instances.auto.tfvars
    sed -i -e '/windows_worker_instance_type /s/ = "[^"]*"/= '$winwrkVMSize'/' instances.auto.tfvars
    sed -i -e '/dtr_instance_type /s/ = "[^"]*"/= '$dtrVMSize'/' instances.auto.tfvars

    destdir=$dcihome/.ssh/id_rsa
    #echo  ${SSHPrivKey} | base64 --decode > $destdir
    #echo -n  "$SSHPrivKey" | base64 -d -i > $destdir
    echo "$SSHPrivKey" > "$destdir"
    
    

else
    echo "Looks like you've already run setup, we've probably already emited these files"
    echo "Remove .SETUP_COMPLETED if you want to re-run setup"
    echo "Exiting!\n"
    exit 0
fi
