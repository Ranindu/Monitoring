#!/usr/bin/env bash

Help()
{
   # Display Help
   echo "This is the kubernetes zapmii bootstrap"
   echo
   echo "options:"
   echo "-h     Print this Help."
   echo "-w     Windows mode."
   echo "-m     Mac mode."
   echo "-u     Ubuntu mode."
   echo "-l     Deploy local environment."
   echo "-d     Deploy development environment."
   echo "-p     Deploy production environment."
   echo "-c     Deploy Cluster Service Update"
   echo "-t     Run test config."
   echo
}

Windows()
{
  echo "RUNNING WINDOWS SCRIPT"
  minikube delete
  sleep 5
  minikube start \
    --vm-driver=hyperv \
    --network-plugin=cni \
    --extra-config=kubelet.network-plugin=cni \
    --extra-config=apiserver.service-node-port-range=1-65535
  minikube addons enable dashboard
  minikube addons enable metrics-server
  minikube addons enable ingress
  kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
  kustomize build ./cluster | kubectl apply -f -
  minikube addons list
}

Mac()
{
  echo "RUNNING MAC SCRIPT"
  minikube delete
  sleep 5
  minikube start \
    --vm-driver=hyperkit \
    --network-plugin=cni \
    --extra-config=kubelet.network-plugin=cni \
    --extra-config=apiserver.service-node-port-range=1-65535
  minikube addons enable dashboard
  minikube addons enable metrics-server
  minikube addons enable ingress
  kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
  kustomize build ./clusters/overlays/local | kubectl apply -f -
  minikube addons list
}

Ubuntu()
{
  echo "RUNNING UBUNTU SCRIPT"
  minikube delete
  sleep 5
  minikube start \
    --vm-driver=virtualbox \
    --network-plugin=cni \
    --extra-config=kubelet.network-plugin=cni \
    --extra-config=apiserver.service-node-port-range=1-65535
  minikube addons enable dashboard
  minikube addons enable metrics-server
  minikube addons enable ingress
  kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
  kustomize build ./clusters/local | kubectl apply -f -
  minikube addons list
}


DeployLocal()
{
  echo "RUNNING LOCAL CLUSTER UPDATE"
  kustomize build ./clusters/overlays/local | kubectl apply -f -
  sleep 2;
  minikube service ui-admin-local --url -n local
  minikube service profile-local --url -n local
  minikube service refdata-local --url -n local
  minikube service keycloak-local --url -n local
  minikube service filestore-local --url -n local
  minikube service messages-local --url -n local
  minikube service devices-local --url -n local
}
 
DeployDevelopement()
{
  echo "RUNNING DEVELOPMENT CLUSTER UPDATE"
  kustomize build ./clusters/overlays/development | kubectl apply -f -
}

DeployProduction()
{
  echo "RUNNING PRODUCTION CLUSTER UPDATE"
  kustomize build ./clusters/production | kubectl apply -f -
}

DeployClusterServiceUpdate()
{
  echo "RUNNING CLUSTER SERVICE UPDATE"
   kustomize build ./apps/base | kubectl apply -f -
}

TestConfig()
{
  echo "RUNNING CONFIG TEST"
  echo "LOCAL:"
  kustomize build ./clusters/local
  echo "CLUSTER:"
  kustomize build ./apps/base
  echo "DEVELOPMENT:"
  kustomize build ./clusters/development
}

while getopts ":hwmuldptc" option; do
   case ${option} in
      h) # display Help
         Help
         exit;;
      w) # run windows script
         Windows
         exit;;
      m) # run mac script
         Mac
         exit;;
      u) # run ubuntu script
         Ubuntu
         exit;;
      l) #run local script
         DeployLocal
         exit;;
      d) #run development script
         DeployDevelopement
         exit;;
      p) #run production script
         DeployProduction
         exit;;
      c) #run cluster service update
         DeployClusterServiceUpdate
         exit;;
      t) #run config check
         TestConfig
         exit;;
      \?)
         echo "Error: Invalid option"
   esac
done

Help