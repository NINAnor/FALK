# FALK
Repository for development, scripts, configuration files, specific for the FALK project. Where/when more appropriate, additional development for the project can be found in repositories for the software components used in FALK.

# Deploying GeoNode in Sigma2 kubernetes
This section describes the steps followed to deploy a GeoNode instance to sigma2 kubernetes starting from a solution used at NINA based on docker-compose.

## Generate a docker-compose suitable for conversion

#### `docker-compose-with-vars.yml`

This file is generated populating `docker-compose.yml` with variables from `.env`:

```bash
cd scripts/spcgeonode
(set -a && source .env && envsubst < docker-compose.yml ) > docker-compose-with-vars.yml
```

## Convert to kubernetes pods

This folder has been generated from `docker-compose-with-vars.yml`

```bash
cd kubernetes
kompose convert -f ../docker-compose-with-vars.yml
```

## Install k3s

[k3s](https://k3s.io/) is a lightweight distribution of Kubernetes.

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

`kubectl apply — namespace=falk-ns9693k  –f nina-gitlab-com.yml`


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
