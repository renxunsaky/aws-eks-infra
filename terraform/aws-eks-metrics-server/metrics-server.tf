locals {
  core_node_name = "${var.project}-${var.env}-${var.core_node_group_name_suffix}"
}

resource "helm_release" "metrics-server" {
  namespace        = "kube-system"
  create_namespace = false

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.8.2"

  values = [
    yamlencode({"nodeSelector": {"eks.amazonaws.com/nodegroup": local.core_node_name}})
  ]
}
