#!/bin/bash

delete_gke_cfk_lb_objects() {
    local id="$1"
    local healthcheckname=""

    # lookup healthcheck name
    healthchecklink=$(gcloud compute --project="${PROJECT}" target-pools describe "${id}" --format='json' | jq -r '.healthChecks' | jq -r '.[0]')

    # check if healthcheck covers multiple target pools, if only 1 target pool, we can delete it
    echo "LOOKUP healthcheck ${healthchecklink}"
    targetpoolcount=$(gcloud compute --project="${PROJECT}" target-pools list --format='json' --filter="region:( ${REGION} )" --filter="healthChecks:( ${healthchecklink} )" | jq length)
    if [[ $targetpoolcount == 1 ]] ; then
        healthcheckname=$(gcloud --project="${PROJECT}" compute http-health-checks list --filter="selfLink: ( ${healthchecklink} )" --format="json" | jq -r '.[]' | jq -r '.name')
    fi

    echo "DELETING forwarding-rule ${id}"
    if [[ -z "$DRYRUN" ]] ; then 
        gcloud compute --project="${PROJECT}" forwarding-rules delete "${id}" --region=${REGION} --quiet
    fi
    echo "DELETING target-pool ${id}"
    if [[ -z "$DRYRUN" ]] ; then
        gcloud compute --project="${PROJECT}" target-pools     delete "${id}" --region=${REGION} --quiet
    fi

    if [[ ! -z $healthcheckname ]] ; then
        echo "DELETING healthcheck ${healthcheckname}"
        if [[ -z "$DRYRUN" ]] ; then
            gcloud compute --project="${PROJECT}" http-health-checks delete "${healthcheckname}" --quiet
        fi
    fi
}

# lookup all target pools for provided cluster
for target in $(gcloud compute --project="${PROJECT}" target-pools list --format='json' --filter="region:( ${REGION} )" --filter="instances:( gke-${GKE_CLUSTER_NAME} )" | jq -r '.[] ' | jq -r '.name') ; do
    # collect the target pools that don't have healthy instances
    if ! $(gcloud compute --project="${PROJECT}" target-pools get-health "${target}" --region="${REGION}" 2>/dev/null >/dev/null); then
        delete_gke_cfk_lb_objects "$target"
        break
    fi
done
