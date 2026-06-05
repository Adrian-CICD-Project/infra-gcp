######################################
# ENV TEST – GCP
######################################

# UWAGA: ustaw realne ID projektu GCP
project_id  = "devops-poc01-adrian"
region      = "europe-west1"
zone        = "europe-west1-b"
name_prefix = "devops-poc01"

# --- Artifact Registry (odpowiednik ACR) ---
registry_name = "adrian-java-app"

# --- Klastry GKE ---
gke_test_name = "devops-poc01-test"
gke_prod_name = "devops-poc01-prod"

# --- Węzły (Compute Engine) ---
node_machine_type = "e2-standard-2"
node_count        = 1
use_spot          = false # ustaw true dla Spot VM (maks. oszczędność)

# --- Auto-shutdown 18:00 ---
shutdown_cron     = "0 18 * * *"
schedule_timezone = "Europe/Warsaw"
