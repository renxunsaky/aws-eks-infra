locals {
  hostname = "kube-ops-view.${var.dns_domain_suffix}"
}

resource "helm_release" "kube_ops_view" {
  namespace        = "kube-system"
  create_namespace = false

  name       = "kube-ops-view"
  repository = "https://christianknell.github.io/helm-charts"
  chart      = "kube-ops-view"
  version    = "v1.1.5"

  values = [<<-EOT
            image:
              tag: "latest"
            ingress:
              enabled: true
              annotations:
                alb.ingress.kubernetes.io/target-type: "ip"
                alb.ingress.kubernetes.io/ssl-redirect: "443"
                alb.ingress.kubernetes.io/group.name: "${var.project}-${var.env}-eks-${var.tenant}"
                alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}]'
                alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
                kubernetes.io/ingress.class: "alb"
                external-dns.alpha.kubernetes.io/hostname: "${local.hostname}"
              hosts:
              - host: "${local.hostname}"
                paths:
                - path: "/"
                  pathType: Prefix
            nodeSelector:
              eks.amazonaws.com/nodegroup: "${local.core_node_name}"
            EOT
  ]
}