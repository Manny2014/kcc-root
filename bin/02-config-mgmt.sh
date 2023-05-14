# DELETE OLD CONFIG CONNECTOR 
kdel configconnectorcontext -n config-control --all 
kdel configconnector --all 

# UPDATE ACM
kubectl apply -f bin/resources/config-management.yaml