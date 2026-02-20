MINIKUBE_K8S_VERSION ?= v1.35.0
NAMESPACE ?= restart-demos

.PHONY: check-env setup demo-configmap demo-secret demo-image \
        demo-istio demo-resize demo-reloader clean

check-env:
	@echo "=== Environment Check ==="
	@kubectl version --short 2>/dev/null || kubectl version
	@minikube version
	@echo ""
	@echo "Current K8s version:"
	@kubectl version --short 2>/dev/null | grep Server || true
	@echo ""
	@echo "Nodes:"
	@kubectl get nodes -o wide

setup:
	@kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@echo "Namespace $(NAMESPACE) ready"

demo-configmap: setup
	@echo "=== Scenario 01: ConfigMap ==="
	bash 01-configmap/demo.sh 2>&1 | tee evidence/01-configmap.txt

demo-secret: setup
	@echo "=== Scenario 02: Secret ==="
	bash 02-secret/demo.sh 2>&1 | tee evidence/02-secret.txt

demo-image: setup
	@echo "=== Scenario 03: Image Update ==="
	bash 03-image-update/demo.sh 2>&1 | tee evidence/03-image-update.txt

demo-istio:
	@echo "=== Scenario 04: Istio Routing ==="
	@kubectl get ns istio-system > /dev/null 2>&1 || \
		(echo "ERROR: Istio not installed. Run: minikube addons enable istio" && exit 1)
	bash 04-istio-routing/demo.sh 2>&1 | tee evidence/04-istio.txt

demo-resize:
	@echo "=== Scenario 05: In-Place Resize (requires K8s 1.35+) ==="
	bash 05-resource-resize/demo.sh 2>&1 | tee evidence/05-resize.txt

demo-reloader: setup
	@echo "=== Scenario 07: Stakater Reloader ==="
	bash 07-stakater-reloader/demo.sh 2>&1 | tee evidence/07-reloader.txt

demo-all: demo-configmap demo-secret demo-image demo-istio demo-reloader

clean:
	kubectl delete namespace $(NAMESPACE) --ignore-not-found
