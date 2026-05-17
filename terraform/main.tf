terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_config_map" "gsx_config" {
  metadata {
    name = "gsx-config"
  }
  data = {
    BACKEND_PORT = "3000"
    NGINX_PORT   = "80"
  }
}


resource "kubernetes_deployment" "backend" {
  metadata {
    name = "backend"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "backend"
      }
    }
    template {
      metadata {
        labels = {
          app = "backend"
        }
      }
      spec {
        container {
          name  = "python-backend"
          image = "${var.docker_username}/app-simple:v1"
	  image_pull_policy = "Never"          
	  port {
            container_port = 3000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "backend" {
  metadata {
    name = "backend"
  }
  spec {
    selector = {
      app = "backend"
    }
    port {
      port        = 3000
      target_port = 3000
    }
  }
}

# Nginx: Deployment i Service
resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      spec {
        container {
          name  = "web-nginx"
          image = "${var.docker_username}/nginx-gsx:v1"
          image_pull_policy = "Never"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx"
  }
  spec {
    selector = {
      app = "nginx"
    }
    port {
      port        = 80
      target_port = 80
    }
  }
}
