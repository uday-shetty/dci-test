#!/bin/sh
dciStack="azure"
dciContainerTag="stack-$dciStack-master-cc99641"

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

#sudo apt-get install -y software-properties-common

#install unzip
sudo apt-get install -y unzip

#install terraform
wget https://releases.hashicorp.com/terraform/0.11.5/terraform_0.11.5_linux_amd64.zip
unzip terraform_0.11.5_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version

#install ansible
apt-get --yes install sofware-properties-common
apt-add-repository --yes ppa:ansible/ansible 
apt-get --yes update 
apt-get --yes install ansible

#sudo apt-get upgrade
#sudo apt-get install -y software-properties-common
#sudo apt-add-repository ppa:ansible/ansible
#sudo apt-get update
#sudo apt-get install -y ansible
ansible --version

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

    dciDockerEESubscription=$6
    echo "DockerEESubscription: $dciDockerEESubscription"

    dcidockeree=$7
    echo "dcidockeree: $dcidockeree"
 
    ucpversion=$8
    echo "DCI UCP Version: $ucpversion"

    dtrversion=$9
    echo "DCI DTR Version: $dtrversion"

    dockerlicense=${10}
    destfile=docker_subscription.lic
    echo "$dockerlicense" > "$destfile"

    managerCount=${11}
    echo "Manager Count: $managerCount"

    managerVMSize=${12}
    echo "Manager VM Size: $managerVMSize"

    linuxwrkCount=${13}
    echo "Linux Worker Count: $linuxwrkCount"

    linuxwrkVMSize=${14}
    echo "Linux Worker VM Size: $linuxwrkVMSize"

    winwrkCount=${15}
    echo "Windows Worker Count: $winwrkCount"

    winwrkVMSize=${16}
    echo "Windows Worker VM Size: $winwrkVMSize"

    linuxOffer=${17}
    echo "linuxOffer: $linuxOffer"

    dciName=${18}
    echo "dciName: $dciName"

    dciadminpass=${19}
    
    SSHPublicKey=${20}
    mkdir -p /dci/$dciStack/
    destdir=/dci/$dciStack/id_rsa.pub
    echo -n  "$SSHPublicKey" | base64 -d >> $destdir
    cat $destdir

    echo "Great you're all set"
    echo "Remove .SETUP_COMPLETED if you want to re-run setup"

    if [ "$linuxOffer" == "UbuntuServer" ]; then
       linuxOffer="Ubuntu"
       echo "linuxOffer: $linuxOffer"
    fi

    touch ".SETUP_COMPLETED"
    touch terraform.tfstate

    #Override the group_vars
    mkdir -p group_vars/
    echo "---\ncloudstor_plugin_version: 1.0" > group_vars/all

    #Stage the inventory
    mkdir -p inventory/
    touch "inventory/1.hosts"
    realPathForSSHPrivateKey="`realpath ${dciSSHPrivateKey/#\~/$HOME}`"

    #Let's drop some templates too
    mkdir -p kube-templates

    cat > terraform.tfvars << EOF
deployment                 = "$dciName"
region                     = "$dciAzureRegion"
ssh_private_key_path       = "/dci/$dciStack/ssh_key"
linux_ucp_manager_count    = "$managerCount"
linux_ucp_worker_count     = "$linuxwrkCount"
linux_dtr_count            = "$managerCount"
windows_ucp_worker_count   = "$winwrkCount"
ansible_inventory          = "inventory/1.hosts"
ucp_license_path           = "./docker_subscription.lic"
ucp_admin_password         = "$dciadminpass"
client_id                  = "$dciAzureClientID"
client_secret              = "$dciAzureClientSecret"
subscription_id            = "$dciAzureSubscriptionID"
tenant_id                  = "$dciAzureTenantID"
linux_user                 = "ubuntu"
enable_kubernetes_azure_disk = true
EOF

    cat > inventory/docker-ee << EOF
[all:vars]
docker_ee_subscriptions_ubuntu="$dciDockerEESubscription"
docker_ee_release_channel=stable
docker_ee_version="$dcidockeree"
docker_ee_package_version=3:17.06.2~ee~14~3-0~ubuntu
docker_ee_package_version_win=17.06.2-ee-14
EOF

    cat > inventory/docker-ucp << EOF
[all:vars]
docker_ucp_image_repository=docker
docker_ucp_version="$ucpversion"
EOF

    cat > inventory/docker-dtr << EOF
[all:vars]
docker_dtr_image_repository=docker
docker_dtr_version="$dtrversion"
EOF

    cat > buildStack << EOF
#!/bin/sh
docker run -it --rm \\
    -v "`pwd`/terraform.tfvars":/dci/$dciStack/terraform.tfvars \\
    -v "`pwd`/terraform.tfstate":/dci/$dciStack/terraform.tfstate \\
    -v "`pwd`/inventory/docker-ee":/dci/$dciStack/inventory/docker-ee \\
    -v "`pwd`/inventory/docker-ucp":/dci/$dciStack/inventory/docker-ucp \\
    -v "`pwd`/inventory/docker-dtr":/dci/$dciStack/inventory/docker-dtr \\
    -v "`pwd`/inventory/1.hosts":/dci/$dciStack/inventory/1.hosts \\
    -v "${realPathForSSHPrivateKey}":/dci/$dciStack/ssh_key \\
    dockereng/certified-infrastructure:$dciContainerTag \\
    sh -c "terraform init && terraform apply -auto-approve"
docker run -it --rm \\
    -v `pwd`/terraform.tfvars:/dci/$dciStack/terraform.tfvars \\
    -v `pwd`/terraform.tfstate:/dci/$dciStack/terraform.tfstate \\
    -v `pwd`/inventory/docker-ee:/dci/$dciStack/inventory/docker-ee \\
    -v `pwd`/inventory/docker-ucp:/dci/$dciStack/inventory/docker-ucp \\
    -v `pwd`/inventory/docker-dtr:/dci/$dciStack/inventory/docker-dtr \\
    -v `pwd`/inventory/1.hosts:/dci/$dciStack/inventory/1.hosts \\
    -v `pwd`/group_vars/all:/dci/$dciStack/group_vars/all \\
    -v "${realPathForSSHPrivateKey}":/dci/$dciStack/ssh_key \\
    dockereng/certified-infrastructure:$dciContainerTag \\
    ansible-playbook --private-key=/dci/$dciStack/ssh_key install.yml
EOF

    cat > destroyStack << EOF
#!/bin/sh
#Assuming we had installed the UCP bundle, we want to run this container locally 
export DOCKER_TLS_VERIFY=
export COMPOSE_TLS_VERSION=
export DOCKER_CERT_PATH=
export DOCKER_HOST=
docker run -it --rm \\
    -v "`pwd`/terraform.tfvars":/dci/$dciStack/terraform.tfvars \\
    -v "`pwd`/terraform.tfstate":/dci/$dciStack/terraform.tfstate \\
    -v "`pwd`/inventory/docker-ee":/dci/$dciStack/inventory/docker-ee \\
    -v "`pwd`/inventory/docker-ucp":/dci/$dciStack/inventory/docker-ucp \\
    -v "`pwd`/inventory/docker-dtr":/dci/$dciStack/inventory/docker-dtr \\
    -v "`pwd`/inventory/1.hosts":/dci/$dciStack/inventory/1.hosts \\
    -v "${realPathForSSHPrivateKey}":/dci/$dciStack/ssh_key \\
    dockereng/certified-infrastructure:$dciContainerTag \\
    sh -c "terraform init && terraform destroy -force"
EOF

    cat > kube-templates/azure-disk-test.yaml << EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: standard
provisioner: kubernetes.io/azure-disk
parameters:
  storageaccounttype: Standard_LRS
  kind: Managed
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: task-pv-claim
spec:
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
---
kind: Pod
apiVersion: v1
metadata:
  name: task-pv-pod
spec:
  volumes:
    - name: task-pv-storage
      persistentVolumeClaim:
       claimName: task-pv-claim
  containers:
    - name: task-pv-container
      image: nginx
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: task-pv-storage
EOF
else
    echo "Looks like you've already run setup, we've probably already emited these files"
    echo "Remove .SETUP_COMPLETED if you want to re-run setup"
    echo "Exiting!\n"
    exit 0
fi
