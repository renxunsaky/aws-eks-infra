terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

locals {
  core_node_name = "${var.project}-${var.env}-${var.core_node_group_name_suffix}"
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config  = {
    region = var.region
    bucket = var.terraform_state_bucket
    key    = "corp/eks"
  }
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = "v0.13.0"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter_irsa_role.iam_role_arn
  }

  set {
    name  = "clusterName"
    value = data.terraform_remote_state.eks.outputs.cluster_id
  }

  set {
    name  = "clusterEndpoint"
    value = data.terraform_remote_state.eks.outputs.cluster_endpoint
  }

  set {
    name  = "aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }

  values = [
    yamlencode({"nodeSelector": {"eks.amazonaws.com/nodegroup": local.core_node_name}})
  ]
}

resource "kubectl_manifest" "karpenter_spark_driver_provisioner" {
  yaml_body = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: spark-driver
  spec:
    labels:
      sparkRole: driver
    requirements:
      - key: "topology.kubernetes.io/zone"
        operator: In
        values: ["eu-west-1a"]
      - key: "karpenter.sh/capacity-type"
        operator: In
        values: ["on-demand"]
      - key: karpenter.k8s.aws/instance-family
        operator: In
        values: [m5, r5, r6]
      - key: karpenter.k8s.aws/instance-size
        operator: In
        values: [small, large, xlarge]
    limits:
      resources:
        cpu: "50"
        memory: 100Gi
    provider:
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: 100Gi
            volumeType: gp3
            iops: 10000
            deleteOnTermination: true
            throughput: 125
      subnetSelector:
        kubernetes.io/cluster/${data.terraform_remote_state.eks.outputs.cluster_id}: "shared"
      securityGroupSelector:
        karpenter.sh/discovery: "${data.terraform_remote_state.eks.outputs.cluster_id}"
      instanceProfile: "${aws_iam_instance_profile.karpenter.name}"
      tags:
        Name: "${var.project}-${var.env}-eks-spark-driver"
        karpenter.sh/discovery: "${data.terraform_remote_state.eks.outputs.cluster_id}"
    ttlSecondsAfterEmpty: 300
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_spark_executor_provisioner" {
  yaml_body = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: spark-executor
  spec:
    labels:
      sparkRole: executor
    requirements:
      - key: "topology.kubernetes.io/zone"
        operator: In
        values: ["eu-west-1a"]
      - key: "karpenter.sh/capacity-type"
        operator: In
        values: ["spot"]
      - key: karpenter.k8s.aws/instance-family
        operator: In
        values: [m5, r5, r6]
      - key: karpenter.k8s.aws/instance-size
        operator: In
        values: [small, large, xlarge, 2xlarge]
    limits:
      resources:
        cpu: "1000"
        memory: 1000Gi
    provider:
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: 200Gi
            volumeType: gp3
            iops: 10000
            deleteOnTermination: true
            throughput: 125
      subnetSelector:
        kubernetes.io/cluster/${data.terraform_remote_state.eks.outputs.cluster_id}: "shared"
      securityGroupSelector:
        karpenter.sh/discovery: "${data.terraform_remote_state.eks.outputs.cluster_id}"
      instanceProfile: "${aws_iam_instance_profile.karpenter.name}"
      tags:
        Name: "${var.project}-${var.env}-eks-spark-executor"
        karpenter.sh/discovery: "${data.terraform_remote_state.eks.outputs.cluster_id}"
    ttlSecondsAfterEmpty: 180
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}