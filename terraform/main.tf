resource "docker_network" "nginx" {
  name   = "${var.project_name}-network"
  driver = "bridge"

  labels {
    label = "managed-by"
    value = "terraform"
  }
}

resource "docker_volume" "nginx_html" {
  name = "${var.project_name}-nginx-html"

  labels {
    label = "managed-by"
    value = "terraform"
  }
}

resource "docker_image" "nginx" {
  name         = var.nginx_image
  keep_locally = false
}

resource "docker_container" "nginx" {
  name    = "${var.project_name}-nginx"
  image   = docker_image.nginx.image_id
  restart = "unless-stopped"

  ports {
    internal = 80
    external = var.external_port
    protocol = "tcp"
  }

  networks_advanced {
    name = docker_network.nginx.name
  }

  volumes {
    volume_name    = docker_volume.nginx_html.name
    container_path = "/usr/share/nginx/html"
  }

  upload {
    file    = "/usr/share/nginx/html/index.html"
    content = <<-HTML
      <!doctype html>
      <html lang="en">
        <head><meta charset="utf-8"><title>Terraform nginx</title></head>
        <body><h1>Terraform nginx works</h1><p>This container uses its own Docker network and named volume.</p></body>
      </html>
    HTML
  }

  labels {
    label = "managed-by"
    value = "terraform"
  }
}
