module "ap-southeast-2" {
  source = "./modules/inst"
  region = "ap-southeast-2"
}

module "us-west-1" {
  source = "./modules/inst"
  region = "us-west-1"
}
