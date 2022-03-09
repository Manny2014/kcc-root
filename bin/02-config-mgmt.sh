# DELETE OLD CONFIG CONNECTOR 
kdel configconnector --all 

# UPDATE ACM
kubectl apply -f bin/resources/config-management.yaml