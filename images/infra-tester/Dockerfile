FROM alpine:3.12.1
LABEL maintainer="calum.lacroix@11fs.com"
ENV KUBERNETES_VERSION="v1.19.4" TERRAFORM_VERSION="0.14.0" KOPS_VERSION="v1.19.0-beta.1" \
    SHELLCHECK_VERSION="v0.7.1" TFLINT_VERSION="v0.20.3" TFSEC_VERSION="v0.36.6" \
    KUBEVAL_VERSION="0.15.0" KUBESCORE_VERSION="1.10.0" KUSTOMIZE_VERSION="v3.9.2" \
    HELM_VERSION="v3.4.1" AWS_DEFAULT_REGION="eu-west-1" AWS_REGION="eu-west-1" \
    GOOGLE_REGION="us-central1" GOOGLE_ZONE="us-central1-c" YQ_VERSION="3.4.1" \
    FETCH_VERSION="0.3.11" HUB_VERSION="2.14.2"
ADD https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz /tmp/shellcheck.tar.xz
ADD https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64 /usr/local/bin/kops
ADD https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_amd64.zip /tmp/tflint.zip
ADD https://github.com/liamg/tfsec/releases/download/${TFSEC_VERSION}/tfsec-linux-amd64 /usr/local/bin/tfsec
ADD https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz /tmp/helm.tgz
ADD https://github.com/instrumenta/kubeval/releases/download/${KUBEVAL_VERSION}/kubeval-linux-amd64.tar.gz /tmp/kubeval.tgz
ADD https://github.com/zegl/kube-score/releases/download/v${KUBESCORE_VERSION}/kube-score_${KUBESCORE_VERSION}_linux_amd64 /usr/local/bin/kube-score
ADD https://github.com/gruntwork-io/fetch/releases/download/v${FETCH_VERSION}/fetch_linux_amd64 /usr/local/bin/fetch
ADD https://github.com/github/hub/releases/download/v${HUB_VERSION}/hub-linux-amd64-${HUB_VERSION}.tgz /tmp/hub.tgz
ADD https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip /tmp/terraform.zip
ADD https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz /tmp/kustomize.tgz
ADD https://dl.k8s.io/${KUBERNETES_VERSION}/kubernetes-client-linux-amd64.tar.gz /tmp/kubernetes.tgz
ADD https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 /usr/local/bin/yq
RUN apk add jq && apk add libc6-compat && apk add git
RUN chmod +x /usr/local/bin/tfsec /usr/local/bin/kube-score /usr/local/bin/kops /usr/local/bin/yq /usr/local/bin/fetch && \
    tar -C /tmp/ -xf /tmp/shellcheck.tar.xz && \
    tar -C /tmp/ -xf /tmp/hub.tgz && \
    mv /tmp/shellcheck-${SHELLCHECK_VERSION}/shellcheck /usr/local/bin && chmod +x /usr/local/bin/shellcheck && \
    mv /tmp/hub-linux-amd64-${HUB_VERSION}/bin/hub /usr/local/bin && chmod +x /usr/local/bin/hub && \
    unzip -q -d /tmp/ /tmp/tflint.zip && mv /tmp/tflint /usr/local/bin/tflint && chmod +x /usr/local/bin/tflint && \
    tar -C /tmp/ -xf /tmp/helm.tgz && mv /tmp/linux-amd64/helm /usr/local/bin/helm && chmod +x /usr/local/bin/helm && \
    tar -C /tmp/ -xf /tmp/kubeval.tgz && mv /tmp/kubeval /usr/local/bin/kubeval && chmod +x /usr/local/bin/kubeval && \
    unzip -q -d /tmp/ /tmp/terraform.zip && mv /tmp/terraform /usr/local/bin/terraform && chmod +x /usr/local/bin/terraform \
    && tar -C /tmp/ -xf /tmp/kubernetes.tgz && mv /tmp/kubernetes/client/bin/kubectl /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl && tar -C /usr/local/bin -xf /tmp/kustomize.tgz && chmod +x /usr/local/bin/kustomize
VOLUME ["/workspace"]
WORKDIR /workspace
ENTRYPOINT ["/bin/ash","/workspace/build.sh"]
