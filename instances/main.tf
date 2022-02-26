module "ap-southeast-2" {
  source = "./modules/inst"
  region = "ap-southeast-2"
}

module "us-west-1" {
  source = "./modules/inst"
  region = "us-west-1"
}

output "ap-southeast-2_public_ips" {
  value = module.ap-southeast-2.public_ip
}

output "us-west-1_public_ips" {
  value = module.us-west-1.public_ip
}
