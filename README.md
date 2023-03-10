# MATLAB Production Server in Kubernetes

The ```matlab-production-server-on-kubernetes``` repository contains utilities for using MATLAB® Production Server™ in a Kubernetes® cluster.  

## Introduction

This guide helps you to automate the process of running MATLAB
Production Server in a Kubernetes cluster by using a Helm® chart. The chart is a collection of YAML
files that define the resources you need to deploy MATLAB Production
Server in Kubernetes. Once you deploy the server, you can manage it using the
`kubectl` command-line tool. 

For more information about MATLAB Production Server, see the [MATLAB Production Server documentation](https://www.mathworks.com/help/mps/index.html).

For more information about Kubernetes, see the [Kubernetes documentation](https://kubernetes.io/docs/home/).

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
    * Uses Kubernetes version 1.24 or later
    * Each MATLAB Production Server container in the Kubernetes cluster requires at least 1 CPU core and 2GiB RAM.
* [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) command-line tool that can access your Kubernetes cluster.
* [Helm](https://helm.sh/) package manager to install Helm charts that contain preconfigured Kubernetes resources for MATLAB Production Server.

## Deployment Steps
### Clone GitHub® Repository that Contains Helm Chart
The MATLAB Production Server on Kubernetes GitHub repository contains Helm charts that reference Ubuntu-based Docker container images for MATLAB Production Server deployment.

1. Clone the MATLAB Production Server on Kubernetes GitHub repository to your machine.
    ```
    git clone https://github.com/mathworks-ref-arch/matlab-production-server-on-kubernetes.git
    ```
2. Navigate to the Helm chart folder for the release you want to use. Replace `<release>` with the release version, for example, `R2023a`.
    ```
    cd matlab-production-server-on-kubernetes/releases/<release>/matlab-prodserver
    ```
    This folder contains two files that together define the Helm chart used to deploy MATLAB Production Server.
    * `Chart.yaml` &mdash; Contains metadata about the Helm chart.
    * `values.yaml` &mdash; Contains configuration options for the deployment.

### Pull Container Images for MATLAB Production Server and MATLAB Runtime
1. Log in to the MathWorks container registry, `containers.mathworks.com`, using the credentials of your MathWorks account.

    ```
    docker login containers.mathworks.com
    ```

2. Pull the container image for MATLAB Production Server to your machine.

    ```
    docker pull containers.mathworks.com/matlab-production-server:<release-tag>
    ```
    * `containers.mathworks.com` is the name of the container registry.
    * `matlab-production-server` is the name of the repository.
    * `<release-tag>` is the tag name of the MATLAB Production Server release, for example, `r2023a`.

    The `values.yaml` file specifies these values in the `productionServer` section, in the `registry`, `repository`, and `tag` variables, respectively. 

3. Pull the container image for MATLAB Runtime to your machine.

    ```
    docker pull containers.mathworks.com/matlab-runtime:<release-tag>
    ```
    * `containers.mathworks.com` is the name of the container registry.
    * `matlab-runtime` is the name of the repository.
    * `<release-tag>` is the tag name of the MATLAB Runtime release. Update this value to the release version of the MATLAB Runtime you are using, for example, `r2023a`. MATLAB Production Server supports MATLAB Runtime versions up to six releases back from the MATLAB Production Server version you are using.

    The `values.yaml` file specifies these values in the `matlabRuntime` section, in the `registry`, `repository`, and `tag` variables, respectively.  

### Upload Container Images to Private Registry
After you pull the MATLAB Production Server and MATLAB Runtime container images to your system, upload them to a private container registry that your Kubernetes cluster can access.

1. Tag the images with information about your private registry by using [docker tag](https://docs.docker.com/engine/reference/commandline/tag/).

2. Push the images to your private registry by using [docker push](https://docs.docker.com/engine/reference/commandline/push/).

3. In the `values.yaml` file, set the `productionServer` > `registry` and `matlabRuntime` > `registry` variables to the name of your private registry.

4. If your private registry requires authentication, create a Kubernetes Secret that your pod can use to pull the image from the private registry. For more information, see [Pull an Image from a Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) in the Kubernetes documentation. 

### Provide Mapping for Deployable Archives
Deploying MATLAB Production Server requires a running Kubernetes cluster. From the Kubernetes cluster that you use for MATLAB Production Server, provide a mapping from the storage location where you want to store MATLAB Production Server deployable archives (CTF files) to a storage resource in your cluster. You can store the deployable archives on the network file system or on the cloud. After the MATLAB Production Server deployment is complete, the deployable archives that you store in the mapped location are automatically deployed to the server.

To specify mapping, in the `values.yaml` file, under `matlabProductionServerSettings`, set values for the variables under `autoDeploy`.

To specify the storage location for storing deployable archives, under `autoDeploy`, set `volumeType` to one of the following:

* `"nfs"` &mdash; Store archives to a location on the network file system. Specify values for the `server` and `path` variables.
* `"pvc"` &mdash; Store archives to a persistent volume by using a Persistent Volume Claim. Specify a value for the `claimName` variable. To use this option, you must have an existing Persistent Volume Claim that is already bound to its underlying storage volume.  
* `"azurefileshare"`  &mdash; Store archives to a file share using Azure™ Files. Specify values for `shareName` and `secretName` variables. To use this option, you must have an existing file share and Kubernetes secret used to access the file share. For details about Azure file shares, see [Create and use a volume with Azure Files in Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/azure-csi-files-storage-provision) in the Azure documentation.

The default value for `volumeType` is `"empty"`. However, to access deployable archives, you must set `volumeType` to one of the previously described options. 

### Install Helm Chart
The Helm chart for MATLAB Production Server is located in the repository in `/releases/<release>/matlab-prodserver`. To install the Helm chart for the MATLAB Production Server release that you want to deploy, use the [helm install](https://helm.sh/docs/helm/helm_install/) command. Install the chart in a separate Kubernetes namespace. For more information about Kubernetes namespaces, see [Share a Cluster with Namespaces](https://kubernetes.io/docs/tasks/administer-cluster/namespaces/) in the Kubernetes documentation.

To install the chart, you must set parameters that state your agreement to the MathWorks cloud reference architecture license and specify the address of the network license manager. You can set the parameters either in the `values.yaml` file in the chart or when running `helm install`.

- To accept the license terms, set the `global.agreeToLicense` parameter to `Yes`.  
- To specify the address of the license server, set the `global.licenseServer` parameter in the format `port_number@host`. 

For example, this `helm install` command installs the Helm chart for MATLAB Production Server:

```
helm install [-n <k8s-namespace>] --generate-name <path/to/chart> --set global.agreeToLicense=Yes --set global.licenseServer=<port_number@host>
```

After you install the chart, the pod takes a few minutes to initialize because the installation consists of approximately 10 GB of container images.

The deployment name is `deployment.apps/matlab-production-server`. You can use the [kubectl get](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#get) command to confirm that MATLAB Production Server is running. The name of the service that enables network access to the pod is `service/matlab-production-server`.

### Upload Deployable Archive
After the deployment is complete, upload the MATLAB Production Server deployable archive to your network file server or Azure file share. All users must have read permission to the deployable archive.


### Manage External Access Using Ingress
You can manage access to MATLAB Production Server by specifying an [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/Ingress) controller. The Ingress controller also acts as a load balancer and is the preferred way to expose MATLAB Production Server services in production. This reference architecture assumes that you have an existing Ingress controller already running on the Kubernetes cluster. Specify controller options in the `ingressController` variable of the `values.yaml` file or use the default values.

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


## Execute Deployed Functions
To evaluate MATLAB functions deployed on the server, see [Client Programming](https://www.mathworks.com/help/mps/client-programming.html). Starting in R2022a, asynchronous request execution is supported, in addition to existing support for synchronous request execution.

## Request Enhancements

To suggest additional features or capabilities, see
[Request Reference Architectures](https://www.mathworks.com/products/reference-architectures/request-new-reference-architectures.html).

## Get Technical Support

If you require assistance, contact [MathWorks Technical Support](https://www.mathworks.com/support/contact_us.html).

## License

MATHWORKS CLOUD REFERENCE ARCHITECTURE LICENSE © 2023 The MathWorks, Inc.

