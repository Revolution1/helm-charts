# helm-charts

Helm charts of various apps

## Usage

### Adding the Helm Repository

```bash
helm repo add revolution1 https://revolution1.github.io/helm-charts
helm repo update
```

### Installing a Chart

```bash
helm install my-release revolution1/<chart-name>
```

### Searching for Charts

```bash
helm search repo revolution1
```

## Development

### Prerequisites

- Helm 3.x
- chart-testing (ct)
- yamllint
- yamale

### Directory Structure

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

### Creating a New Chart

```bash
# Create a new chart
helm create charts/my-new-chart

# Update Chart.yaml with proper metadata
# Add your chart files and templates
```

### Linting Charts

```bash
# Lint using chart-testing (recommended)
make lint

# Or lint using helm lint
make lint-helm
```

### Packaging Charts

```bash
# Package all charts
make package
```

### Testing Charts Locally

```bash
# Template charts to verify syntax
make template

# Install chart in a local cluster
helm install test-release ./charts/<chart-name> --dry-run --debug
```

### Updating Chart Dependencies

```bash
make deps
```

## CI/CD

### Automated Testing

On every pull request that modifies charts:
- Charts are automatically linted using chart-testing
- Changed charts are installed and tested in a kind cluster

### Automated Releases

When charts are pushed to the `main` branch:
- New chart versions are automatically packaged
- Releases are created on GitHub
- Charts are published to GitHub Pages
- The Helm repository index is updated

### Repository Setup

For initial repository setup including creating and protecting the gh-pages branch, see:
- [Setup Guide](SETUP.md) (English)
- [设置指南](SETUP_zh.md) (中文)

## Chart Guidelines

### Chart.yaml Requirements

Each chart must have a properly formatted `Chart.yaml` with:
- `name`: Chart name
- `version`: Chart version (must be bumped for each change)
- `description`: Brief description
- `type`: Usually "application"
- `appVersion`: Version of the application being deployed

### Versioning

- Follow [Semantic Versioning](https://semver.org/)
- Bump the chart version in `Chart.yaml` for every change
- Use `appVersion` to track the application version

### Documentation

Each chart should include:
- `README.md` with installation and configuration instructions
- `values.yaml` with well-commented default values
- Examples in an `examples/` directory (optional)

## Contributing

1. Create a new branch for your changes
2. Make changes to charts in the `charts/` directory
3. Bump the chart version in `Chart.yaml`
4. Test your changes locally
5. Submit a pull request
6. Wait for CI checks to pass
7. Once merged to main, charts are automatically released

## License

See individual chart directories for license information
