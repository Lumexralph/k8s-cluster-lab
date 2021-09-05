## Quick start ##

# add a chart repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# list the charts you can install from the bitnami repository
helm search repo bitnami | more

# If you have found the chart (app) from the list, you can deploy
# the app to the cluster by running the below command:
helm repo update      # Make sure we get the latest list of charts

# install the chart i.e the app and it gets deployed to the k8s cluster:
helm install bitnami/mysql --generate-name

# get a simple idea of the features of this MySQL chart by running :
helm show chart bitnami/mysql

# Or to get all information about the bitnami/mysql chart:
helm show all bitnami/mysql

# Whenever you install a chart, a new release is created. So one chart can be installed multiple times into the same cluster.
# And each can be independently managed and upgraded.

# to see what has been released using Helm (list of all deployed releases):
helm list
helm ls

# uninstall mysql-1612624192 from Kubernetes, which will remove all resources associated with the release as well as the release history.
helm uninstall mysql-1612624192

# to keep the release history, use the flag --keep-history
helm uninstall --keep-history mysql-1612624192

# to request information about that release:
helm status mysql-1612624192

# Helm tracks your releases even after you've uninstalled them, you can audit a cluster's history, and even undelete a release:
 helm rollback mysql-1612624192

# create a persistent volume for the persistent volume claim by mysql app
cat <<EOF >mysql-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: task-pv-volume
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
EOF

cat mysql-pv.yaml | kubectl apply -f -

cat <<EOF >mysql-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  finalizers:
  - kubernetes.io/pvc-protection
  labels:
    app.kubernetes.io/component: primary
    app.kubernetes.io/instance: mysql-1630400590
    app.kubernetes.io/name: mysql
  name: data-mysql-1630400590-0
  namespace: default
spec:
  storageClassName: manual
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 8Gi
  volumeMode: Filesystem
EOF 

cat mysql-pvc.yaml | kubectl apply -f -


helm install bitnami/mysql --set persistence.storageClass="fast" --generate-name

# Changing ownership of the locally mouted volume for mysql in the worker: volume /bitnami/mysql
chown -R 1001:1001 /bitnami/mysql

# DEBUG the pod with
kubectl logs [podname] -p

# searches the Artifact Hub, which lists helm charts from
# dozens of different repositories.
helm search hub <helm-char-name>

# searches for all wordpress charts on Artifact Hub.
helm search hub wordpress

#  searches the repositories that you have added to your local helm client (with helm repo add). 
# This search is done over local data, and no public network connection is needed.
helm repo add <repo-from-hubs-list>

# Installing a chart with a relaease name you picked.
helm install <your-release-name> <name-of-helm-chart>
helm install happy-panda bitnami/wordpress

# To keep track of a release's state, or to re-read configuration information
helm status happy-panda

# To see what options are configurable on a chart, use helm show values
helm show values bitnami/wordpress

# You can then override any of these settings in a YAML
# formatted file, and then pass that file during installation.
# create a default MariaDB user with the name user0, 
# and grant this user access to a newly created user0db database
echo '{mariadb.auth.database: user0db, mariadb.auth.username: user0}' > values.yaml

helm install -f values.yaml bitnami/wordpress --generate-name

# There are two ways to pass configuration data during install:

# --values (or -f): Specify a YAML file with overrides. This can be specified multiple times and the rightmost file will take precedence

# --set: Specify overrides on the command line.

# When a new version of a chart is released, or when you want
# to change the configuration of your release, you can use the helm upgrade command.

# the happy-panda release is upgraded with the same chart, but with a new YAML file:
helm upgrade -f panda.yaml happy-panda bitnami/wordpress

# We can use helm get values to see whether that new setting took effect.
# The helm get command is a useful tool for looking at a release in the cluster
helm get values happy-panda

# if something does not go as planned during a release, 
# it is easy to roll back to a previous release using 
# A release version is an incremental revision. 
# Every time an install, upgrade, or rollback happens, the revision number is incremented by 1.
# helm rollback [RELEASE] [REVISION]
helm rollback happy-panda 1

# we can use helm history [RELEASE] to see revision numbers for a certain release.
helm history happy-panda

# When it is time to uninstall a release from the cluster
# helm uninstall [RELEASENAME]
# flags: --keep-history
helm uninstall happy-panda

# see all of your currently deployed releases
# flags: --uninstalled, --all
helm list

# REPOSITORY
# You can see which repositories are configured using 
helm repo list

# new repositories can be added with:
helm repo add <repo-name> <repo-artifact-url>
helm repo add dev https://example.com/dev-charts

# at any point you can make sure your Helm client is up to date by running:
helm repo update

# Repositories can be removed with
helm repo remove <repo-name>
