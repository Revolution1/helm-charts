# Claude Relay Service Helm Chart

使用此 Helm Chart 在 Kubernetes 上部署 [Claude Relay Service](https://github.com/Wei-Shaw/claude-relay-service)。提供生产就绪的部署配置，包括身份认证、监控、日志和灵活的存储选项。

> **说明**：本文档仅覆盖当前 Chart 模板与 `values.yaml` 实际支持的配置。

## 核心特性

- **多账户 Claude API 中继**，具备基于 JWT 的安全认证
- **安全认证机制**，支持 JWT Token 与可选的管理员凭据
- **内置监控**，提供 Prometheus 指标与可选的 ServiceMonitor（Prometheus Operator）集成
- **Redis 集成** - 可使用内部 Redis 子 Chart 或连接外部 Redis（支持 TLS/密码）
- **Ingress 支持**，支持 TLS 终止并自动阻止 `/metrics` 和 `/prometheus` 端点
- **水平自动扩缩容（HPA）**，基于 CPU 与可选的内存指标
- **灵活的日志管道**，使用 Fluent Bit Sidecar
  - 多种输出类型：stdout、forward、Elasticsearch、Loki、HTTP、Kafka、S3
  - 支持 `emptyDir` 临时日志或 PVC 持久化日志
- **可选的外部数据 PVC**，挂载至 `/app/external-data`

## 前置要求

- Kubernetes 1.19+
- Helm 3.2.0+
- PersistentVolume 供应器（仅当 `storage.logs.mode=pvc` 或 `storage.data.external.enabled=true` 时需要）

## 安装

### 从 Helm 仓库基础安装

```bash
# 添加 Helm 仓库并更新
helm repo add revolution1 https://revolution1.github.io/helm-charts
helm repo update

# 查看可用的 Charts（可选）
helm search repo revolution1

# 最小配置安装
# 注意：如未提供，JWT 密钥和加密密钥将自动生成
helm install my-claude-relay revolution1/claude-relay \
  --set config.jwtSecret="$(openssl rand -base64 32)" \
  --set config.encryptionKey="$(openssl rand -base64 32)" \
  --set config.adminUsername="admin" \
  --set config.adminPassword="secure-password"
```

### 使用外部 Redis

```bash
helm install my-claude-relay revolution1/claude-relay \
  --set redis.enabled=false \
  --set externalRedis.host="redis.example.com" \
  --set externalRedis.port=6379 \
  --set externalRedis.password="redis-password" \
  --set externalRedis.database=0 \
  --set externalRedis.tls=true
```

### 启用 Ingress

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

### 启用 ServiceMonitor（Prometheus Operator）

```bash
helm install my-claude-relay revolution1/claude-relay \
  --set serviceMonitor.enabled=true \
  --set serviceMonitor.namespace=monitoring \
  --set serviceMonitor.labels.release=prometheus \
  --set serviceMonitor.interval=30s \
  --set serviceMonitor.scrapeTimeout=10s
```

## 配置参考

### 应用配置（核心设置）

```yaml
config:
  # 服务器
  nodeEnv: production
  port: 3000
  host: "0.0.0.0"

  # 密钥（如不提供将自动生成）
  jwtSecret: ""          # 为获得可重复的密钥，建议显式设置
  encryptionKey: ""      # 为获得可重复的密钥，建议显式设置

  # 安全
  adminSessionTimeout: 86400000
  apiKeyPrefix: "cr_"

  # 管理员（可选）
  adminUsername: ""
  adminPassword: ""

  # 日志
  logLevel: "info"
  logMaxSize: "10m"
  logMaxFiles: 5

  # 系统
  cleanupInterval: 3600000
  rateLimitCleanupInterval: 5
  tokenUsageRetention: 2592000000
  healthCheckInterval: 60000
  timezoneOffset: 8

  # 使用限制
  defaultTokenLimit: 1000000
```

### Redis 配置

#### 内部 Redis（默认）

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

#### 外部 Redis

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

### Ingress 配置

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

> **说明**：出于安全考虑，Ingress 规则会通过路由到不存在的后端来自动阻止对 `/metrics` 和 `/prometheus` 端点的访问。

### 监控配置（ServiceMonitor）

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

### 存储与日志配置

```yaml
storage:
  data:
    # 默认：emptyDir（/app/data 不持久化）
    type: emptyDir
    external:
      enabled: false
      # storageClass: ""
      # size: 1Gi
      # accessMode: ReadWriteOnce

  logs:
    # 模式：fluentbit（默认）、forward、pvc、emptyDir
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

    # 仅在 mode=pvc 时生效
    persistence:
      enabled: false
      storageClass: ""
      accessMode: ReadWriteOnce
      size: 10Gi
```

**日志模式：**

- **`fluentbit`/`forward`**：添加 Fluent Bit Sidecar 与 ConfigMap，从 `/app/logs/*.log` 读取日志
- **`pvc`**：为日志创建 PersistentVolumeClaim，挂载到 `/app/logs`
- **`emptyDir`**：在 Pod 文件系统中使用临时存储

**外部数据 PVC**（可选）：启用后挂载到 `/app/external-data`

## 配置值参考

以下表格列出了最常用的配置值：

| 键 | 类型 | 默认值 | 描述 |
|-----|------|---------|-------------|
| **部署与镜像** | | | |
| `replicaCount` | int | `1` | 副本数量（启用 HPA 时忽略） |
| `image.repository` | string | `ghcr.io/wei-shaw/claude-relay-service` | 容器镜像仓库 |
| `image.tag` | string | `""` | 镜像标签（默认为 chart `appVersion`） |
| `image.pullPolicy` | string | `IfNotPresent` | 镜像拉取策略 |
| **Service 与 Ingress** | | | |
| `service.type` | string | `ClusterIP` | Service 类型 |
| `service.port` | int | `80` | Service 端口（代理到容器 `config.port`） |
| `ingress.enabled` | bool | `false` | 是否启用 Ingress |
| **自动扩缩容** | | | |
| `autoscaling.enabled` | bool | `false` | 是否启用 HPA |
| `autoscaling.minReplicas` | int | `1` | 最小副本数 |
| `autoscaling.maxReplicas` | int | `100` | 最大副本数 |
| `autoscaling.targetCPUUtilizationPercentage` | int | `80` | 目标 CPU 利用率 |
| **Redis** | | | |
| `redis.enabled` | bool | `true` | 使用内部 Redis 子 Chart |
| `redis.auth.enabled` | bool | `false` | 是否启用 Redis 认证 |
| `redis.persistence.size` | string | `1Gi` | 内部 Redis PVC 大小 |
| `externalRedis.host` | string | `""` | 外部 Redis 主机 |
| `externalRedis.port` | int | `6379` | 外部 Redis 端口 |
| `externalRedis.password` | string | `""` | 外部 Redis 密码 |
| `externalRedis.database` | int | `0` | 外部 Redis 数据库索引 |
| `externalRedis.tls` | bool | `false` | 是否为外部 Redis 启用 TLS |
| **应用配置** | | | |
| `config.jwtSecret` | string | `""` | JWT 密钥（可选；为空时自动生成） |
| `config.encryptionKey` | string | `""` | 加密密钥（可选；为空时自动生成） |
| `config.adminUsername` | string | `""` | 管理员用户名 |
| `config.adminPassword` | string | `""` | 管理员密码 |
| `config.apiKeyPrefix` | string | `"cr_"` | API Key 前缀 |
| `config.adminSessionTimeout` | int(ms) | `86400000` | 管理员会话超时 |
| `config.logLevel` | string | `info` | 日志级别 |
| `config.logMaxSize` | string | `10m` | 单个日志文件最大大小 |
| `config.logMaxFiles` | int | `5` | 日志文件轮转保留数量 |
| `config.cleanupInterval` | int(ms) | `3600000` | 清理任务间隔 |
| `config.rateLimitCleanupInterval` | int(s) | `5` | 速率限制清理间隔 |
| `config.tokenUsageRetention` | int(ms) | `2592000000` | Token 使用数据保留周期 |
| `config.healthCheckInterval` | int(ms) | `60000` | 健康检查间隔 |
| `config.timezoneOffset` | int | `8` | 时区偏移（小时） |
| `config.defaultTokenLimit` | int | `1000000` | 默认 Token 限额 |
| **监控** | | | |
| `serviceMonitor.enabled` | bool | `false` | 是否启用 ServiceMonitor |
| `serviceMonitor.path` | string | `/prometheus` | 指标路径 |
| `serviceMonitor.interval` | string | `30s` | 采集间隔 |
| `serviceMonitor.scrapeTimeout` | string | `10s` | 采集超时 |
| **存储与日志** | | | |
| `storage.logs.mode` | string | `fluentbit` | 日志模式（fluentbit/forward/pvc/emptyDir） |
| `storage.logs.fluentbit.output.type` | string | `stdout` | Fluent Bit 输出类型 |
| `storage.logs.fluentbit.output.config` | map | `{}` | 输出配置（原始键值） |
| `storage.logs.persistence.size` | string | `10Gi` | 日志 PVC 大小（mode=pvc 时） |
| `storage.data.type` | string | `emptyDir` | 数据存储类型 |
| `storage.data.external.enabled` | bool | `false` | 是否启用外部数据 PVC |

## 示例

### 生产环境部署

使用外部 Redis、Ingress、HPA 和 ServiceMonitor 的生产环境配置：

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

### Fluent Bit 输出到 Loki

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

### 持久化日志存储（PVC 模式）

```yaml
storage:
  logs:
    mode: pvc
    persistence:
      enabled: true
      size: 50Gi
```

### 外部数据 PVC

```yaml
storage:
  data:
    type: emptyDir
    external:
      enabled: true
      size: 5Gi
      accessMode: ReadWriteOnce
```

## 管理

### 升级 Chart

```bash
# 升级到最新版本
helm upgrade claude-relay revolution1/claude-relay

# 使用自定义配置升级
helm upgrade claude-relay revolution1/claude-relay -f values.yaml
```

### 卸载 Chart

```bash
# 卸载
helm uninstall claude-relay
```

## 故障排除

### 常见问题

#### 1. Pod 启动报认证错误

- 确认已设置 `config.jwtSecret` 和 `config.encryptionKey`（或查看 Secret 中的自动生成值）
- 检查 Redis 连接与凭据

#### 2. Redis 连接问题

- 核对 `redis.enabled` 与 `externalRedis` 配置是否与您的设置匹配
- 查看 Redis 日志或检查外部 Redis 的网络可达性
- 确保防火墙规则允许连接

#### 3. Ingress 不工作

- 确认 Ingress 控制器已安装并运行
- 验证 Ingress 类与注解配置正确
- 注意：出于安全考虑，对 `/metrics` 和 `/prometheus` 端点的访问被故意阻止

#### 4. 日志未采集

- 检查 `storage.logs.mode` 配置和 Fluent Bit ConfigMap
- 在 PVC 模式下，确认 PVC 已绑定且有足够容量
- 查看 Fluent Bit Sidecar 日志中的错误信息

## 相关资源

- **源代码**：[Claude Relay Service on GitHub](https://github.com/Wei-Shaw/claude-relay-service)
- **问题与 Bug 报告**：[提交 Issue](https://github.com/Wei-Shaw/claude-relay-service/issues)
- **Chart 仓库**：[Revolution1 Helm Charts](https://github.com/Revolution1/helm-charts)

## 许可证

本 Chart 采用 MIT 许可证。详见 [LICENSE](../../LICENSE)。