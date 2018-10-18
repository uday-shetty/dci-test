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

    linuxuser=${21}

    dciVersion=${22}
    echo "DCI Version= $dciVersion"

    dcideploymentName=${23}
    echo "Deployment Name= $dcideploymentName"
    
    ucpadminusername=${24}
    echo "Docker EE Username = $ucpadminusername"

    ucpadminpasswd=${25}
    echo "Docker EE passwd = $ucpadminpasswd"

    hubUsername=${26}
    hubPassword=${27}

    windows_admin_password=${28}
    echo "Windows Admin Password= $windows_admin_password"
    
    sshPrivKey=${29}
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
    sed -i -e '/deployment /s/ = "[^"]*"/= "'$dcideploymentName'"/' terraform.tfvars
    sed -i -e '/ucp_admin_password /s/ = "[^"]*"/= "'$ucpadminpasswd'"/' terraform.tfvars
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
    
    #docker_ee_dir="inventory/2.config"

    #
# Docker EE Platform variables
#
#[all:vars]
echo "docker_ee_release_channel=stable" >> terraform.tfvars
echo "docker_ee_version=17.06" >> terraform.tfvars
#<placeholder>  Format= sub-xxx-xxx-xxx-xxx
echo "docker_ee_subscriptions_ubuntu= sub-1d0661e3-2ba1-4362-9e5f-42d56ad03eb8" >> terraform.tfvars
echo "docker_ee_package_version=3:17.06.2~ee~16~3-0~ubuntu" >> terraform.tfvars
#
# docker_ee_subscriptions_centos= <placeholder>
# docker_ee_package_version= 17.06.2.ee.16-3.el7
#
# docker_ee_subscriptions_redhat= <placeholder>
# docker_ee_package_version= 17.06.2.ee.16-3.el7
#
# docker_ee_subscriptions_oracle= <placeholder>
# docker_ee_package_version= 17.06.2.ee.16-3.el7
#
# docker_ee_subscriptions_sles= <placeholder>
# docker_ee_package_version= 2:17.06.2.ee.16-3
echo "docker_ee_package_version_win=17.06.2-ee-16" >> terraform.tfvars
echo "docker_ucp_version=3.0.4" >> terraform.tfvars
# docker_ucp_license_path: "{{ playbook_dir }}/docker_subscription.lic"
# docker_ucp_cert_file= ssl_cert/ucp_cert.pem
# docker_ucp_ca_file= ssl_cert/ucp_ca.pem
# docker_ucp_key_file= ssl_cert/ucp_key.pem
# docker_ucp_admin_password=<placeholder>
# docker_ucp_admin_username=<placeholder>
# docker_ucp_lb=<placeholder>
echo "docker_dtr_version=2.5.3" >> terraform.tfvars
# docker_dtr_cert_file= ssl_cert/dtr_cert.pem
# docker_dtr_key_file= ssl_cert/dtr_key.pem
# docker_dtr_ca_file= ssl_cert/dtr_ca.pem
# docker_dtr_lb= <placeholder>
# docker_dtr_replica_id= <placeholder> # (A 12-character long hexadecimal number= e.g. 1234567890ab)
#
# Docker storage volume.
#
# If this is set to a block device then the device will be formatted with the recommended fs for the OS
# and mounted at /var/lib/docker.
# docker_storage_volume="/dev/xvdb"
#
# Cloudstor
#
# Set to "disabled" to prevent the plugin being installed (even if cloudstor_plugin_options is set).
echo "cloudstor_plugin_version=1.0" >> terraform.tfvars

    #if [[ $linuxOS == *"ubuntu"* ]]; then
    #    echo "Ubuntu"
    #    sed -i -e '/ docker_ee_subscriptions_ubuntu/s/^# //' $docker_ee_dir
    #    sed -i -e '/docker_ee_subscriptions_ubuntu/s/= [^"]*/= '$dockerEESub'/' $docker_ee_dir
    #    sed -i -e '/ docker_ee_package_version=3:17.06.2~ee~16~3-0~ubuntu/s/^# //' $docker_ee_dir
    #elif [[ $linuxOS == *"rhel"* ]]; then
    #    echo "RHEL"
    #    sed -i -e '/ docker_ee_subscriptions_redhat/s/^# //' $docker_ee_dir
    #    sed -i -e '/docker_ee_subscriptions_redhat/s/= [^"]*/= '$dockerEESub'/' $docker_ee_dir
    #    sed -i -e '/ docker_ee_package_version= 17.06.2.ee.16-3.el7/s/^# //' $docker_ee_dir
    #elif [[ $linuxOS == *"centos"* ]]; then
    #    sed -i -e '/ docker_ee_subscriptions_centos/s/^# //' $docker_ee_dir
    #    sed -i -e '/docker_ee_subscriptions_centos/s/= [^"]*/= '$dockerEESub'/' $docker_ee_dir
    #    sed -i -e '/ docker_ee_package_version= 17.06.2.ee.16-3.el7/s/^# //' $docker_ee_dir
    #elif [[ $linuxOS == *"oraclelinux"* ]]; then
    #    sed -i -e '/ docker_ee_subscriptions_oracle/s/^# //' $docker_ee_dir
    #    sed -i -e '/docker_ee_subscriptions_oracle/s/= [^"]*/= '$dockerEESub'/' $docker_ee_dir
    #    sed -i -e '/ docker_ee_package_version= 17.06.2.ee.16-3.el7/s/^# //' $docker_ee_dir
    #elif [[ $linuxOS == *"sles"* ]]; then
    #    sed -i -e '/ docker_ee_subscriptions_sles/s/^# //' $docker_ee_dir
    #    sed -i -e '/docker_ee_subscriptions_sles/s/= [^"]*/= '$dockerEESub'/' $docker_ee_dir
    #    sed -i -e '/ docker_ee_package_version= 2:17.06.2.ee.16-3/s/^# //' $docker_ee_dir
    #fi

    # execute DCI script
    export DCI_SSH_KEY="$HOME/.ssh/id_rsa"
    export DCI_CLOUD="azure"
    echo "Executing dci script"
    $DCIHOME/dci.sh create

else
    echo "updated terraform.tfvars and inventory/2.config files."
    echo "Remove .SETUP_COMPLETED if you want to updated configuration and re-run setup"
    echo "Exiting!\n"
    exit 0
fi
