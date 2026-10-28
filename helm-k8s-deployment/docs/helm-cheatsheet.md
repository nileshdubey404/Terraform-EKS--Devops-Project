                helm upgrade frontend ./charts/frontend-chart \
                --install \
                -n development \
                -f values-dev.yaml \
                --set image.repository=${ECR_URI} \
                --set image.tag=${IMAGE_TAG}


# Step-by-Step Parameter Breakdown
# 1. helm upgrade
# What it does: Tells Helm to update an existing release.

# How it behaves: Helm looks for an existing release named backend in the target Kubernetes namespace and updates it to match the chart configuration provided.

# 2. backend
# What it does: The Release Name.

# How it behaves: This is the unique identifier Helm uses inside your Kubernetes cluster to track this specific deployment (e.g., helm list will show backend).

# 3. ./helm
# What it does: Path to the Helm Chart directory.

# How it behaves: Points to a local folder named helm containing the chart files (Chart.yaml, templates/, values.yaml).

# 4. --install (or -i)
# What it does: Acts as an "upsert" flag (upgrade or install).

# How it behaves: If the backend release does not exist, Helm creates a brand new installation instead of throwing an error. If it already exists, Helm performs a standard upgrade.

# 5. -f values-prod.yaml (or --values)
# What it does: Specifies an external values file for environment overrides.

# How it behaves: Overrides default settings in ./helm/values.yaml with production-specific settings defined in values-prod.yaml (e.g., database URLs, replica counts, memory/CPU limits).

# 6. --set image.repository=$ECR_REPOSITORY
# What it does: Overrides a specific configuration key dynamically from the command line or CI/CD environment variable.

# How it behaves: Sets the container image repository path using the $ECR_REPOSITORY environment variable (e.g., [123456789012.dkr.ecr.us-east-1.amazonaws.com/my-backend-app](https://123456789012.dkr.ecr.us-east-1.amazonaws.com/my-backend-app)).

# 7. --set image.tag=102
# What it does: Sets the exact container image tag to deploy.

# 8.-n development tell namespace where the helm chart will be deployed

# How it behaves: Tells Kubernetes to pull version 102 of your image. During an upgrade, changing this tag triggers a rolling update of your pods to the new image version.
_____________________________________________________________________________________________________________________________________________________
#  to install Helm
# sudo snap install helm --classic

-----------------------------------------------
1. Rollback to the Immediate Previous Version (Safest & Easiest)If you just deployed a broken 
version and want to go back exactly one step, you do not actually need a number. 
Helm has a built-in feature for this:bash
helm rollback "$SERVICE_NAME" 0
Use code with caution. How it works: Passing 0 tells Helm to automatically look up the previous 
revision and roll back to it.
2. Dynamically Target the Second-to-Last RevisionIf you want to bypass the current broken version 
and go back to the version before that, you can use this dynamic pipeline:bash
helm rollback "$SERVICE_NAME" $(helm history "$SERVICE_NAME" --output json | jq '.[-2].revision')
helm history ... --output json: Outputs the history in clean JSON format.
jq '.[-2].revision': Grabs the second-to-last item from the history array and extracts its 
revision number.
__________________________________________________________________________________
1. Restore the deleted folder
This restores any files or folders that you deleted from your local repository:bash
git restore .

2. Delete the newly created files
This permanently deletes all new, untracked files and folders that you accidentally added:bash
git clean -fd
_________________________________________________________________________________

