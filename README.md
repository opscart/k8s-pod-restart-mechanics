# k8s-pod-restart-mechanics

> Companion repository for the OpsCart article:
> **"When Kubernetes Restarts Your Pod — And When It Doesn't"**
>
> OpsCart.com | Author: Shamsher Sindhu

## Prerequisites

| Tool       | Version  | Notes                              |
|------------|----------|------------------------------------|
| minikube   | v1.34+   | v1.35+ required for resize demos   |
| kubectl    | 1.34+    |                                    |
| Docker     | Latest   | Minikube driver                    |
| Istio      | 1.20+    | For scenario 04 (pre-installed OK) |
| helm       | v3       | For Stakater Reloader (scenario 07)|

## Kubernetes Version Requirements

```
Scenario 01-03, 06-07 → K8s 1.34+ (your current minikube)
Scenario 04 (Istio)   → K8s 1.34+ + Istio installed
Scenario 05 (resize)  → K8s 1.35+ required (minikube upgrade needed)
```

## Quick Start

```bash
# Clone and run any demo
git clone https://github.com/your-handle/k8s-pod-restart-mechanics
cd k8s-pod-restart-mechanics

# Verify cluster
make check-env

# Run a specific demo
make demo-configmap
make demo-istio
make demo-resize        # Requires K8s 1.35+
```

## Scenarios

| # | Scenario | K8s Version | Restart? |
|---|---|---|---|
| 01 | ConfigMap — env var vs volume mount | 1.34+ | Conditional |
| 02 | Secret — env var vs volume mount | 1.34+ | Conditional |
| 03 | Image update rolling strategy | 1.34+ | Always |
| 04 | Istio xDS routing change | 1.34+ + Istio | Never |
| 05 | In-place resource resize (CPU/mem) | **1.35+ GA** | Per policy |
| 06 | StatefulSet maxUnavailable | 1.35 beta | Controlled |
| 07 | Stakater Reloader pattern | 1.34+ | Automated |

## Evidence

All demo scripts write captured output to `/evidence/`.
These are pre-captured in the repo so you can read results
without running the demos.

## Related Tools

- [kubectl-health-snapshot](https://github.com/your-handle/kubectl-health-snapshot) — OpsCart
- [opscart-k8s-watcher](https://github.com/your-handle/opscart-k8s-watcher) — OpsCart
