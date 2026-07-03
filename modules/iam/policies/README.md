# aws-load-balancer-controller-policy.json

This is the upstream IAM policy for the [AWS Load Balancer
Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller),
which stagecraft-helm installs into the cluster to satisfy "expose via a load
balancer." It's a large, actively-maintained policy — before every
production apply, refresh it from the canonical source rather than trusting
a copy that may drift:

```bash
curl -o modules/iam/policies/aws-load-balancer-controller-policy.json \
  https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
```

The version committed here is a known-good snapshot, sufficient to `terraform
validate`/`plan` immediately, but treat the command above as the source of
truth.
