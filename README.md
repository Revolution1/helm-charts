# Helm Charts

A collection of Helm charts for deploying various applications on Kubernetes.

## Available Charts

| Chart | Description | Documentation |
|-------|-------------|---------------|
| `claude-relay` | Claude Relay Service - Multi-account Claude API relay with authentication | [README](charts/claude-relay/README.md) / [中文文档](charts/claude-relay/README_zh.md) |

## Quick Start

### 1. Add the Helm Repository

```bash
helm repo add revolution1 https://revolution1.github.io/helm-charts
helm repo update
```

### 2. Install a Chart

```bash
helm install my-release revolution1/<chart-name>
```

### 3. Search for Charts

```bash
helm search repo revolution1
```

## Development Guide

### Prerequisites

- [Helm](https://helm.sh/) 3.x
- [chart-testing (ct)](https://github.com/helm/chart-testing)
- [yamllint](https://github.com/adrienverge/yamllint)
- [yamale](https://github.com/23andMe/Yamale)

### Repository Structure

```
.
├── charts/                 # Helm charts directory
├── .github/
│   └── workflows/         # GitHub Actions workflows
├── .ct.yaml               # Chart testing configuration
├── .cr.yaml               # Chart releaser configuration
├── Makefile               # Common operations
└── README.md
```

### Common Development Tasks

#### Creating a New Chart

```bash
# Create a new chart using Helm scaffolding
helm create charts/my-new-chart

# Edit Chart.yaml with proper metadata
# Add your chart files and templates
```

#### Linting Charts

```bash
# Lint using chart-testing (recommended)
make lint

# Or lint using Helm directly
make lint-helm
```

#### Packaging Charts

```bash
# Package all charts
make package
```

#### Testing Charts Locally

```bash
# Render templates to verify syntax
make template

# Test installation in a local cluster
helm install test-release ./charts/<chart-name> --dry-run --debug
```

#### Updating Chart Dependencies

```bash
make deps
```

## CI/CD Pipeline

This repository uses GitHub Actions for automated testing and releases.

### Automated Testing (Pull Requests)

On every pull request that modifies charts:

- Charts are automatically linted using `chart-testing`
- Changed charts are installed and tested in a [kind](https://kind.sigs.k8s.io/) cluster

### Automated Releases (Main Branch)

When charts are pushed to the `main` branch:

- New chart versions are automatically packaged
- GitHub releases are created
- Charts are published to [GitHub Pages](https://revolution1.github.io/helm-charts)
- The Helm repository index is updated

### Automated Chart Updates

The `claude-relay` chart is automatically updated when new versions of the upstream application are released:

- Workflow runs every 12 hours to check for new releases
- Automatically bumps chart version and updates `appVersion`
- Creates a pull request with the changes
- Prevents duplicate PRs by using consistent branch names

## Chart Development Guidelines

### Chart.yaml Requirements

Each chart must have a properly formatted `Chart.yaml` with:

- **`name`**: Chart name
- **`version`**: Chart version (must be bumped for each change)
- **`description`**: Brief description of the chart
- **`type`**: Usually "application"
- **`appVersion`**: Version of the application being deployed

### Versioning

- Follow [Semantic Versioning](https://semver.org/)
- Bump the chart version in `Chart.yaml` for every change
- Use `appVersion` to track the application version

### Documentation Requirements

Each chart should include:

- **`README.md`**: Installation and configuration instructions
- **`values.yaml`**: Well-commented default values
- **`examples/`**: Example configurations (optional but recommended)

## Contributing

We welcome contributions! Here's how to contribute:

1. **Fork the repository** and create a new branch for your changes
2. **Make changes** to charts in the `charts/` directory
3. **Bump the chart version** in `Chart.yaml` following [Semantic Versioning](https://semver.org/)
4. **Test your changes** locally using the development tasks above
5. **Submit a pull request** with a clear description of your changes
6. **Wait for CI checks** to pass - all tests must pass before merging
7. **Merge to main** - charts are automatically released after merge

## Support and Resources

- **Documentation**: See individual chart `README.md` files for detailed documentation
- **Issues**: Report bugs or request features in the [Issues](https://github.com/Revolution1/helm-charts/issues) section
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines

## License

See individual chart directories for license information.
