resource "google_compute_network" "vpc" {
  name                    = var.name
  project                 = var.project
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}

resource "google_compute_router" "vpc_router" {
  name = "${var.name}-router"

  project = var.project
  region  = var.region
  network = google_compute_network.vpc.self_link
}

resource "google_compute_subnetwork" "public_subnet" {
  count = len(var.public_subnet_cidr_blocks)
  name = "${var.name}-public-subnet"

  project = var.project
  region  = var.region
  network = google_compute_network.vpc.self_link

  private_ip_google_access = true
  ip_cidr_range            = var.public_subnet_cidr_blocks[count.index]
}

resource "google_compute_router_nat" "vpc_nat" {
  name = "${var.name}-nat"

  project = var.project
  region  = var.region
  router  = google_compute_router.vpc_router.name

  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.public_subnet.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_subnetwork" "private_subnet" {
  count = len(var.private_subnet_cidr_blocks)
  name = "${var.name}-private-subnet"

  project = var.project
  region  = var.region
  network = google_compute_network.vpc.self_link

  private_ip_google_access = true
  ip_cidr_range = var.private_subnet_cidr_blocks[count.index]
}
