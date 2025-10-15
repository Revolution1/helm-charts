# example-app

An example Helm chart demonstrating the repository structure.

## Introduction

This chart is a demonstration of how charts are structured in this repository. It deploys a basic nginx application.

## Installing the Chart

To install the chart with the release name `my-release`:

```bash
helm install my-release revolution1/example-app
```

## Uninstalling the Chart

To uninstall the `my-release` deployment:

```bash
helm uninstall my-release
```

## Configuration

The following table lists the configurable parameters of the example-app chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `nginx` |
| `image.tag` | Image tag | `""` (uses appVersion) |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example:

```bash
helm install my-release \
  --set replicaCount=3 \
  --set service.type=LoadBalancer \
  revolution1/example-app
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart:

```bash
helm install my-release -f values.yaml revolution1/example-app
```
