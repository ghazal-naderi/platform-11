## This policy will enable kops to creates required resources on AWS account .

For aws-load-balancer-controller to run properly, kops needs extra policies to be attached to the cluster nodes.

This file which contains the policy description has been downloded from the following url:

 `curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.1.0/docs/install/iam_policy.jso`
