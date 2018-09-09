az group delete --name custom-acs-rg
echo 'deleted rg'

az group create --name custom-acs-rg --location centralindia
echo 'created rg'

az network vnet create -n vnet-acs --address-prefix 10.0.0.0/16 --subnet-name acs-cluster-subnet --subnet-prefix 10.0.1.0/24 -g custom-acs-rg --location centralindia
echo 'created vnet'

echo 'creating acs cluster'
az acs create --name custom-acs-cluster \
              --resource-group custom-acs-rg \
              --admin-username linuxadmin \
              --agent-count 1 \
              --agent-osdisk-size 64 \
              --agent-storage-profile ManagedDisks \
              --agent-vm-size Standard_E2_v3 \
              --agent-vnet-subnet-id '/subscriptions/0d2f1119-530d-4547-917e-ad9024059695/resourceGroups/custom-acs-rg/providers/Microsoft.Network/virtualNetworks/vnet-acs/subnets/acs-cluster-subnet' \
              --generate-ssh-keys \
              --location centralindia \
              --master-count 1 \
              --master-first-consecutive-static-ip 10.0.1.5 \
              --master-osdisk-size 30 \
              --master-storage-profile ManagedDisks \
              --master-vm-size Standard_E2_v3 \
              --master-vnet-subnet-id '/subscriptions/0d2f1119-530d-4547-917e-ad9024059695/resourceGroups/custom-acs-rg/providers/Microsoft.Network/virtualNetworks/vnet-acs/subnets/acs-cluster-subnet' \
              --orchestrator-type Kubernetes \

echo 'created acs cluster'