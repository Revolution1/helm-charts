# Charts Directory

Place your Helm charts in this directory.

Each chart should be in its own subdirectory with the following structure:

```
charts/
└── my-chart/
    ├── Chart.yaml          # Chart metadata
    ├── values.yaml         # Default values
    ├── templates/          # Kubernetes manifest templates
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── ...
    ├── README.md           # Chart documentation
    └── .helmignore         # Files to ignore when packaging
```

## Example: Creating a New Chart

```bash
# Create a new chart using helm
cd /path/to/helm-charts
helm create charts/my-app

# Edit the chart files as needed
# Update Chart.yaml with correct version and description
# Modify templates and values.yaml

# Test the chart
helm lint charts/my-app
helm template my-app charts/my-app

# Commit and push
git add charts/my-app
git commit -m "Add my-app chart v1.0.0"
git push
```

## Chart Requirements

1. **Chart.yaml**: Must include name, version, description
2. **values.yaml**: Should have commented defaults
3. **README.md**: Installation and configuration docs
4. **Version Bump**: Increment version for every change

## References

- [Helm Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Helm Documentation](https://helm.sh/docs/)
