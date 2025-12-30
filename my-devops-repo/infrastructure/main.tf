terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

# Point Terraform to your MicroK8s config file
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Create a new Namespace called 'devops-learning'
resource "kubernetes_namespace_v1" "learning" {
  metadata {
    name = "devops-learning"
  }
}

# 1. Define the Nginx Deployment
resource "kubernetes_deployment_v1" "nginx" {
  metadata {
    name   = "nginx-server"
    labels = { app = "nginx" }
  }

  spec {
    replicas = 5
    selector {
      match_labels = { app = "nginx" }
    }

    template {
      metadata {
        labels = { app = "nginx" }
      }

      spec {
        container {
          image = "nginx:1.21.6"
          name  = "nginx-container"

          # This is where the magic happens:
          volume_mount {
            name       = "config-volume"
            mount_path = "/usr/share/nginx/html/index.html"
            sub_path   = "WELCOME_MSG" # The key we defined in Ansible
          }
        }

        # Define the volume source (The ConfigMap from Ansible)
        volume {
          name = "config-volume"
          config_map {
            name = "app-settings" # Must match the name in your Ansible playbook
          }
        }
      }
    }
  }
}

# 2. Define the Service to expose Nginx
resource "kubernetes_service_v1" "nginx_service" {
  metadata {
    name = "nginx-service"
  }

  spec {
    selector = {
      app = kubernetes_deployment_v1.nginx.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "NodePort" # Best for local testing on a laptop
  }
}
