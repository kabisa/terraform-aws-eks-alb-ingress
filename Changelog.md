# Version 3.0.0 - 19-05-2022
## BREAKING CHANGES
```This version no longer works with Kubernetes version 1.18 and below due to changes in the API for Ingress resources from 1.19 and onwards```

### Upgraded
- Helm chart for the loadbalancer controller upgraded to version: [2.4.1](https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/tag/v2.4.1)
- Upgraded values yaml for the loadbalancer
- Custom resource definitions updated to new version: [0.5.0](https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/ec3418567841c1d36caf493c76105baf5e337b98/helm/aws-load-balancer-controller/crds/crds.yaml) 

### Added
- Terraform-docs inside the Readme.
- Added description for all the variables.
- Added description for all the outputs.
- Added variable `force_update` for the helm chart.
- Added Changelog to repository.


# Version 2.0.1 - 14-04-2022
### Upgraded
- removed usage of `template_file` in favor of `templatefile`