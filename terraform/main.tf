# Terraform configuration for dotNOVI application on Kubernetes
# This demonstrates Infrastructure as Code principles

terraform {
  required_version = ">= 1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  # Backend configuration (uncomment for production)
  # backend "s3" {
  #   bucket  = "dotnovi-terraform-state"
  #   key     = "kubernetes/dotnovi.tfstate"
  #   region  = "eu-west-1"
  #   encrypt = true
  # }
}

# Configure Kubernetes provider
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

# Configure Helm provider
provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig_path
    config_context = var.kubeconfig_context
  }
}

# Variables
variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "docker-desktop"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "dotnovi"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "dotnovi"
}

variable "docker_image" {
  description = "Docker image URL"
  type        = string
  default     = "dotnovi:latest"
}

variable "replicas" {
  description = "Number of pod replicas (initial; HPA owns this after create)"
  type        = number
  default     = 5
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "database_url" {
  description = "PostgreSQL connection string"
  type        = string
  sensitive   = true
  default     = "postgresql://dotnovi:dotnovi123@postgres.dotnovi.svc.cluster.local:5432/dotnovi"
}

# Database credentials — kept as discrete vars so the Postgres deployment and
# the connection string stay in sync. Change these together.
variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "dotnovi"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
  default     = "dotnovi123"
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "dotnovi"
}

# Namespace
resource "kubernetes_namespace" "dotnovi" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# ConfigMap
resource "kubernetes_config_map" "dotnovi_config" {
  metadata {
    name      = "${var.app_name}-config"
    namespace = kubernetes_namespace.dotnovi.metadata[0].name
  }

  data = {
    NODE_ENV  = var.environment
    PORT      = "3000"
    LOG_LEVEL = "info"
  }
}

# Secret
resource "kubernetes_secret" "dotnovi_secrets" {
  metadata {
    name      = "${var.app_name}-secrets"
    namespace = kubernetes_namespace.dotnovi.metadata[0].name
  }

  type = "Opaque"

  # Provider base64-encodes values for you; pass the raw string.
  data = {
    database-url = var.database_url
  }
}

# Service Account
resource "kubernetes_service_account" "dotnovi" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.dotnovi.metadata[0].name
  }
}

# -----------------------------------------------------------------------------
# PostgreSQL (dev-only: emptyDir storage, data is lost when the pod restarts)
# The Service MUST be named "postgres" so it resolves as
# postgres.dotnovi.svc.cluster.local, which is what DATABASE_URL points at.
# -----------------------------------------------------------------------------
resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.dotnovi.metadata[0].name
    labels = {
      app = "postgres"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    # Single-writer database on a single volume: never run two at once.
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:18-alpine"

          port {
            name           = "postgres"
            container_port = 5432
          }

          env {
            name  = "POSTGRES_USER"
            value = var.postgres_user
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = var.postgres_password
          }
          env {
            name  = "POSTGRES_DB"
            value = var.postgres_db
          }
          # Keep PGDATA in a subdirectory of the mount to avoid lost+found issues.
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", var.postgres_user, "-d", var.postgres_db]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 6
          }

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", var.postgres_user, "-d", var.postgres_db]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }

        # Dev storage. Swap for a PersistentVolumeClaim to keep data across restarts.
        volume {
          name = "data"
          empty_dir {}
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.dotnovi]
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.dotnovi.metadata[0].name
    labels = {
      app = "postgres"
    }
  }

  spec {
    selector = {
      app = "postgres"
    }

    port {
      name        = "postgres"
      port        = 5432
      target_port = "postgres"
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.postgres]
}

# Deployment
resource "kubernetes_deployment" "dotnovi" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.dotnovi.metadata[0].name
    labels = {
      app = var.app_name
    }
  }

  spec {
    replicas = var.replicas

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = 1
        max_unavailable = 0
      }
    }

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        service_account_name = kubernetes_service_account.dotnovi.metadata[0].name

        container {
          name              = var.app_name
          image             = var.docker_image
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 3000
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.dotnovi_config.metadata[0].name
            }
          }

          env {
            name = "DATABASE_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.dotnovi_secrets.metadata[0].name
                key  = "database-url"
              }
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path   = "/health"
              port   = "http"
              scheme = "HTTP"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path   = "/health"
              port   = "http"
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 2
          }

          security_context {
            run_as_non_root            = true
            run_as_user                = 1001
            allow_privilege_escalation = false
            read_only_root_filesystem  = false
            capabilities {
              drop = ["ALL"]
            }
          }
        }

        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                label_selector {
                  match_expressions {
                    key      = "app"
                    operator = "In"
                    values   = [var.app_name]
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }
      }
    }
  }

  # HPA owns replica count after creation; don't let Terraform fight it on every apply.
  lifecycle {
    ignore_changes = [spec[0].replicas]
  }

  # Ensure the Postgres Service (and its DNS name) exists before the app rolls out.
  depends_on = [
    kubernetes_namespace.dotnovi,
    kubernetes_service.postgres,
  ]
}

# Service
resource "kubernetes_service" "dotnovi" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.dotnovi.metadata[0].name
    labels = {
      app = var.app_name
    }
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      name        = "http"
      port        = 80
      target_port = "http"
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment.dotnovi]
}

# Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v2" "dotnovi" {
  metadata {
    name      = "${var.app_name}-hpa"
    namespace = kubernetes_namespace.dotnovi.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.dotnovi.metadata[0].name
    }

    min_replicas = 3
    max_replicas = 10

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }
}

# Pod Disruption Budget
resource "kubernetes_pod_disruption_budget_v1" "dotnovi" {
  metadata {
    name      = "${var.app_name}-pdb"
    namespace = kubernetes_namespace.dotnovi.metadata[0].name
  }

  spec {
    min_available = 2
    selector {
      match_labels = {
        app = var.app_name
      }
    }
  }
}

# Outputs
output "namespace" {
  description = "Kubernetes namespace"
  value       = kubernetes_namespace.dotnovi.metadata[0].name
}

output "service_name" {
  description = "Service name"
  value       = kubernetes_service.dotnovi.metadata[0].name
}

output "service_external_ip" {
  description = "External IP of the service"
  value       = try(kubernetes_service.dotnovi.status[0].load_balancer[0].ingress[0].ip, null)
}

output "deployment_name" {
  description = "Deployment name"
  value       = kubernetes_deployment.dotnovi.metadata[0].name
}
