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