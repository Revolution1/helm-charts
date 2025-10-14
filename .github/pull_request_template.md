# Description

Please include a summary of the changes and which issue is fixed. Include relevant motivation and context.

Fixes # (issue)

## Type of Change

Please delete options that are not relevant.

- [ ] New chart
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Chart Information (if applicable)

**Chart Name**: 

**Chart Version**: 

**App Version**: 

## Checklist

- [ ] I have read the [CONTRIBUTING](../CONTRIBUTING.md) guidelines
- [ ] My code follows the style guidelines of this project
- [ ] I have bumped the chart version in `Chart.yaml`
- [ ] I have updated the chart's `README.md` with any new configuration options
- [ ] I have commented my values.yaml with clear descriptions
- [ ] My changes lint without errors (`make lint-helm`)
- [ ] My changes template without errors (`make template`)
- [ ] I have tested my chart with `helm install --dry-run --debug`
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing tests pass locally with my changes

## Testing Performed

Describe the tests that you ran to verify your changes:

```bash
# Example commands used
helm lint charts/my-chart
helm template test charts/my-chart
helm install test charts/my-chart --dry-run --debug
```

## Additional Notes

Add any additional notes about the PR here.
