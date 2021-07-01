locals {
  applications = [for app in var.applications : lower(app)]
}

module "emr-sgs" {
  source                        = "./modules/aws-emr-sgs"
  applications                  = local.applications
  emr_managed_master_sg_name    = var.emr_managed_master_sg_name
  emr_managed_core_sg_name      = var.emr_managed_core_sg_name
  emr_additional_master_sg_name = var.emr_additional_master_sg_name
  emr_additional_core_sg_name   = var.emr_additional_core_sg_name
  emr_service_access_sg_name    = var.emr_service_access_sg_name
  vpc_id                        = var.vpc_id
  tamr_cidrs                    = var.tamr_cidrs
  tamr_sgs                      = var.tamr_sgs
  enable_http_port              = var.enable_http_port
  additional_tags               = var.additional_tags
}

module "emr-iam" {
  source = "./modules/aws-emr-iam"

  s3_bucket_name_for_logs           = var.bucket_name_for_logs
  s3_bucket_name_for_root_directory = var.bucket_name_for_root_directory
  s3_policy_arns                    = var.s3_policy_arns
  emr_ec2_iam_policy_name           = var.emr_ec2_iam_policy_name
  emr_service_iam_policy_name       = var.emr_service_iam_policy_name
  emr_service_role_name             = var.emr_service_role_name
  emr_ec2_instance_profile_name     = var.emr_ec2_instance_profile_name
  emr_ec2_role_name                 = var.emr_ec2_role_name
  additional_tags                   = var.additional_tags
  arn_partition                     = var.arn_partition

}

module "emr-cluster-config" {
  source                         = "./modules/aws-emr-config"
  create_static_cluster          = var.create_static_cluster
  cluster_name                   = var.cluster_name
  emr_config_file_path           = var.emr_config_file_path
  bucket_name_for_root_directory = var.bucket_name_for_root_directory
  hbase_config_path              = var.hbase_config_path
  hadoop_config_path             = var.hadoop_config_path
  json_configuration_bucket_key  = var.json_configuration_bucket_key
  utility_script_bucket_key      = var.utility_script_bucket_key
}

module "emr-cluster" {
  source = "./modules/aws-emr-cluster"

  depends_on = [module.emr-cluster-config]

  # Cluster configuration
  create_static_cluster          = var.create_static_cluster
  cluster_name                   = var.cluster_name
  release_label                  = var.release_label
  json_configuration_bucket_key  = module.emr-cluster-config.json_config_s3_key
  utility_script_bucket_key      = module.emr-cluster-config.upload_config_script_s3_key
  applications                   = local.applications
  bucket_name_for_root_directory = var.bucket_name_for_root_directory
  bucket_name_for_logs           = var.bucket_name_for_logs
  bucket_path_to_logs            = var.bucket_path_to_logs
  bootstrap_actions              = var.bootstrap_actions

  # Cluster instances
  subnet_id                                         = var.subnet_id
  key_pair_name                                     = var.key_pair_name
  master_instance_fleet_name                        = var.master_instance_fleet_name
  master_instance_type                              = var.master_instance_type
  master_instance_on_demand_count                   = var.master_instance_on_demand_count
  master_instance_spot_count                        = var.master_instance_spot_count
  master_bid_price                                  = var.master_bid_price
  master_bid_price_as_percentage_of_on_demand_price = var.master_bid_price_as_percentage_of_on_demand_price
  master_ebs_volumes_count                          = var.master_ebs_volumes_count
  master_ebs_type                                   = var.master_ebs_type
  master_ebs_size                                   = var.master_ebs_size
  master_block_duration_minutes                     = var.master_block_duration_minutes
  master_timeout_action                             = var.master_timeout_action
  master_timeout_duration_minutes                   = var.master_timeout_duration_minutes
  core_instance_fleet_name                          = var.core_instance_fleet_name
  core_instance_type                                = var.core_instance_type
  core_instance_on_demand_count                     = var.core_instance_on_demand_count
  core_instance_spot_count                          = var.core_instance_spot_count
  core_bid_price                                    = var.core_bid_price
  core_bid_price_as_percentage_of_on_demand_price   = var.core_bid_price_as_percentage_of_on_demand_price
  core_ebs_volumes_count                            = var.core_ebs_volumes_count
  core_ebs_type                                     = var.core_ebs_type
  core_ebs_size                                     = var.core_ebs_size
  core_block_duration_minutes                       = var.core_block_duration_minutes
  core_timeout_action                               = var.core_timeout_action
  core_timeout_duration_minutes                     = var.core_timeout_duration_minutes
  custom_ami_id                                     = var.custom_ami_id

  # Security groups
  emr_managed_master_sg_id    = module.emr-sgs.emr_managed_master_sg_id
  emr_additional_master_sg_id = module.emr-sgs.emr_additional_master_sg_id
  emr_managed_core_sg_id      = module.emr-sgs.emr_managed_core_sg_id
  emr_additional_core_sg_id   = module.emr-sgs.emr_additional_core_sg_id
  emr_service_access_sg_id    = module.emr-sgs.emr_service_access_sg_id

  # IAM
  emr_service_role_arn         = module.emr-iam.emr_service_role_arn
  emr_ec2_instance_profile_arn = module.emr-iam.emr_ec2_instance_profile_arn

  additional_tags = var.additional_tags
}
