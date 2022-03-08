# CREATE KCC HOST PROJEC
# --> export CLOUDSDK_CORE_PROJECT=kcc-root 
gcloud projects create kcc-root  

# ENABLE SERVICES
gcloud services enable krmapihosting.googleapis.com \
    container.googleapis.com \
    cloudresourcemanager.googleapis.com --project=kcc-root 

# CREATE VPC
# gcloud compute firewall-rules create <FIREWALL_NAME> --network default --allow tcp,udp,icmp --source-ranges <IP_RANGE>
# gcloud compute firewall-rules create default-allow-interal --network default --allow tcp:22,tcp:3389,icmp --project=kcc-root 
# gcloud compute firewall-rules create allow-ssh --network default --source-ranges 35.235.240.0/20 --allow tcp:22 --project=kcc-root 
gcloud compute networks create default --subnet-mode=auto --project=kcc-root 

# CREATE NAT ROUTER (TO ACCESS GITHUB)
gcloud compute routers create default-nat-router --network default --region us-central1 --project kcc-root

gcloud compute routers nats create default-nat-config --router-region us-central1 --router default-nat-router \
--nat-all-subnet-ip-ranges --auto-allocate-nat-external-ips --project kcc-root

## Test
gcloud compute ssh <KCC_HOST> --zone us-central1-f  --tunnel-through-iap --project kcc-root 

# CREATE CONTROLLER
# --> https://cloud.google.com/anthos-config-management/docs/how-to/config-controller-setup

gcloud anthos config controller create root-cluster --network=default --location=us-central1 --project=kcc-root 
gcloud anthos config controller list

export KUBECONFIG=$(pwd)/.kcc-kube.yaml   

gcloud container clusters get-credentials krmapihost-root-cluster --region us-central1 --project kcc-root
 
# PERMISSION

export SA_EMAIL="$(kubectl get ConfigConnectorContext -n config-control -o jsonpath='{.items[0].spec.googleServiceAccount}' 2> /dev/null)"

gcloud projects add-iam-policy-binding "kcc-root" \
    --member "serviceAccount:${SA_EMAIL}" \
    --role "roles/owner" \
    --project "kcc-root"

# CNRM CLUSTER MODE
gcloud iam service-accounts create kcc-sa --project "kcc-root"
gcloud iam service-accounts add-iam-policy-binding \
    kcc-sa@kcc-root.iam.gserviceaccount.com \
    --member="serviceAccount:kcc-root.svc.id.goog[cnrm-system/cnrm-controller-manager]" \
    --role="roles/iam.workloadIdentityUser"

gcloud projects add-iam-policy-binding "kcc-root" \
    --member="serviceAccount:kcc-sa@kcc-root.iam.gserviceaccount.com" \
    --role="roles/owner"

gcloud projects add-iam-policy-binding "223199570693" \
    --member="serviceAccount:kcc-sa@kcc-root.iam.gserviceaccount.com" \
    --role="roles/resourcemanager.folderAdmin"