data "http" "ai_bots_haproxy" {
  url = "https://raw.githubusercontent.com/ai-robots-txt/ai.robots.txt/main/haproxy-block-ai-bots.txt"
}

locals {
  raw_lines = compact(split("\n", trimspace(data.http.ai_bots_haproxy.response_body)))
  escaped = [for l in local.raw_lines : replace(l, "/([][{}()\\.*+?^$|])/", "\\\\$0")]
  agent_regex = format(".*(%s).*", join("|", local.escaped))

  crawler_rules = {
    matches = [
      {
        headers = [
          {
            type  = "RegularExpression"
            name  = "user-agent"
            value = local.agent_regex
          }
        ]
      }
    ]
    filters = [
      {
        type = "ExtensionRef"
        extensionRef = {
          group = "gateway.envoyproxy.io"
          kind  = "HTTPRouteFilter"
          name  = "robots"
        }
      }
    ]
  }
}


resource "kubectl_manifest" "crawler_filter" {
  yaml_body = yamlencode({
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "HTTPRouteFilter"
    metadata = {
      name      = "robots"
      namespace = var.namespace
    }
    spec = {
      type = "DirectResponse"
      directResponse = {
        contentType = "text/plain"
        statusCode  = 403
        body = {
          type   = "Inline"
          inline = "Forbidden"
        }
      }
    }
  })
}

