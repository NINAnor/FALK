# Deploying GeoNode in Sigma2 kubernetes
A FALK GeoNode instance has been deployed in sigma2 servers and available at https://geonode.falk.sigma2.no/.
This section of the README describes the steps followed to deploy the GeoNode instance to sigma2 kubernetes starting from a docker-compose configuration used at NINA.

## Customize GeoNode for the FALK project
GeoNode was customized with changes in the Homepage, a suitable color palette and the Milødirektoratet logo.
Gitlab CI automatically builds docker images and provides them through the NINA registry.gitlab.com registry. 

## Generate a docker-compose suitable for conversion
Before converting the NINA docker-compose.yml to kubernetes pods: 
#### `docker-compose-with-vars.yml`

This file is generated populating `docker-compose.yml` with variables from `.env` by the command:

```bash
cd scripts/spcgeonode
(set -a && source .env && envsubst < docker-compose.yml ) > docker-compose-with-vars.yml
```

## Convert to kubernetes pods

A folder containing kuberneted pods is generated from `docker-compose-with-vars.yml`, using the kompose tool:

```bash
cd kubernetes
kompose convert -f ../docker-compose-with-vars.yml
```

## Install k3s

Before sharing the pods with sigma2 enginners, they were tested locally. [k3s](https://k3s.io/) is a lightweight distribution of Kubernetes.

```bash
curl -sfL https://get.k3s.io | sh -
```

## Local provisioner

As k3s has no provisioner by default, a local provisioner can be created after the installation.

1. Create directory that's needed by local provisioner: 

`sudo mkdir /opt/local-path-provisioner`

2. Install local provisioner: 

`sudo k3s kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml`

3. Set the local provisioner as default:

 `sudo k3s kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' `

Source: https://github.com/rancher/k3s/issues/85#issuecomment-492475034


## Support for private registry (local, using k3s)

Authentication for registry.gitlab.com can be obtained doing:

```bash
docker login registry.gitlab.com
sudo k3s kubectl create secret generic nina-gitlab-com \
    --from-file=.dockerconfigjson=$HOME/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson
pip3 install --user yq
for f in {celery{,cam,beat},django,geoserver,nginx}-pod.yaml; do
  yq -y '.spec += {"imagePullSecrets":[{"name": "nina-gitlab-com"}]}' $f | sponge $f
done
```

## Storage

Have a look at those files, especially at the storage size requested:

```bash
find *-persistentvolumeclaim.yaml
database-persistentvolumeclaim.yaml
geodatadir-persistentvolumeclaim.yaml
media-persistentvolumeclaim.yaml
rabbitmq-persistentvolumeclaim.yaml
static-persistentvolumeclaim.yaml
```

## Deploy

```bash
sudo kubectl k3s apply -f .
```

## Monitoring

```bash
sudo watch k3s kubectl get pod
```

## Debugging

```bash
sudo watch k3s kubectl describe pods
```

## Moving the obtained pods to sigma2 servers
A FALK project folder created in sigma2 nird servers was used to store configuration files and data.
The folder containing the pods was moved via scp to the nird project folder, used as a bridge to interact with sigma2 engineers.

## Support for private registry (from sigma2 server)
Authentication for registry.gitlab.com in this case can be obtained creating a secret with a gitlab deploy token
(after moving the kubernetes folder obtained with previous steps, including imagePullSecrets in pods):

```bash
kubectl create secret docker-registry --dry-run=true nina-gitlab-com \
--docker-server=registry.gitlab.com \
--docker-username=gitlab-falk-geonode \
--docker-password=<token obtained in gitlab.com> \
--docker-email=<some-email> -o yaml > nina-gitlab-com.yaml

```

The nina-gitlab-com.yaml secret file is copied to sigma2 storage server and secret deployed with:

`kubectl apply —namespace=falk-[namespace] –f nina-gitlab-com.yml`

## Adaptation and reconfiguration of the pods
The pods had to be modified and adapted to the sigma2 kubernetes environment. The choice was to convert the separate pods to a single multi-container pod.  
