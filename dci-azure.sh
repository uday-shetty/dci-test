#!/bin/sh
dciStack="azure"
dciContainerTag="stack-$dciStack-master-cc99641"

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

    dciSSHPublicKey=$6
    echo "SSHPublicKey: $dciSSHPublicKey"

    dciDockerEESubscription=$7
    echo "dciDockerEESubscription: $DockerEESubscription"

    dcidockeree=$8
    echo "dcidockeree: $dcidockeree"
 
    ucpversion=$9
    echo "DCI UCP Version: $ucpversion"

    dtrversion=${10}
    echo "DCI DTR Version: $dtrversion"

    dockerlicense=${11}
    echo "entered Docker License"

    managerCount=${12}
    echo "Manager Count: $managerCount"

    managerVMSize=${13}
    echo "Manager VM Size: $managerVMSize"

    linuxworkerCount=${14}
    echo "Linux Worker Count: $linuxworkerCount"

    linuxwrkVMSize=${15}
    echo "Linux Worker VM Size: $linuxwrkVMSize"

    winwrkCount=${16}
    echo "Windows Worker Count: $winwrkCount"

    winwrkVMSize=${17}
    echo "Windows Worker VM Size: $winwrkVMSize"

    linuxOffer=${18}
    echo "linuxOffer: $linuxOffer"

    dciName=${19}
    echo "dciName: $dciName"

    echo "Great you're all set"
    echo "Remove .SETUP_COMPLETED if you want to re-run setup"

    if [ "$linuxOffer" == "UbuntuServer" ]; then
       linuxOffer="Ubuntu"
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
ucp_license_path           = "./$docker_subscription.lic"
ucp_admin_password         = ""
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
