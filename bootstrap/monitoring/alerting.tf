locals {
  rules = {
    "Container cpu throttling is high" = {
      description                  = "Alert when container is being throttled > 25% of the time for more than 5 minutes"
      violation_time_limit_seconds = 21600
      query                        = "from K8sContainerSample select sum(containerCpuCfsThrottledPeriodsDelta) / sum(containerCpuCfsPeriodsDelta) * 100 where clusterName in ('${var.cluster_name}') facet containerName, podName, namespaceName, clusterName"
      critical = {
        operator              = "above"
        threshold             = 90
        threshold_duration    = 300
        threshold_occurrences = "all"
      }
    }

    "Container high cpu utilization" = {
      description                  = "Alert when the average container cpu utilization (vs. Limit) is > 90% for more than 5 minutes"
      violation_time_limit_seconds = 21600
      query                        = "from K8sContainerSample select average(cpuCoresUtilization) where clusterName in ('${var.cluster_name}') facet containerName, podName, namespaceName, clusterName"
      critical = {
        operator              = "above"
        threshold             = 90
        threshold_duration    = 300
        threshold_occurrences = "all"
      }
    }

    "Container high memory utilization" = {
      description                  = "Alert when the average container memory utilization (vs. Limit) is > 90% for more than 5 minutes"
      violation_time_limit_seconds = 21600
      query                        = "from K8sContainerSample select average(memoryWorkingSetUtilization) where clusterName in ('${var.cluster_name}') facet containerName, podName, namespaceName, clusterName"
      critical = {
        operator              = "above"
        threshold             = 90
        threshold_duration    = 300
        threshold_occurrences = "all"
      }
    }

    "Container is Restarting" = {
      description                  = "Alert when the container restart count is greater than 0 in a sliding 5 minute window"
      violation_time_limit_seconds = 21600
      query                        = "from K8sContainerSample select sum(restartCountDelta) where clusterName in ('${var.cluster_name}') FACET containerName, podName, namespaceName, clusterName"
      critical = {
        operator              = "above"
        threshold             = 0
        threshold_duration    = 300
        threshold_occurrences = "all"
      }
    }

    "Container is Waiting" = {
      description                  = "Alert when a container is Waiting for more than 5 minutes"
      violation_time_limit_seconds = 21600
      query                        = "from K8sContainerSample select uniqueCount(podName) WHERE status = 'Waiting' and clusterName in ('${var.cluster_name}') FACET containerName, podName, namespaceName, clusterName"
      critical = {
        operator              = "above"
        threshold             = 0
        threshold_duration    = 300
        threshold_occurrences = "all"
      }
    }

    "Daemonset is missing Pods" = {
      description                  = "Alert when Daemonset is missing Pods for > 5 minutes"
      violation_time_limit_seconds = 21600
      query                        = "from K8sDaemonsetSample select latest(podsMissing) where clusterName in ('${var.cluster_name}') facet daemonsetName, namespaceName, clusterName"
      critical = {
        operator              = "above"
        threshold             = 0
        threshold_duration    = 300
        threshold_occurrences = "all"
      }
    }

    "Deployment is missing Pods" = {
      description                  = "Alert when Deployment is missing Pods for > 5 minutes"
      violation_time_limit_seconds = 21600
      query                        = "from K8sDeploymentSample select latest(podsMissing) where clusterName in ('${var.cluster_name}') facet deploymentName, namespaceName, clusterName"
      critical = {
        operator              = "above"
        threshold             = 0
        threshold_duration    = 300
        threshold_occurrences = "all"
      }
    }

    "Etcd file descriptor utilization is high" = {
      description                  = "Alert when Etcd file descriptor utilization is > 90% for more than 5 minutes"
      violation_time_limit_seconds = 21600
      query                        = "from K8sEtcdSample select max(processFdsUtilization) where clusterName in ('${var.cluster_name}') facet displayName, clusterName"
      critical = {
        operator              = "below"
        threshold             = 1
        threshold_duration    = 60
        threshold_occurrences = "all"
      }
    }

    "Etcd has no leader" = {
      description                  = "Alert when Etcd has no leader for more than 1 minute"
      violation_time_limit_seconds = 21600
      query                        = "from K8sEtcdSample select min(etcdServerHasLeader) where clusterName in ('${var.cluster_name}') facet displayName, clusterName"
      critical = {
        operator              = "below"
        threshold             = 1
        threshold_duration    = 60
        threshold_occurrences = "all"
      }
    }

    "HPA current replicas < desired replicas" = {
      description                  = "Alert when a Horizontal Pod Autoscaler's current replicas < desired replicas for > 5 minutes"
      violation_time_limit_seconds = 21600
      query                        = "FROM K8sHpaSample select latest(desiredReplicas - currentReplicas) where clusterName in ('${var.cluster_name}') facet displayName, namespaceName, clusterName"
      critical = {
        operator              = "equals"
        threshold             = 0
        threshold_duration    = 300
        threshold_occurrences = "all"
      }
    }

    "HPA has reached maximum replicas" = {
      description                  = "Alert when a Horizontal Pod Autoscaler has reached its maximum replicas for > 5"
      violation_time_limit_seconds = 21600
      query                        = "FROM K8sHpaSample select latest(maxReplicas - currentReplicas) where clusterName in ('${var.cluster_name}') facet displayName, namespaceName, clusterName"
      critical = {
        operator              = "equals"
        threshold             = 0
        threshold_duration    = 300
        threshold_occurrences = "all"
      }
    }

    "Job Failed" = {
      description                  = "Alert when a Job reports a failed status"
      violation_time_limit_seconds = 21600
      query                        = "from K8sJobSample select uniqueCount(jobName) where failed = 'true' and clusterName in ('${var.cluster_name}') facet jobName, namespaceName, clusterName, failedPodsReason"
      critical = {
        operator              = "above"
        threshold             = 0
        threshold_duration    = 60
        threshold_occurrences = "at_least_once"
      }
    }

    "Node is not ready" = {
      description                  = "Alert when a Node is not ready for > 5 minutes"
      violation_time_limit_seconds = 21600
      query                        = "from K8sNodeSample select latest(condition.Ready) where clusterName in ('${var.cluster_name}') facet nodeName, clusterName"
      critical = {
        operator              = "below"
        threshold             = 1
        threshold_duration    = 300
        threshold_occurrences = "all"
      }
    }

    "Node root file system capacity utilization is high" = {
      description                  = "Alert when the average Node root file system capacity utilization is > 90% for more than 5 minutes"
      violation_time_limit_seconds = 21600
      query                        = "from K8sNodeSample select average(fsCapacityUtilization) where clusterName in ('${var.cluster_name}') facet nodeName, clusterName"
      critical = {
        operator              = "above"
        threshold             = 90
        threshold_duration    = 300
        threshold_occurrences = "all"
      }
    }

    "Persistent Volume has errors" = {
      description                  = "Alert when Persistent Volume is in a Failed or Pending state for more than 5 minutes"
      violation_time_limit_seconds = 21600
      query                        = "from K8sPersistentVolumeSample select uniqueCount(volumeName) where statusPhase in ('Failed','Pending') and clusterName in ('${var.cluster_name}') facet volumeName, clusterName"
      critical = {
        operator              = "above"
        threshold             = 0
        threshold_duration    = 300
        threshold_occurrences = "all"
      }
    }

    "Pod cannot be scheduled" = {
      description                  = "Alert when a Pod cannot be scheduled for more than 5 minutes"
      violation_time_limit_seconds = 21600
      query                        = "from K8sPodSample select latest(isScheduled) where clusterName in ('${var.cluster_name}') facet podName, namespaceName, clusterName"
      critical = {
        operator              = "below"
        threshold             = 1
        threshold_duration    = 300
        threshold_occurrences = "all"
      }
    }

    "Pod is not ready" = {
      description                  = "Alert when a Pod is not ready for > 5 minutes"
      violation_time_limit_seconds = 21600
      query                        = "FROM K8sPodSample select latest(isReady) where status not in ('Failed', 'Succeeded') where clusterName in ('${var.cluster_name}') facet podName, namespaceName, clusterName"
      critical = {
        operator              = "below"
        threshold             = 1
        threshold_duration    = 300
        threshold_occurrences = "all"
      }
    }

    "Statefulset is missing Pods" = {
      description                  = "Alert when Statefulset is missing Pods for > 5 minutes"
      violation_time_limit_seconds = 21600
      query                        = "from K8sStatefulsetSample select latest(podsMissing) where clusterName in ('${var.cluster_name}') facet daemonsetName, namespaceName, clusterName"
      critical = {
        operator              = "above"
        threshold             = 0
        threshold_duration    = 300
        threshold_occurrences = "all"
      }
    }
  }
}

resource "newrelic_alert_policy" "this" {
  name = var.cluster_name
}

resource "newrelic_nrql_alert_condition" "this" {
  for_each = local.rules

  policy_id = newrelic_alert_policy.this.id
  type      = "static"
  name      = each.key

  enabled                      = true
  violation_time_limit_seconds = each.value.violation_time_limit_seconds

  nrql {
    query           = each.value.query
    data_account_id = var.new_relic_account_id
  }

  critical {
    operator              = each.value.critical.operator
    threshold             = each.value.critical.threshold
    threshold_duration    = each.value.critical.threshold_duration
    threshold_occurrences = each.value.critical.threshold_occurrences
  }

  fill_option                    = "none"
  aggregation_window             = 300
  aggregation_method             = "event_flow"
  aggregation_delay              = 60
  slide_by                       = 60
  expiration_duration            = 300
  open_violation_on_expiration   = false
  close_violations_on_expiration = true
  ignore_on_expected_termination = false
}

resource "newrelic_notification_destination" "this" {
  name = "Notify admin"
  type = "MOBILE_PUSH"

  property {
    key   = "userId"
    value = var.new_relic_admin
  }
}

resource "newrelic_notification_channel" "this" {
  name           = "Notifications"
  type           = "MOBILE_PUSH"
  destination_id = newrelic_notification_destination.this.id
  product        = "IINT"

  property {
    key   = "foo"
    value = "bar"
  }
}

resource "newrelic_workflow" "workflow" {
  name                  = "Notify ${var.cluster_name}"
  enabled               = true
  muting_rules_handling = "DONT_NOTIFY_FULLY_MUTED_ISSUES"

  issues_filter {
    name = "workflow_filter"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.this.id]
    }
  }

  destination {
    channel_id              = newrelic_notification_channel.this.id
    notification_triggers   = ["ACKNOWLEDGED", "ACTIVATED", "CLOSED"]
    update_original_message = true
  }
}
