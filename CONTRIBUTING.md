# Contributing to helm-charts

Thank you for your interest in contributing to this Helm charts repository!

## How to Contribute

### Adding a New Chart

1. **Create the chart structure**
   ```bash
   helm create charts/your-chart-name
   ```

2. **Update Chart.yaml**
   - Set proper `version` (start with 1.0.0 for new charts)
   - Set descriptive `description`
   - Add `maintainers` information
   - Set correct `appVersion`

3. **Customize the templates**
   - Modify the Kubernetes manifests in `templates/`
   - Update `values.yaml` with sensible defaults
   - Add comments to explain configuration options

4. **Add documentation**
   - Create a comprehensive `README.md` in your chart directory
   - Document all configurable parameters
   - Include installation examples

5. **Test locally**
   ```bash
   # Lint the chart
   helm lint charts/your-chart-name
   
   # Template the chart
   helm template test charts/your-chart-name
   
   # Dry-run install
   helm install test charts/your-chart-name --dry-run --debug
   ```

6. **Submit a Pull Request**
   - Create a branch for your changes
   - Commit your chart
   - Push and create a PR
   - CI will automatically lint and test your chart

### Updating an Existing Chart

1. **Make your changes**
   - Edit templates, values, or documentation as needed

2. **Bump the version**
   - Increment the `version` in `Chart.yaml` following [Semantic Versioning](https://semver.org/):
     - MAJOR version for incompatible API changes
     - MINOR version for backwards-compatible functionality
     - PATCH version for backwards-compatible bug fixes

3. **Update documentation**
   - Update the chart's README.md if configuration changes

4. **Test your changes**
   ```bash
   make lint-helm
   make template
   ```

5. **Submit a Pull Request**

## Development Workflow

### Prerequisites

Install the required tools:
- [Helm](https://helm.sh/docs/intro/install/) v3.x
- [chart-testing](https://github.com/helm/chart-testing) (ct)
- [yamllint](https://github.com/adrienverge/yamllint)

### Makefile Commands

```bash
# Display help
make help

# Lint all charts
make lint

# Lint with helm
make lint-helm

# Package charts
make package

# Clean packaged charts
make clean

# Update dependencies
make deps

# Template charts
make template
```

## CI/CD Process

### Pull Requests

When you submit a PR that modifies charts:
1. Charts are automatically linted using `chart-testing`
2. Changed charts are installed in a kind cluster
3. Tests defined in `templates/tests/` are executed

### Releases

When changes are merged to `main`:
1. Chart versions are compared with released versions
2. New versions are automatically packaged
3. GitHub releases are created
4. Charts are published to GitHub Pages
5. The Helm repository index is updated

For initial repository setup, see the [Setup Guide](SETUP.md) ([中文版](SETUP_zh.md)).

## Chart Guidelines

### Required Files

Every chart must include:
- `Chart.yaml` - Chart metadata
- `values.yaml` - Default configuration values
- `README.md` - Usage documentation
- `templates/` - Kubernetes manifests

### Best Practices

1. **Naming**: Use lowercase kebab-case for chart names
2. **Versioning**: Follow Semantic Versioning strictly
3. **Values**: Provide sensible defaults
4. **Documentation**: Comment all values in `values.yaml`
5. **Labels**: Use standard Kubernetes labels
6. **Resources**: Define resource limits and requests
7. **Security**: Follow security best practices
8. **Testing**: Include test templates in `templates/tests/`

### Testing Checklist

Before submitting:
- [ ] Chart lints without errors (`helm lint`)
- [ ] Chart templates without errors (`helm template`)
- [ ] `Chart.yaml` has correct version and metadata
- [ ] `values.yaml` is well-documented
- [ ] README.md includes installation and configuration docs
- [ ] Changes work with `helm install --dry-run`

## Questions?

If you have questions or need help, please:
- Open an issue for discussion
- Check existing issues and PRs
- Review the [Helm documentation](https://helm.sh/docs/)

Thank you for contributing! 🎉
