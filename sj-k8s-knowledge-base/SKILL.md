---
name: sj-k8s-knowledge-base
description: SmartJoules/sj-k8s Kubernetes deployment knowledge base. Use when adding, reviewing, optimizing, or migrating a SmartJoules service, worker, CronJob, ML workload, ingress route, service account, HPA, PDB, ConfigMap, Secret reference, or EKS deployment. Guides new services to share the centralized sj-k8s repo structure instead of inventing separate Kubernetes deployment repos, with reusable deployment/service/HPA/PDB/RBAC patterns and production guardrails.
---

# sj-k8s Knowledge Base

**Source:** `SmartJoules/sj-k8s` at commit `dc4dab2`.
**Purpose:** Make Kubernetes deployment changes through the shared SmartJoules EKS manifest repo, not per-service ad hoc deployment files.

The repo centralizes EKS configuration for production/staging/dev services, CronJobs, ML workloads, ingress, RBAC/service accounts, monitoring, external apps, and storage. Secrets are intentionally not fully represented in the repo; do not copy inline secrets from existing manifests.

## Repository Map

- `deployments/<env-service>/` - long-running Deployments, usually with `deployment.yaml`, optional `service.yaml`, optional `hpa.yaml`, optional `pdb.yaml`, optional `cm.yaml` or `configmap.yaml`.
- `jobs/<env-job>/` - Kubernetes `CronJob` or one-off `Job` workloads.
- `ml/<ml-workload>/` - ML workloads with service account, configmap, PVC, and deployment resources.
- `networking/` - shared ALB ingress resources such as prod/dev/monitor/argo ingress.
- `rbac/` - EKS IAM role bound `ServiceAccount` manifests.
- `monitors/` - Grafana, Prometheus, and Telegraf resources.
- `external-apps/` - cluster add-ons such as Karpenter, Redis values, and Loki stack values.
- `storageclass/` - cluster storage class configuration.

Observed inventory: 69 deployment folders, 14 job folders, 1 ML workload, 45 services, 13 HPAs, 10 PDBs, 19 RBAC manifests, and shared ingress/monitoring resources.

## Naming Conventions

- Folder and resource names use `<env>-<service>` such as `prod-jt-api-v2`, `stg-jt-api-v2`, `dev-panjtara`.
- Use namespace by environment: `prod`, `stg`, `dev`, `monitor`, or `argocd`.
- Labels/selectors normally use `app: <env-service>`.
- ECR image names follow AWS ECR plus service image repo plus numeric tag.
- ServiceAccounts typically use `<env-service>-sa`; older services may use existing names such as `prod-jt-api-v2-new-sa`.
- ConfigMaps usually use `<env-service>-cm` or service-specific configmap names.

## New Service Onboarding

For a new SmartJoules service:

1. Add a folder under `deployments/<env-service>/` for long-running APIs/workers, or `jobs/<env-job>/` for scheduled/batch work.
2. Create `deployment.yaml` with app label, namespace, image, probes, resources, env/config references, and rollout strategy.
3. Add `service.yaml` only if the workload needs cluster or ingress traffic.
4. Add `cm.yaml` or `configmap.yaml` for non-secret config.
5. Add `hpa.yaml` for scalable online services or high-throughput consumers.
6. Add `pdb.yaml` for multi-replica production services that must survive node disruption.
7. Add an RBAC/service-account manifest when the pod needs AWS access through IRSA.
8. Add or update `networking/<env>-ingress.yaml` only when public host/path routing is required.
9. Validate selectors, ports, health paths, namespace, image tag, and secret references before applying.

Do not create a separate Kubernetes repo for each new service. Share this repo so operations, ingress, RBAC, autoscaling, and observability stay reviewable in one place.

## Deployment Pattern

Use this shape for normal service deployments:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <env-service>
  namespace: <env>
  labels:
    app: <env-service>
spec:
  replicas: 2
  revisionHistoryLimit: 1
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: <env-service>
  template:
    metadata:
      labels:
        app: <env-service>
    spec:
      serviceAccountName: <env-service>-sa
      terminationGracePeriodSeconds: 60
      containers:
        - name: <env-service>
          image: <account>.dkr.ecr.<region>.amazonaws.com/<image>:<tag>
          imagePullPolicy: Always
          envFrom:
            - configMapRef:
                name: <env-service>-cm
          ports:
            - containerPort: <app-port>
          readinessProbe:
            httpGet:
              path: /health/ready
              port: <app-port>
          livenessProbe:
            httpGet:
              path: /health
              port: <app-port>
          resources:
            requests:
              cpu: 200m
              memory: 512Mi
            limits:
              cpu: 500m
              memory: 1Gi
```

For high-traffic legacy Node/Sails APIs, `sj-k8s` also has a sidecar `nginx` pattern in front of the app container. Reuse it only when the service already needs nginx config, ALB health checks through port 80, or graceful proxy draining.

## Service Pattern

Use a `Service` when the workload receives traffic:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: <env-service>
  namespace: <env>
  labels:
    app: <env-service>
  annotations:
    alb.ingress.kubernetes.io/healthcheck-path: /health
    alb.ingress.kubernetes.io/healthcheck-port: "80"
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
    alb.ingress.kubernetes.io/target-type: ip
spec:
  type: ClusterIP
  selector:
    app: <env-service>
  ports:
    - name: http
      port: 80
      targetPort: <app-port>
      protocol: TCP
```

Make `targetPort` match the container port or the nginx sidecar port. For internal-only workers, skip `service.yaml`.

## CronJob Pattern

Use `jobs/<env-job>/deployment.yaml` for scheduled tasks:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: <env-job>
  namespace: <env>
  labels:
    app: <env-job>
spec:
  schedule: "*/15 * * * *"
  successfulJobsHistoryLimit: 0
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      backoffLimit: 0
      template:
        metadata:
          labels:
            app: <env-job>
        spec:
          serviceAccountName: <env-job>-sa
          restartPolicy: Never
          containers:
            - name: <env-job>
              image: <ecr-image>:<tag>
              imagePullPolicy: Always
              envFrom:
                - configMapRef:
                    name: <env-job>-cm
              resources:
                requests:
                  cpu: 200m
                  memory: 512Mi
                limits:
                  cpu: 500m
                  memory: 1Gi
```

Set schedules conservatively. For minute-level jobs, confirm idempotency, locks, timeouts, and duplicate-run handling.

## HPA and PDB

Add HPA for services with variable traffic or Kafka/queue load. Existing production HPAs commonly scale by CPU and sometimes memory, with slower scale-down stabilization.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: <env-service>
  namespace: <env>
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: <env-service>
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 60
```

Add a PDB for multi-replica production APIs:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: pdb-<env-service>
  namespace: <env>
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: <env-service>
```

## RBAC / IRSA Pattern

When a pod needs AWS access, add or reuse a `ServiceAccount` with the EKS role annotation:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: <env-service>-sa
  namespace: <env>
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::<account-id>:role/<role-name>
automountServiceAccountToken: false
```

Use least privilege IAM. Do not reuse broad service accounts just because they already exist. Confirm S3/DynamoDB/IoT/Neptune/MSK/RDS permissions with the service owner.

## Ingress Pattern

Shared ALB ingress lives in `networking/`. Production uses ALB annotations for certificate, group, target type, WAF, HTTPS listener, and SSL redirect. Add a route only when the service must be public:

```yaml
- host: <host>
  http:
    paths:
      - backend:
          service:
            name: <env-service>
            port:
              number: 80
        path: /<path>
        pathType: Prefix
```

Prefer path/host reuse only when API ownership is clear. Check path precedence to avoid shadowing existing `/`, `/m2`, `/health`, or socket routes.

## Config and Secrets

- Put non-secret environment in `cm.yaml` or `configmap.yaml`.
- Put secrets in Kubernetes Secrets, external secret management, or pre-existing cluster secret workflows.
- Reference secrets with `valueFrom.secretKeyRef`.
- Do not copy inline credentials, tokens, DSNs with embedded credentials, webhook URLs, database passwords, Kafka credentials, or API keys from existing manifests.
- If an existing manifest has inline secrets, treat that as legacy debt and avoid spreading it to new services.

## Production Readiness Checklist

- [ ] Folder placed under `deployments/`, `jobs/`, or `ml/` correctly
- [ ] Resource names, selectors, labels, namespace, and service names match
- [ ] Image points to the correct ECR repo and immutable tag
- [ ] Requests and limits are set
- [ ] Liveness/readiness probes match real health endpoints
- [ ] Graceful shutdown is handled for APIs and consumers
- [ ] ConfigMap contains only non-secret config
- [ ] Secrets are referenced, not embedded
- [ ] ServiceAccount/IRSA is least privilege
- [ ] Service exists only when traffic is needed
- [ ] Ingress route is added only when public traffic is needed
- [ ] HPA/PDB added for production multi-replica services
- [ ] Rollback path is clear: previous image tag and `kubectl rollout undo`
- [ ] Monitoring/logging/Sentry/APM environment names are correct

## Apply / Review Commands

Use these as review commands, not blind production actions:

```bash
kubectl diff -f deployments/<env-service>/
kubectl apply --dry-run=server -f deployments/<env-service>/
kubectl apply -f deployments/<env-service>/
kubectl rollout status deployment/<env-service> -n <env>
kubectl describe pod -n <env> -l app=<env-service>
kubectl logs -n <env> -l app=<env-service> --tail=100
```

For CronJobs:

```bash
kubectl apply --dry-run=server -f jobs/<env-job>/
kubectl create job --from=cronjob/<env-job> <env-job>-manual-<date> -n <env>
kubectl logs -n <env> job/<manual-job-name>
```

Ask before running production `apply`, deleting resources, changing ingress, changing service accounts, or editing secrets.
