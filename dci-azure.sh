#!/bin/sh

dciwd="/home/docker/dci-for-azure-2.0.0"

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

    echo "Hello, we just need to setup a handful of variables to get started\n"

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

    dtrversion=$10
    echo "DCI DTR Version: $dtrversion"

    dockerlicense=${11}

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

    linuxOSVersion=${21}
    echo "linuxOSVersion: $linuxOSVersion"

    dciName=${22}
    echo "dciName: $dciName"

    dciadminpass=${23}

    hubUsername=${24}
    hubPassword=${25}
    
    SSHPrivKey=${26}
    destdir=$dciwd/.ssh/id_rsa
    echo -n  "$SSHPrivKey" | base64 -d >> $destdir

    echo "Great you're all set"
    echo "Remove .SETUP_COMPLETED if you want to re-run setup"

    touch ".SETUP_COMPLETED"

    docker login -p $hubPassword -u $hubUsername
    #docker run --rm --name dci -v "$dciwd/:/home" "docker/certified-infrastructure:azure-latest" cp -r . /home
    cd /home/docker && curl -fsSL https://download.docker.com/dci/for/azure.sh | sh

    destfile=$dciwd/docker_subscription.lic
    echo "$dockerlicense" > "$destfile"

else
    echo "Looks like you've already run setup, we've probably already emited these files"
    echo "Remove .SETUP_COMPLETED if you want to re-run setup"
    echo "Exiting!\n"
    exit 0
fi
