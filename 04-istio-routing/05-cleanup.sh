#!/bin/bash
NS="restart-demos"
echo ""
echo "Cleaning up Lab 04 resources..."
kubectl delete deployment echo-v1 echo-v2 -n $NS --ignore-not-found
kubectl delete service echo -n $NS --ignore-not-found
kubectl delete virtualservice echo -n $NS --ignore-not-found
kubectl delete destinationrule echo -n $NS --ignore-not-found
echo "✅ Lab 04 resources removed"
echo ""
