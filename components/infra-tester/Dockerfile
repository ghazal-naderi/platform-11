FROM alpine:3.11.3
LABEL maintainer="calum.lacroix@11fs.com"
ENV KUBERNETES_VERSION="v1.18.8" TERRAFORM_VERSION="0.13.3" HELM_VERSION="v3.3.0" \
    SHELLCHECK_VERSION="v0.7.1" TFLINT_VERSION="v0.20.1" TFSEC_VERSION="v0.25.0" \
    KUBEVAL_VERSION="0.15.0" KUBESCORE_VERSION="1.8.1" KUSTOMIZE_VERSION="v3.8.1" \
    AWS_DEFAULT_REGION="eu-west-1" AWS_REGION="eu-west-1" GOOGLE_REGION="us-central1" \
    GOOGLE_ZONE="us-central1-c"
ADD https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz /tmp/shellcheck.tar.xz
ADD https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_amd64.zip /tmp/tflint.zip
ADD https://github.com/liamg/tfsec/releases/download/${TFSEC_VERSION}/tfsec-linux-amd64 /usr/local/bin/tfsec
ADD https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz /tmp/helm.tgz
ADD https://github.com/instrumenta/kubeval/releases/download/${KUBEVAL_VERSION}/kubeval-linux-amd64.tar.gz /tmp/kubeval.tgz
ADD https://github.com/zegl/kube-score/releases/download/v${KUBESCORE_VERSION}/kube-score_${KUBESCORE_VERSION}_linux_amd64 /usr/local/bin/kube-score
ADD https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip /tmp/terraform.zip
ADD https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz /tmp/kustomize.tgz
ADD https://dl.k8s.io/${KUBERNETES_VERSION}/kubernetes-client-linux-amd64.tar.gz /tmp/kubernetes.tgz
RUN apk add jq
RUN chmod +x /usr/local/bin/tfsec /usr/local/bin/kube-score && \
    tar -C /tmp/ -xf /tmp/shellcheck.tar.xz && \
    mv /tmp/shellcheck-${SHELLCHECK_VERSION}/shellcheck /usr/local/bin && chmod +x /usr/local/bin/shellcheck && \
    unzip -q -d /tmp/ /tmp/tflint.zip && mv /tmp/tflint /usr/local/bin/tflint && chmod +x /usr/local/bin/tflint && \
    tar -C /tmp/ -xf /tmp/helm.tgz && mv /tmp/linux-amd64/helm /usr/local/bin/helm && chmod +x /usr/local/bin/helm && \
    tar -C /tmp/ -xf /tmp/kubeval.tgz && mv /tmp/kubeval /usr/local/bin/kubeval && chmod +x /usr/local/bin/kubeval && \
    unzip -q -d /tmp/ /tmp/terraform.zip && mv /tmp/terraform /usr/local/bin/terraform && chmod +x /usr/local/bin/terraform \
    && tar -C /tmp/ -xf /tmp/kubernetes.tgz && mv /tmp/kubernetes/client/bin/kubectl /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl && tar -C /usr/local/bin -xf /tmp/kustomize.tgz && chmod +x /usr/local/bin/kustomize
VOLUME ["/workspace"]
WORKDIR /workspace
ENTRYPOINT ["/bin/ash","/workspace/build.sh"]

