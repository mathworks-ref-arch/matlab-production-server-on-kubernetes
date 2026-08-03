# MATLAB Production Server in Kubernetes

The ```matlab-production-server-on-kubernetes``` repository contains utilities for using MATLAB® Production Server™ in a Kubernetes® cluster.  

## Introduction

This guide helps you automate the process of running MATLAB
Production Server in a Kubernetes cluster by using a Helm® chart. The chart is a collection of YAML
files that define the resources you need to deploy MATLAB Production
Server in Kubernetes. Once you deploy the server, you can manage it using the
`kubectl` command-line tool.

For more information about MATLAB Production Server, see the [MATLAB Production Server documentation](https://www.mathworks.com/help/mps/index.html).

For more information about Kubernetes, see the [Kubernetes documentation](https://kubernetes.io/docs/home/).

## Contents
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Deployment Steps](#deployment-steps)
  1. [Clone GitHub Repository](#step-1-clone-github-repository-that-contains-helm-chart)
  2. [Pull Container Images](#step-2-pull-container-images-for-matlab-production-server-and-matlab-runtime)
  3. [Upload Container Images to Private Registry](#step-3-upload-container-images-to-private-registry) *(optional)*
  4. [Provide Mapping for Deployable Archives](#step-4-provide-mapping-for-deployable-archives)
  5. [Install Helm Chart](#step-5-install-helm-chart)
- [Common Tasks](#common-tasks)
  - [Upload Deployable Archive](#upload-deployable-archive)
  - [Manage External Access Using Ingress](#manage-external-access-using-ingress)
  - [Scale the Deployment](#scale-the-deployment)
  - [Test Client Access Using Port Forwarding](#test-client-access-using-port-forwarding)
  - [Update Server Configuration Properties](#update-server-configuration-properties)
  - [Delete Your Deployment](#delete-your-deployment)
- [Troubleshooting](#troubleshooting)
  - [View Logs](#view-logs)
  - [Check Deployment Status](#check-deployment-status)
  - [Restart Pods](#restart-pods)
  - [Common Issues](#common-issues)
  - [kubectl Quick Reference](#kubectl-quick-reference)
- [Execute Deployed Functions](#execute-deployed-functions)
- [Request Enhancements](#request-enhancements)
- [Get Technical Support](#get-technical-support)

## Requirements
Before starting, you need the following:

*   MATLAB Production Server license that meets the following conditions:
    * Linked to a [MathWorks Account](https://www.mathworks.com/mwaccount/).
    * Concurrent license type. To check your license type, see [MathWorks License Center](https://www.mathworks.com/licensecenter/). 
    * Configured to use a network license manager. The license manager must be accessible from the Kubernetes cluster where you deploy MATLAB Production Server but must not be installed in the cluster.
*  Network access to the MathWorks container registry, containers.mathworks.com    
* [Git™](https://git-scm.com/)
* [Docker®](https://www.docker.com/)
* Running [Kubernetes](https://kubernetes.io/) cluster that meets the following conditions: 
    * Uses Kubernetes version 1.33 or later.
    * Each MATLAB Production Server container in the Kubernetes cluster requires at least 1 CPU core and 2 GiB RAM.
* [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) command-line tool that can access your Kubernetes cluster
* [Helm](https://helm.sh/) package manager to install Helm charts that contain preconfigured Kubernetes resources for MATLAB Production Server
    * Uses Helm version v3.17 or later.

⚠️  Since R2026b, MATLAB Runtime no longer includes the Java® Runtime Environment (JRE™).
If your MATLAB code requires Java to run, explore your options [here](https://www.mathworks.com/matlab-runtime-openjdk).

If you do not have a license, please contact your MathWorks representative [here](https://www.mathworks.com/company/aboutus/contact_us/contact_sales.html) or [request a trial license](https://www.mathworks.com/campaigns/products/trials.html?prodcode=PR). 

## Quick Start
The Quick Start option is recommended for the following cases:
* You are deploying MATLAB Production Server R2024b or newer.
* You don't require significant changes to the Helm chart.
* For CI/CD workflows, we recommend that you retag and cache docker images in your private container registry.

The Quick Start option only requires you to download a single file, rather than cloning the full GitHub repository. For more complex workflows, use the [Deployment Steps](#deployment-steps).

1. Download the `values-overrides.yaml` file containing configuration options that apply across all release deployments from the MATLAB Production Server on Kubernetes GitHub repository. You can use the cURL command below or click the "Download Raw File" icon.
    ```
    curl -O https://raw.githubusercontent.com/mathworks-ref-arch/matlab-production-server-on-kubernetes/main/values-overrides.yaml
    ```

2. Complete the steps in [Provide Mapping for Deployable Archives](#step-4-provide-mapping-for-deployable-archives).

3. Before installing the chart, first set parameters that state your agreement to the MathWorks cloud reference architecture license and specify the address of the network license manager. In the top-level values-overrides.yaml file, set these parameters:

    To accept the license terms, set global > agreeToLicense to "yes".
    To specify the address of the license server, set global > licenseServer using the format port_number@host. 

    Next, install the Helm chart for MATLAB Production Server R2026b by using the following `helm install` command:
    ```
    helm install -f <path/to/values-overrides.yaml> [-n <k8s-namespace>] --generate-name oci://containers.mathworks.com/matlab-prodserver-k8s --version 1.5.0
    ```

4. After the deployment is complete, upload the MATLAB Production Server deployable archive to your network file server or Azure file share. All users must have read permission to the deployable archive.

> **Note:** After completing Quick Start, the following sections still apply:
> - [Common Tasks](#common-tasks) (Ingress, port forwarding, configuration updates)
>
> The following sections are only needed for the full [Deployment Steps](#deployment-steps) workflow and can be skipped:
> - Clone GitHub Repository
> - Pull Container Images
> - Upload Container Images to Private Registry

## Deployment Steps
### Step 1: Clone GitHub® Repository that Contains Helm Chart
The MATLAB Production Server on Kubernetes GitHub repository contains Helm charts that reference Ubuntu-based Docker container images for MATLAB Production Server deployment.

1. Clone the MATLAB Production Server on Kubernetes GitHub repository to your machine.
    ```
    git clone https://github.com/mathworks-ref-arch/matlab-production-server-on-kubernetes.git
    ```
    This repository includes Helm chart folders for each supported MATLAB Production Server release and a `values-overrides.yaml` file containing configuration options that apply across all release deployments.

2. Navigate to the Helm chart folder for the release you want to use. Replace `<release>` with the release version, for example, `R2026b`.
    ```
    cd matlab-production-server-on-kubernetes/releases/<release>/matlab-prodserver
    ```
    This folder contains two files that together define the Helm chart used to deploy MATLAB Production Server.
    * `Chart.yaml` &mdash; Contains metadata about the Helm chart.
    * `values.yaml` &mdash; Contains release-specific configuration options for the deployment.

### Step 2: Pull Container Images for MATLAB Production Server and MATLAB Runtime

1. Pull the container image for MATLAB Production Server to your machine.

    ```
    docker pull containers.mathworks.com/matlab-production-server:<release-tag>
    ```
    * `containers.mathworks.com` is the name of the container registry.
    * `matlab-production-server` is the name of the repository.
    * `<release-tag>` is the tag name of the MATLAB Production Server release, for example, `r2026b`.

    The `values.yaml` file specifies these values in the `productionServer` section, in the `registry`, `repository`, and `tag` variables, respectively. 

2. Pull the container image for MATLAB Runtime to your machine.

    ```
    docker pull containers.mathworks.com/matlab-runtime:<release-tag>
    ```
    * `containers.mathworks.com` is the name of the container registry.
    * `matlab-runtime` is the name of the repository.
    * `<release-tag>` is the tag name of the MATLAB Runtime release. Update this value to the release version of the MATLAB Runtime you are using, for example, `r2026b`. MATLAB Production Server supports MATLAB Runtime versions up to six releases back from the MATLAB Production Server version you are using.

    The `values.yaml` file specifies these values in the `matlabRuntime` section, in the `registry`, `repository`, and `tag` variables, respectively.  

### Step 3: Upload Container Images to Private Registry
After you pull the MATLAB Production Server and MATLAB Runtime container images to your system, upload them to a private container registry that your Kubernetes cluster can access.

1. Tag the images with information about your private registry by using [docker tag](https://docs.docker.com/engine/reference/commandline/tag/).

2. Push the images to your private registry by using [docker push](https://docs.docker.com/engine/reference/commandline/push/).

3. In the `values-overrides.yaml` file, set the `global` > `images` > `registry` variable to the name of your private registry.

4. If your private registry requires authentication, create a Kubernetes Secret that your pod can use to pull the image from the private registry. For more information, see [Pull an Image from a Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) in the Kubernetes documentation. 

5. In the `values-overrides.yaml` file, set the `global` > `images` > `pullSecret` variable to the name of the Kubernetes Secret you created.

### Step 4: Provide Mapping for Deployable Archives
Deploying MATLAB Production Server requires a running Kubernetes cluster. From the Kubernetes cluster that you use for MATLAB Production Server, provide a mapping from the storage location where you want to store MATLAB Production Server deployable archives (CTF files) to a storage resource in your cluster. You can store the deployable archives on the network file system or on the cloud. After the MATLAB Production Server deployment is complete, the deployable archives that you store in the mapped location are automatically deployed to the server.

To specify mapping, in the top-level `values-overrides.yaml` file, under `matlabProductionServerSettings`, set values for the variables under `autoDeploy`.

To specify the storage location for storing deployable archives, under `autoDeploy`, set `volumeType` to one of the following:

* `"nfs"` &mdash; Store archives to a location on the network file system. Specify values for the `server` and `path` variables. Specify the hostname of your NFS server in the `server` variable and the location of your deployable archives in the `path` variable. For more information about the `nfs` option, see [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/) in the Kubernetes documentation.
* `"pvc"` &mdash; Store archives to a persistent volume by using a Persistent Volume Claim. Specify a value for the `claimName` variable. To use this option, you must have an existing Persistent Volume Claim that is already bound to its underlying storage volume.  
* `"azurefileshare"`  &mdash; Store archives to a file share using Azure™ Files. Specify values for `shareName` and `secretName` variables. To use this option, you must have an existing file share and Kubernetes secret used to access the file share. For details about Azure file shares, see [Create and use a volume with Azure Files in Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/azure-csi-files-storage-provision) in the Azure documentation.

The default value for `volumeType` is `"empty"`. However, to access deployable archives, you must set `volumeType` to one of the previously described options. 

### Step 5: Install Helm Chart
The Helm chart for MATLAB Production Server is located in the repository in `/releases/<release>/matlab-prodserver`. To install the Helm chart for the MATLAB Production Server release that you want to deploy, use the [helm install](https://helm.sh/docs/helm/helm_install/) command. Install the chart in a separate Kubernetes namespace. For more information about Kubernetes namespaces, see [Share a Cluster with Namespaces](https://kubernetes.io/docs/tasks/administer-cluster/namespaces/) in the Kubernetes documentation.

Before installing the chart, first set parameters that state your agreement to the MathWorks cloud reference architecture license and specify the address of the network license manager. In the top-level `values-overrides.yaml` file, set these parameters:

- To accept the license terms, set `global` > `agreeToLicense` to `"yes"`.
- To specify the address of the license server, set `global` > `licenseServer` using the format `port_number@host`. 

Then, install the Helm chart for MATLAB Production Server by using the `helm install` command:

```
helm install -f <path/to/values-overrides.yaml> [-n <k8s-namespace>] --generate-name <path/to/chart directory>
```

After you install the chart, the pod takes a few minutes to initialize because the installation consists of approximately 10 GB of container images.

The deployment name is `deployment.apps/matlab-production-server`. You can use the [kubectl get](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#get) command to confirm that MATLAB Production Server is running. The name of the service that enables network access to the pod is `service/matlab-production-server`.

## Common Tasks
The following tasks can be performed at any time after the initial deployment is complete. They apply to both [Quick Start](#quick-start) and full [Deployment Steps](#deployment-steps) workflows.

### Upload Deployable Archive
After the deployment is complete, upload the MATLAB Production Server deployable archive to your network file server or Azure file share. All users must have read permission to the deployable archive.

### Manage External Access Using Ingress
You can manage access to MATLAB Production Server by specifying an [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) controller. The Ingress controller also acts as a load balancer and is the preferred way to expose MATLAB Production Server services in production. This reference architecture assumes that you have an existing Ingress controller already running on the Kubernetes cluster. Specify controller options in the `ingressController` variable of the `values-overrides.yaml` file or use the default values.
You can enable inbound HTTPS connections by using an Ingress controller TLS termination.

### Scale the Deployment
You can scale MATLAB Production Server in two ways:

* **Number of pods** (horizontal scaling) &mdash; Increase the number of pod replicas by using [kubectl scale](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#scale). For example, to scale to 4 pods:
    ```
    kubectl scale deployment matlab-production-server --namespace=<k8s-namespace> --replicas=4
    ```
* **Number of workers per pod** &mdash; Set the `--num-workers` option in the `values-overrides.yaml` file under `matlabProductionServerSettings` to control how many MATLAB workers run inside each pod.

#### Best Practices and Restrictions

* **License limits** &mdash; The total number of workers across all pods cannot exceed your MATLAB Production Server license seat count. For example, if you have a 4-seat license and configure 2 workers per pod, you can run at most 2 pods.
* **Resource requirements** &mdash; As of R2025a, the default configuration creates 2 workers per pod, with CPU and memory requirements based on existing product recommendations. This results in a resource request of approximately 1 CPU per pod. When scaling the number of pods, ensure your Kubernetes cluster has sufficient resources to accommodate the total CPU and memory requirements, as it is easy to exceed overall cluster resource limits.
* **Choosing between more pods vs. more workers** &mdash; More pods provide better fault isolation and allow Kubernetes to distribute load across nodes. More workers per pod reduces scheduling overhead but increases per-pod resource requirements.

### Test Client Access Using Port Forwarding
To test that the deployment was successful, first, use *port forwarding* to map the port that is running MATLAB Production Server inside the cluster (default = 9910) to a port that is available outside the cluster.

To add port forwarding, use the [kubectl port-forward](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#port-forward) command. This example maps the default internal port 9910 to port 19910. Clients from any IP address can then access the `svc/matlab-production-server` service from outside the cluster by connecting to port 19910.
```
kubectl port-forward --address 0.0.0.0 --namespace=<k8s-namespace> svc/matlab-production-server 19910:9910 &
```

Then, test the server connection by using a `curl` command. This example tests the connection to the health check API by accessing the mapped port (19910) on the localhost. If `curl` is installed on a different machine, replace `localhost` with the hostname for that machine.
```
curl localhost:19910/api/health
```
Sample JSON output for a successful connection: `{"status": "ok"}`

### Update Server Configuration Properties
The default server configuration properties are stored in a [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) located at `/releases/<release>/matlab-prodserver/templates/mps-2-configmap.yaml`. To update server properties, you can update `mps-2-configmap.yaml` or `values.yaml`. To apply the updated server properties to the deployment, see [helm upgrade](https://helm.sh/docs/helm/helm_upgrade/) and [kubectl scale](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#scale).


### Delete Your Deployment
To remove all Kubernetes resources created by the Helm chart (including the deployment, pods, service, and configmap), use `helm uninstall`.

First, find your release name by running `helm list` in the namespace containing your deployment:
```
helm list --namespace=<k8s-namespace>
```

Example output:
```
NAME                                 NAMESPACE   REVISION   UPDATED                                STATUS     CHART                         APP VERSION
matlab-prodserver-k8s-1749484754     default     1          2025-06-09 11:59:15.8636828 -0400 EDT  deployed   matlab-prodserver-k8s-1.2.0   R2025a
```

Then, uninstall the release:
```
helm uninstall <release-name> --namespace=<k8s-namespace>
```

For example:
```
helm uninstall matlab-prodserver-k8s-1749484754 --namespace=<k8s-namespace>
```

> **Note:** The release name is auto-generated when you use `--generate-name` during installation (as in both the Quick Start and full Deployment Steps). It is not the same as the MATLAB release version (e.g., R2025a). Use `helm list` to find it.

## Troubleshooting

### View Logs
To view MATLAB Production Server logs, query the pod using `kubectl logs`:
```
kubectl get pods --namespace=<k8s-namespace>
kubectl logs <podname> --namespace=<k8s-namespace>
```

Example output:
```
'/opt/mpsinstance' STOPPED
1 [2025.06.09 16:01:29.863738] [information] Starting master (pid = 21)
2 [2025.06.09 16:01:29.864041] [information] Global locale: en_US
3 [2025.06.09 16:01:29.864067] [information] Global encoding: US-ASCII
```

If the pod contains multiple containers, you may need to specify the container name:
```
kubectl logs <podname> -c mps --namespace=<k8s-namespace>
```

### Check Deployment Status
Use `kubectl get all` to view all resources in your deployment namespace:
```
kubectl get all --namespace=<k8s-namespace>
```

Example output:
```
NAME                                            READY   STATUS    RESTARTS   AGE
pod/matlab-production-server-5b7cb74fd9-h5tgh   1/1     Running   0          4m35s

NAME                               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/matlab-production-server   ClusterIP   10.106.203.19   <none>        9910/TCP   4d1h

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/matlab-production-server   1/1     1            1           4d1h
```

To get detailed information about a specific pod, including events and error messages:
```
kubectl describe pod <podname> --namespace=<k8s-namespace>
```

You can also check the server health using the health check API (see [Test Client Access Using Port Forwarding](#test-client-access-using-port-forwarding)).

### Restart Pods
If a pod is stuck in an error state after the root cause has been resolved, you can trigger it to reinitialize by deleting it. The deployment's replica set automatically creates a replacement pod.

To restart a single pod:
```
kubectl delete pod <podname> --namespace=<k8s-namespace>
```

To restart all pods, scale the deployment to 0 and then back to the desired number:
```
kubectl scale deployment matlab-production-server --namespace=<k8s-namespace> --replicas=0
kubectl scale deployment matlab-production-server --namespace=<k8s-namespace> --replicas=<desired-count>
```

### Common Issues

#### License Errors
* MATLAB Production Server on Kubernetes requires a **concurrent** license.
* The license server must be reachable from the network within the Kubernetes cluster but must not be installed in the cluster.
* If the server has difficulty resolving the DNS for a license server specified by hostname, try using the license server's IP address instead (e.g., `27000@172.22.225.0` instead of `27000@MYLICENSEHOST`).
* Each pod requires enough license seats for all its workers. For example, with the default of 2 workers per pod, you need at least 2 license seats per pod.

For more information, see [How can I troubleshoot license errors when using MATLAB Production Server on Kubernetes?](https://www.mathworks.com/matlabcentral/answers/2183724-how-can-i-troubleshoot-license-errors-when-using-matlab-production-server-on-kubernetes)

#### Container Download Issues
If you encounter issues downloading container images, see [Why am I encountering issues downloading containers for my MATLAB Production Server Kubernetes deployment?](https://www.mathworks.com/matlabcentral/answers/659239)

#### Configuration Changes Not Taking Effect (R2024b and Earlier)
In R2024b and earlier, updating the configuration does not automatically trigger pods to restart. You must manually restart all pods after making configuration changes. This has been fixed in R2025a and later.

### kubectl Quick Reference
Most `kubectl` commands follow this pattern:
```
kubectl <action> <object-type> [object-name] --namespace=<k8s-namespace>
```

Common actions and examples:

| Command | Description |
|---------|-------------|
| `kubectl get pods` | List all pods |
| `kubectl get all` | List all resources |
| `kubectl describe pod <podname>` | Show detailed pod information |
| `kubectl logs <podname>` | View pod logs |
| `kubectl delete pod <podname>` | Delete (restart) a pod |
| `kubectl describe configmap matlab-production-server-config` | View server configuration |
| `helm list` | List deployed Helm releases |

> **Note:** All `kubectl` and `helm` commands are scoped to a namespace. If you do not specify `--namespace` (or `-n`), commands run in the `default` namespace. To change your default namespace, run:
> ```
> kubectl config set-context --current --namespace=<k8s-namespace>
> ```

## Execute Deployed Functions
To evaluate MATLAB functions deployed on the server, see [Client Programming](https://www.mathworks.com/help/mps/client-programming.html). Both synchronous and asynchronous request execution are supported.

## Request Enhancements

To suggest additional features or capabilities, see
[Request Reference Architectures](https://www.mathworks.com/products/reference-architectures/request-new-reference-architectures.html).

## Get Technical Support

If you require assistance, contact [MathWorks Technical Support](https://www.mathworks.com/support/contact_us.html).

## License

MATHWORKS CLOUD REFERENCE ARCHITECTURE LICENSE © 2026 The MathWorks, Inc.

