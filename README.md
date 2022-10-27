# MATLAB Production Server in Kubernetes

The ```matlab-production-server-on-kubernetes``` repository contains utilities for using MATLAB® Production Server™ in a Kubernetes® cluster.  

## Introduction

This guide helps you to automate the process of running MATLAB
Production Server in a Kubernetes cluster by using a Helm® chart. The chart is a collection of YAML
files that define the resources you need to deploy MATLAB Production
Server in Kubernetes. Once you deploy the server, you can manage it using the
`kubectl` command-line tool. 

For more information about MATLAB Production Server, see the [MATLAB Production Server documentation](https://www.mathworks.com/help/mps/index.html).

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
    * Uses Kubernetes version 1.21 or later
    * Each MATLAB Production Server container in the Kubernetes cluster requires at least 1 CPU core and 2GiB RAM.
* [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) command-line tool that can access your Kubernetes cluster
* [Helm](https://helm.sh/) package manager to install Helm charts that contain preconfigured Kubernetes resources for MATLAB Production Server

## Deployment Steps
### Clone GitHub® Repository that Contains Helm Chart
The MATLAB Production Server on Kubernetes GitHub repository contains Helm charts that reference Ubuntu-based Docker container images for MATLAB Production Server deployment.

1. Clone the [MATLAB Production Server on Kubernetes GitHub repository](https://github.com/mathworks-ref-arch/matlab-production-server-on-kubernetes) to your machine.
```
git clone https://github.com/mathworks-ref-arch/matlab-production-server-on-kubernetes.git
```
2. Navigate to the folder that contains the Helm chart for the release that you want to use, for example, `R2022b`.
```
cd matlab-production-server-on-kubernetes/releases/<release>/matlab-prodserver
```

### Pull Container Images for MATLAB Production Server and MATLAB Runtime
1. Log in to the MathWorks container registry, `containers.mathworks.com`, using the credentials of your MathWorks account.
```
docker login containers.mathworks.com
```  

2. Pull the container image for MATLAB Production Server to your machine by specifying as input parameters the name of the container registry (`containers.mathworks.com`), name of the repository (`matlab-production-server`), and the release (for example, `r2022b`). 

The `values.yaml` file contains the values for these parameters. The `values.yaml` file is located in `/releases/<release>/matlab-prodserver` in the GitHub repository that you cloned earlier. In `values.yaml`, under the `productionServer` variable, locate the `registry`, `repository`, and `tag` variables. `registry` contains the the name of the container registry, `repository` contains the name of the repository, and `tag` contains the release. 
```
docker pull containers.mathworks.com/matlab-production-server:<release>
```

3. Pull the container image for MATLAB Runtime to your machine by specifying as input parameters the name of the container registry (`containers.mathworks.com`), name of the repository (`matlab-runtime`), and the release (for example, `r2022b`). 

The `values.yaml` file contains the values for these parameters. The `values.yaml` file is located in `/releases/<release>/matlab-prodserver` in the GitHub repository that you cloned earlier. In `values.yaml`, under the `matlabRuntime` variable, locate the `registry`, `repository`, and `tag` variables. `registry` contains the the name of the container registry, `repository` contains the name of the repository, and `tag` contains the release.

```
docker pull containers.mathworks.com/matlab-runtime:<release>
```
### Upload Container Images for MATLAB Production Server and MATLAB Runtime to Private Registry
After you pull the MATLAB Production Server and MATLAB Runtime container images to your system, upload them to a private container registry that your Kubernetes cluster can access.

1. Tag the images with information about your private registry. For details, see [docker tag](https://docs.docker.com/engine/reference/commandline/tag/).

2. Push the images to your private registry. For details, see [docker push](https://docs.docker.com/engine/reference/commandline/push/).

3. In the GitHub repository that you cloned earlier, update the `values.yaml` file located in `/releases/<release>/matlab-prodserver` with the name of your private registry. To do so, update the value of the `registry` variable nested under `productionServer` and `matlabRuntime` variables.

4. If your private registry requires authentication, create a Kubernetes Secret that your pod can use to pull the image from the private registry. For more information, see [Pull an Image from a Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) on the Kubernetes website. 

### Provide Mapping for Deployable Archives
A running Kubernetes cluster is required for deploying MATLAB Production Server. From the Kubernetes cluster that you use for MATLAB Production Server, provide a mapping from the storage location where you want to store MATLAB Production Server deployable archives (CTF files) to a storage resource in your cluster. You can store the deployable archives on the network file system or on the cloud. After the MATLAB Production Server deployment is complete, the deployable archives that you store in the mapped location are automatically deployed to the server.

To specify mapping, in the `values.yaml` file, under `matlabProductionServerSettings`, set values for the variables under `autoDeploy`.

- To specify a location on the network file system for storing deployable archives, under `autoDeploy`, set `volumeType` to `"nfs"` and specify values for `server` and `path` variables. 

- To specify Azure™ file share as the storage location for deployable archives, under `autoDeploy`, set `volumeType` to `"azurefileshare"` and specify values for `shareName` and `secretName` variables. This assumes that you have already created the file share and created a Kubernetes secret to access the file share. For more information about using an Azure file share, see [Azure documentation](https://docs.microsoft.com/en-us/azure/aks/azure-files-volume).

The default value for `volumeType` is `"empty"`. However, to access deployable archives, you must set it to either `"nfs"` or `"azurefileshare"`. 

### Install Helm Chart
The Helm chart for MATLAB Production Server is located in the repository in `/releases/<release_number>/matlab-prodserver`. Use the [helm install](https://helm.sh/docs/helm/helm_install/) command to install the Helm chart for the MATLAB Production Server release that you want to deploy. It is recommended that you install the chart in a separate Kubernetes namespace. For more information about Kubernetes namespaces, see the Kubernetes documentation [Share a Cluster with Namespaces](https://kubernetes.io/docs/tasks/administer-cluster/namespaces/).

To install the chart, you must set parameters that state your agreement to the MathWorks cloud reference architecture license and specify the address of the network license manager. You can set the parameters either in the `values.yaml` file in the chart or when running `helm install`.

- To accept the license terms, set the `global.agreeToLicense` parameter to `Yes`.  
- To specify the address of the license server, set the `global.licenseServer` parameter in the format `port_number@host`. 

For example, this sample `helm install` command installs the Helm chart for MATLAB Production Server:

```
helm install [-n <k8s-namespace>] --generate-name <path/to/chart> --set global.agreeToLicense=Yes --set global.licenseServer=<port_number@host>
```

After you install the chart, the pod takes a few minutes to initialize because the installation consists of approximately 10 GB of container images.

The deployment name is `deployment.apps/matlab-production-server`. You can use the [kubectl get](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#get) command to confirm that MATLAB Production Server is running. The name of the service that enables network access to the pod is `service/matlab-production-server`.

### Upload Deployable Archive
After the deployment is complete, upload the MATLAB Production Server deployable archive to your network file server or Azure file share. All users must have read permission to the deployable archive.

### Add Port Forwarding
 By default, the server runs on port 9910 inside the cluster. If you want the server to be accessible from outside the cluster, add port forwarding that maps the internal port 9910 to a port that is available outside the cluster. To add port forwarding, you can use the `kubectl` command or the [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) Kubernetes API object.

* This sample `kubectl` command allows the service, `svc/matlab-production-server`, to accept connections from any client and maps the port 9910 inside the cluster to port 19910 available outside the cluster: 

 ```
 kubectl port-forward --address 0.0.0.0 --namespace=<k8s-namespace> svc/matlab-production-server 19910:9910 &
```

* To use Ingress, specify values in the `ingressController` variable in the `values.yaml` file or use the default values.

### Update Server Configuration Properties
The default server configuration properties are stored in a [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) located at `/releases/<release_number>/matlab-prodserver/templates/mps-2-configmap.yaml`. To update server properties, you can update `mps-2-configmap.yaml` or `values.yaml`. To apply the updated server properties to the deployment, see [helm upgrade](https://helm.sh/docs/helm/helm_upgrade/) and [kubectl scale](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#scale).

## Execute Deployed Functions
To evaluate MATLAB functions deployed on the server, see [Client Programming](https://www.mathworks.com/help/mps/client-programming.html). Starting in R2022a, asynchronous request execution is supported, in addition to existing support for synchronous request execution.

## Request Enhancements

To suggest additional features or capabilities, see
[Request Reference Architectures](https://www.mathworks.com/products/reference-architectures/request-new-reference-architectures.html).

## Get Technical Support

If you require assistance, contact [MathWorks Technical Support](https://www.mathworks.com/support/contact_us.html).

## License

MATHWORKS CLOUD REFERENCE ARCHITECTURE LICENSE © 2022 The MathWorks, Inc.

