# CREATE KCC HOST PROJEC
# --> export CLOUDSDK_CORE_PROJECT=kcc-root 
export KCC_ROOT_PROJECT=kcc-root-01
export CLOUDSDK_CORE_PROJECT=$KCC_ROOT_PROJECT

gcloud projects create $KCC_ROOT_PROJECT 

# ENABLE SERVICES
gcloud services enable krmapihosting.googleapis.com \
    container.googleapis.com \
    cloudbilling.googleapis.com \
    cloudresourcemanager.googleapis.com --project=$KCC_ROOT_PROJECT

# CREATE VPC
gcloud compute networks create default --subnet-mode=auto --project=$KCC_ROOT_PROJECT

## FW RULES
gcloud compute firewall-rules create default-allow-interal --network default --allow tcp:22,tcp:3389,icmp --project=$KCC_ROOT_PROJECT
gcloud compute firewall-rules create allow-ssh --network default --source-ranges 35.235.240.0/20 --allow tcp:22 --project=$KCC_ROOT_PROJECT

# CREATE NAT ROUTER (TO ACCESS GITHUB)
gcloud compute routers create default-nat-router --network default --region us-central1 --project=$KCC_ROOT_PROJECT

gcloud compute routers nats create default-nat-config --router-region us-central1 --router default-nat-router \
--nat-all-subnet-ip-ranges --auto-allocate-nat-external-ips --project=$KCC_ROOT_PROJECT

## Test
gcloud compute ssh <KCC_HOST> --zone us-central1-f  --tunnel-through-iap --project=$KCC_ROOT_PROJECT 

# CREATE CONTROLLER
# --> https://cloud.google.com/anthos-config-management/docs/how-to/config-controller-setup

gcloud anthos config controller create root-cluster --network=default --location=us-central1 --project=$KCC_ROOT_PROJECT 
gcloud anthos config controller list

export KUBECONFIG=$(pwd)/.kcc-kube.yaml   

gcloud container clusters get-credentials krmapihost-root-cluster --region us-central1 --project=$KCC_ROOT_PROJECT 
 
# PERMISSION
export SA_EMAIL="$(kubectl get ConfigConnectorContext -n config-control -o jsonpath='{.items[0].spec.googleServiceAccount}' 2> /dev/null)"

gcloud projects add-iam-policy-binding $KCC_ROOT_PROJECT \
    --member "serviceAccount:${SA_EMAIL}" \
    --role "roles/owner" \
    --project=$KCC_ROOT_PROJECT 

# CNRM CLUSTER MODE
gcloud iam service-accounts create kcc-sa --project $KCC_ROOT_PROJECT 

gcloud iam service-accounts add-iam-policy-binding \
    kcc-sa@$KCC_ROOT_PROJECT.iam.gserviceaccount.com \
    --member="serviceAccount:$KCC_ROOT_PROJECT.svc.id.goog[cnrm-system/cnrm-controller-manager]" \
    --role="roles/iam.workloadIdentityUser"

gcloud projects add-iam-policy-binding $KCC_ROOT_PROJECT \
    --member="serviceAccount:kcc-sa@$KCC_ROOT_PROJECT.iam.gserviceaccount.com" \
    --role="roles/owner"

gcloud organizations add-iam-policy-binding "223199570693"  \
    --member="serviceAccount:kcc-sa@$KCC_ROOT_PROJECT.iam.gserviceaccount.com" \
    --role=roles/resourcemanager.folderAdmin

gcloud organizations add-iam-policy-binding "223199570693"  \
    --member="serviceAccount:kcc-sa@$KCC_ROOT_PROJECT.iam.gserviceaccount.com" \
    --role=roles/resourcemanager.projectCreator

# Note: To link Project resources to Cloud Billing accounts, 
# your Config Connector IAM service account must have roles/billing.user on the Cloud Billing account, 
# and the IAM service account must belong to a project with the Cloud Billing API enabled.

gcloud organizations add-iam-policy-binding "223199570693"  \
    --member="serviceAccount:kcc-sa@$KCC_ROOT_PROJECT.iam.gserviceaccount.com" \
    --role=roles/billing.user

# ACCESS TO CREATED SHARED VPC's
## TODO: IF SPLIT TO NONE-CLUSTER MODE, CAN BE SPLIT
gcloud organizations add-iam-policy-binding "223199570693"  \
    --member="serviceAccount:kcc-sa@$KCC_ROOT_PROJECT.iam.gserviceaccount.com" \
    --role=roles/compute.xpnAdmin