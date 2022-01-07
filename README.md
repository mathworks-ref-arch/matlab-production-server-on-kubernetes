# MATLAB Production Server in Kubernetes

The ```production-server-k8s``` repository contains utilities for using MATLAB ® Production Server™ in a Kubernetes ® cluster.  

## Introduction

This guide helps you to automate the process of running MATLAB
Production Server in a Kubernetes cluster by using a Helm ® chart. The chart is a collection of YAML
files that define the resources you need to deploy MATLAB Production
Server in Kubernetes. Once you deploy the server, you can manage it using the
`kubectl` command-line tool. 

For more information about MATLAB Production Server, see the [MATLAB Production Server documentation](https://www.mathworks.com/help/mps/index.html).

## Requirements
Before starting, you need the following:

*   MATLAB Production Server license that meets the following conditions:
    * Current on [Software Maintenance Service (SMS)](https://www.mathworks.com/services/maintenance.html).  
    * Linked to a [MathWorks Account](https://www.mathworks.com/mwaccount/).
    * Concurrent license type. To check your license type, see [MathWorks License Center](https://www.mathworks.com/licensecenter/). 
    * Configured to use a network license manager. The license manager must be accessible from the Kubernetes cluster where you deploy MATLAB Production Server but must not be installed in the cluster.
* [Kubernetes](https://kubernetes.io/)  version 1.21 or later
* [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) command-line tool that can access your Kubernetes cluster
* [Helm](https://helm.sh/) package manager to install Helm® charts that contain preconfigured Kubernetes resources for MATLAB Production Server
* Network access to MathWorks Docker® container registry: containers.mathworks.com

## Deployment Steps
### Provide Mapping for Deployable Archives
A running Kubernetes cluster is required for deploying MATLAB Production Server. When you create the Kubernetes cluster for MATLAB Production Server, provide a mapping from the storage location where you want to store MATLAB Production Server deployable archives (CTF files) to the `/share` directory on the nodes in your cluster. The storage location can be on the host machine or on the cloud. After the MATLAB Production Server deployment is complete, the deployable archives that you store in the mapped location are automatically deployed to the server.

Clone the repository available at https://github.com/mathworks-ref-arch/matlab-production-server-on-kubernetes. The repository contains Helm® chart which references container images based on Ubuntu for MATLAB Production Server deployment.

### Install Helm Chart
The Helm chart for MATLAB Production Server is located in the repository in `/releases/<release_number>/matlab-prodserver`. Use the [helm install](https://helm.sh/docs/helm/helm_install/) command to install the Helm chart for the MATLAB Production Server release that you want to deploy. It is recommended that you install the chart in a separate Kubernetes namespace.

To install the chart, you must set parameters that state your agreemenent to the MathWorks license terms and specify the address of the network license manager. The license file is located in `/releases/<release_number>/matlab-prodserver`. You can set the parameters either in the `values.yaml` file in the chart or when running `helm install`.

- To accept the license terms, set the `MathWorks.agreeToLicense` parameter to `Yes`.  
- To specify the address of the license server, set the `MathWorks.licenseServer` parameter in the format `port_number@host`. 

For example, this sample `helm install` command installs the Helm chart for MATLAB Production Server:

`helm install [-n <k8s-namespace>] --generate-name </releases/<release_number>/matlab-prodserver/> --set MathWorks.agreeToLicense=Yes --set MathWorks.licenseServer=<port_number@host>`

After you install the chart, the pod takes a few minutes to initialize because the installation consists of approximately 10 GB of container images.

The deployment name has the prefix `mps-deployment`. You can use the [kubectl get](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#get) command to confirm that MATLAB Production Server is running.

### Upload Deployable Archive
After the deployment is complete, upload the MATLAB Production Server deployable archive to the location on your host or on the cloud that you mapped to `/share` in the Kubernetes cluster.
*   All users must have `read` permission to the deployable archive.
*   The deployable archive must use the same MATLAB Runtime version as MATLAB Production Server.

### Add Port Forwarding
 By default, the server runs on port 9910 inside the cluster. If you want the server to be accessible from outside the cluster, add port forwarding that maps the internal port 9910 to a port that is available outside the cluster. You can use the [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) Kubernetes API object for port forwarding.

### Update Server Configuration Properties
The default server configuration properties are stored in a [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) located at `/releases/<release_number>/matlab-prodserver/templates/mps-2-configmap.yaml`. To update server properties, you can update `mps-2-configmap.yaml` or `values.yaml`. To apply the updated server properties to the deployment, see [helm upgrade](https://helm.sh/docs/helm/helm_upgrade/) and [kubectl scale](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#scale).

## Execute Deployed Functions
To evaluate MATLAB functions deployed on the server, see [Client Programming](https://www.mathworks.com/help/mps/client-programming.html). 

## Request Enhancements

To suggest additional features or capabilities, see
[Request Reference Architectures](https://www.mathworks.com/products/reference-architectures/request-new-reference-architectures.html).

## Get Technical Support

If you require assistance, email mwlab@mathworks.com.

## License

MATHWORKS CLOUD REFERENCE ARCHITECTURE LICENSE © 2021 The MathWorks, Inc.

