GKE CFK Load balancer cleanup script
===================

This script will remove all load balancers created by Confluent for Kubernetes for a GKE cluster.
When configuring a external load balancer in CFK, it will create a forwarding rule, a target pool, and a health check.
If the GKE cluster is deleted without first removing the load balancers, they become orphaned.
The script will remove the forwarding rule, target pool, and health check.

<!-- toc -->

- [Usage](#usage)
  * [Configuration](#configuration)
  * [Running the script](#running-the-script)

<!-- tocstop -->

Usage
-----

### Configuration

Configuration is handled through environment variables:

- `PROJECT`: The GCE project that we should operate on
- `REGION`: The region where GCE resources should be probed
- `GKE_CLUSTER_NAME`: The Kube cluster name for verifying network resources against
- `DRYRUN`: Run script without executing deletes

### Running the script

Set the env variables and execute the script
```
PROJECT=myproject \
REGION=europe-west2 \
GKE_CLUSTER_NAME=cfk-mycluster \
./gke-cfk-lb-cleanup.sh
```

This script interates through gcloud target pools for the provided cluster, 
identifying which are no longer associated with valid instances.
