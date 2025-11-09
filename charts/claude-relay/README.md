# Claude Relay Service Helm Chart

Deploy [Claude Relay Service](https://github.com/Wei-Shaw/claude-relay-service) on Kubernetes with this Helm chart. This chart provides production-ready deployment configurations including authentication, monitoring, logging, and flexible storage options.

> **Note**: This documentation covers only the configurations actually supported by the current chart templates and `values.yaml`.

## Key Features

- **Multi-account Claude API relay** with secure JWT-based authentication
- **Secure authentication** using JWT tokens and optional admin credentials
- **Built-in monitoring** via Prometheus metrics with optional ServiceMonitor for Prometheus Operator
- **Redis integration** - Use internal Redis subchart or connect to external Redis (TLS/password support)
- **Ingress support** with TLS termination and automatic blocking of `/metrics` and `/prometheus` endpoints
- **Horizontal Pod Autoscaling (HPA)** based on CPU and optional memory metrics
- **Flexible logging pipeline** using Fluent Bit sidecar
  - Multiple output types: stdout, forward, Elasticsearch, Loki, HTTP, Kafka, S3
  - Ephemeral logs via `emptyDir` or persistent logs via PVC
- **Optional external data PVC** for mounting at `/app/external-data`

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PersistentVolume provisioner (only required when `storage.logs.mode=pvc` or `storage.data.external.enabled=true`)

## Installation

### Basic Installation from Helm Repository

```bash
# Add the Helm repository and update
helm repo add revolution1 https://revolution1.github.io/helm-charts
helm repo update

# List available charts (optional)
helm search repo revolution1

# Install with minimal configuration
# Note: JWT secret and encryption key are auto-generated if not provided
helm install my-claude-relay revolution1/claude-relay \
  --set config.jwtSecret="$(openssl rand -base64 32)" \
  --set config.encryptionKey="$(openssl rand -base64 32)" \
  --set config.adminUsername="admin" \
  --set config.adminPassword="secure-password"
```

### Using External Redis

```bash
helm install my-claude-relay revolution1/claude-relay \
  --set redis.enabled=false \
  --set externalRedis.host="redis.example.com" \
  --set externalRedis.port=6379 \
  --set externalRedis.password="redis-password" \
  --set externalRedis.database=0 \
  --set externalRedis.tls=true
```

### Enabling Ingress

```bash
helm install my-claude-relay revolution1/claude-relay \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set ingress.hosts[0].host=claude-relay.example.com \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix \
  --set ingress.tls[0].secretName=claude-relay-tls \
  --set ingress.tls[0].hosts[0]=claude-relay.example.com
```

### Enabling ServiceMonitor (Prometheus Operator)

```bash
helm install my-claude-relay revolution1/claude-relay \
  --set serviceMonitor.enabled=true \
  --set serviceMonitor.namespace=monitoring \
  --set serviceMonitor.labels.release=prometheus \
  --set serviceMonitor.interval=30s \
  --set serviceMonitor.scrapeTimeout=10s
```

## Configuration Reference

### Application Configuration (Core Settings)

```yaml
config:
  # Server
  nodeEnv: production
  port: 3000
  host: "0.0.0.0"

  # Secrets (generated if not provided)
  jwtSecret: ""          # REQUIRED for deterministic secret; otherwise auto-generated
  encryptionKey: ""      # REQUIRED for deterministic secret; otherwise auto-generated

  # Security
  adminSessionTimeout: 86400000
  apiKeyPrefix: "cr_"

  # Admin (optional)
  adminUsername: ""
  adminPassword: ""

  # Logging
  logLevel: "info"
  logMaxSize: "10m"
  logMaxFiles: 5

  # System
  cleanupInterval: 3600000
  rateLimitCleanupInterval: 5
  tokenUsageRetention: 2592000000
  healthCheckInterval: 60000
  timezoneOffset: 8

  # Usage limits
  defaultTokenLimit: 1000000
```

### Redis Configuration

#### Internal Redis (Default)

```yaml
redis:
  enabled: true
  auth:
    enabled: false
    password: ""
  persistence:
    enabled: true
    size: 1Gi
  resources:
    limits:
      cpu: 250m
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 128Mi
```

#### External Redis

```yaml
redis:
  enabled: false

externalRedis:
  host: "redis.example.com"
  port: 6379
  password: "redis-password"
  database: 0
  tls: false
```

### Ingress Configuration

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations: {}
  hosts:
    - host: claude-relay.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: claude-relay-tls
      hosts:
        - claude-relay.example.com
```

> **Note**: Ingress rules automatically block access to `/metrics` and `/prometheus` endpoints by routing to a non-existent backend for security.

### Monitoring Configuration (ServiceMonitor)

```yaml
serviceMonitor:
  enabled: true
  namespace: "monitoring"
  labels: {}
  annotations: {}
  interval: 30s
  path: /prometheus
  port: http
  scrapeTimeout: 10s
  relabelings: []
  metricRelabelings: []
  namespaceSelector: {}
```

### Storage and Logging Configuration

```yaml
storage:
  data:
    # Default: emptyDir (no persistence for /app/data)
    type: emptyDir
    external:
      enabled: false
      # storageClass: ""
      # size: 1Gi
      # accessMode: ReadWriteOnce

  logs:
    # Modes: fluentbit (default), forward, pvc, emptyDir
    mode: fluentbit

    fluentbit:
      enabled: true
      image:
        repository: fluent/fluent-bit
        tag: "2.2.0"
        pullPolicy: IfNotPresent
      resources:
        limits:
          cpu: 100m
          memory: 128Mi
        requests:
          cpu: 50m
          memory: 64Mi
      output:
        type: stdout
        config: {}

    # Only used when mode=pvc
    persistence:
      enabled: false
      storageClass: ""
      accessMode: ReadWriteOnce
      size: 10Gi
```

**Logging Modes:**

- **`fluentbit`/`forward`**: Adds a Fluent Bit sidecar with ConfigMap, reads logs from `/app/logs/*.log`
- **`pvc`**: Creates a PersistentVolumeClaim for logs, mounts at `/app/logs`
- **`emptyDir`**: Uses ephemeral storage in pod filesystem for logs

**External Data PVC** (optional): When enabled, mounts at `/app/external-data`

## Values Reference

The following table lists the most commonly used configuration values:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| **Deployment & Image** | | | |
| `replicaCount` | int | `1` | Number of replicas (ignored if HPA enabled) |
| `image.repository` | string | `ghcr.io/wei-shaw/claude-relay-service` | Container image repository |
| `image.tag` | string | `""` | Image tag (defaults to chart `appVersion`) |
| `image.pullPolicy` | string | `IfNotPresent` | Image pull policy |
| **Service & Ingress** | | | |
| `service.type` | string | `ClusterIP` | Service type |
| `service.port` | int | `80` | Service port (proxies to container `config.port`) |
| `ingress.enabled` | bool | `false` | Enable Ingress |
| **Autoscaling** | | | |
| `autoscaling.enabled` | bool | `false` | Enable HPA |
| `autoscaling.minReplicas` | int | `1` | Min replicas |
| `autoscaling.maxReplicas` | int | `100` | Max replicas |
| `autoscaling.targetCPUUtilizationPercentage` | int | `80` | Target CPU utilization |
| **Redis** | | | |
| `redis.enabled` | bool | `true` | Use internal Redis subchart |
| `redis.auth.enabled` | bool | `false` | Enable Redis auth |
| `redis.persistence.size` | string | `1Gi` | Internal Redis PVC size |
| `externalRedis.host` | string | `""` | External Redis host |
| `externalRedis.port` | int | `6379` | External Redis port |
| `externalRedis.password` | string | `""` | External Redis password |
| `externalRedis.database` | int | `0` | External Redis DB index |
| `externalRedis.tls` | bool | `false` | Enable TLS for external Redis |
| **Application Configuration** | | | |
| `config.jwtSecret` | string | `""` | JWT secret (optional; auto-generated if empty) |
| `config.encryptionKey` | string | `""` | Encryption key (optional; auto-generated if empty) |
| `config.adminUsername` | string | `""` | Admin username |
| `config.adminPassword` | string | `""` | Admin password |
| `config.apiKeyPrefix` | string | `"cr_"` | API key prefix |
| `config.adminSessionTimeout` | int(ms) | `86400000` | Admin session timeout |
| `config.logLevel` | string | `info` | Log level |
| `config.logMaxSize` | string | `10m` | Log file max size |
| `config.logMaxFiles` | int | `5` | Max rotated log files |
| `config.cleanupInterval` | int(ms) | `3600000` | Cleanup interval |
| `config.rateLimitCleanupInterval` | int(s) | `5` | Rate-limit cleanup interval |
| `config.tokenUsageRetention` | int(ms) | `2592000000` | Token usage retention |
| `config.healthCheckInterval` | int(ms) | `60000` | Health check interval |
| `config.timezoneOffset` | int | `8` | Timezone offset (hours) |
| `config.defaultTokenLimit` | int | `1000000` | Default token limit |
| **Monitoring** | | | |
| `serviceMonitor.enabled` | bool | `false` | Enable ServiceMonitor |
| `serviceMonitor.path` | string | `/prometheus` | Metrics path |
| `serviceMonitor.interval` | string | `30s` | Scrape interval |
| `serviceMonitor.scrapeTimeout` | string | `10s` | Scrape timeout |
| **Storage & Logging** | | | |
| `storage.logs.mode` | string | `fluentbit` | Logging mode (fluentbit/forward/pvc/emptyDir) |
| `storage.logs.fluentbit.output.type` | string | `stdout` | Fluent Bit output type |
| `storage.logs.fluentbit.output.config` | map | `{}` | Output configuration (raw key-value) |
| `storage.logs.persistence.size` | string | `10Gi` | Log PVC size (when mode=pvc) |
| `storage.data.type` | string | `emptyDir` | Data storage type |
| `storage.data.external.enabled` | bool | `false` | Enable external data PVC |

## Examples

### Production Deployment

Production setup with external Redis, Ingress, HPA, and ServiceMonitor:

```bash
helm install claude-relay revolution1/claude-relay \
  --set config.jwtSecret="your-jwt-secret" \
  --set config.encryptionKey="your-encryption-key" \
  --set config.adminUsername="admin" \
  --set config.adminPassword="secure-password" \
  --set redis.enabled=false \
  --set externalRedis.host="redis.production.com" \
  --set externalRedis.password="redis-password" \
  --set externalRedis.tls=true \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host="claude-relay.production.com" \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=3 \
  --set autoscaling.maxReplicas=20 \
  --set serviceMonitor.enabled=true
```

### Fluent Bit Output to Loki

```yaml
storage:
  logs:
    mode: fluentbit
    fluentbit:
      output:
        type: loki
        config:
          Host: "loki.monitoring.svc.cluster.local"
          Port: 3100
          URI: "/loki/api/v1/push"
          Labels: "job=claude-relay,environment=production"
```

### Persistent Log Storage (PVC Mode)

```yaml
storage:
  logs:
    mode: pvc
    persistence:
      enabled: true
      size: 50Gi
```

### External Data PVC

```yaml
storage:
  data:
    type: emptyDir
    external:
      enabled: true
      size: 5Gi
      accessMode: ReadWriteOnce
```

## Management

### Upgrading the Chart

```bash
# Upgrade to the latest version
helm upgrade claude-relay revolution1/claude-relay

# Upgrade with custom values
helm upgrade claude-relay revolution1/claude-relay -f values.yaml
```

### Uninstalling the Chart

```bash
helm uninstall claude-relay
```

## Troubleshooting

### Common Issues

#### 1. Pod fails to start with auth errors

- Ensure `config.jwtSecret` and `config.encryptionKey` are set (or verify auto-generated values in the Secret)
- Check Redis connectivity and credentials

#### 2. Redis connection issues

- Verify `redis.enabled` vs `externalRedis` configuration matches your setup
- Check Redis logs or external Redis network reachability
- Ensure firewall rules allow connections

#### 3. Ingress not working

- Confirm Ingress controller is installed and running
- Verify Ingress class and annotations are correct
- Note: Access to `/metrics` and `/prometheus` endpoints is intentionally blocked for security

#### 4. Logging not collected

- Check `storage.logs.mode` configuration and Fluent Bit ConfigMap
- For PVC mode, ensure the PVC is bound and has sufficient capacity
- Review Fluent Bit sidecar logs for errors

## Resources

- **Source Code**: [Claude Relay Service on GitHub](https://github.com/Wei-Shaw/claude-relay-service)
- **Issues & Bug Reports**: [Submit an Issue](https://github.com/Wei-Shaw/claude-relay-service/issues)
- **Chart Repository**: [Revolution1 Helm Charts](https://github.com/Revolution1/helm-charts)

## License

This chart is licensed under the MIT License. See [LICENSE](../../LICENSE) for details.