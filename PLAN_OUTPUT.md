# PLAN_OUTPUT.md

## Terraform Plan

El siguiente resultado corresponde a la ejecución del comando:

```bash
terraform plan
```

desde el directorio:

```text
environments/dev
```

---

```text
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_s3_bucket.data_lake_raw will be created
  + resource "aws_s3_bucket" "data_lake_raw" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      + arn                         = (known after apply)
      + bucket                      = "coderhouse-datalake-raw-pre-entrega1-sbustos-2026"
      + bucket_domain_name          = (known after apply)
      + bucket_prefix               = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = true
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + object_lock_enabled         = (known after apply)
      + policy                      = (known after apply)
      + region                      = (known after apply)
      + request_payer               = (known after apply)
      + tags                        = {
          + "Environment" = "dev"
          + "Project"     = "pre-entrega1"
        }
      + tags_all                    = {
          + "Environment" = "dev"
          + "Project"     = "pre-entrega1"
        }
      + website_domain              = (known after apply)
      + website_endpoint            = (known after apply)

      + cors_rule (known after apply)

      + grant (known after apply)

      + lifecycle_rule (known after apply)

      + logging (known after apply)

      + object_lock_configuration (known after apply)

      + replication_configuration (known after apply)

      + server_side_encryption_configuration (known after apply)

      + versioning (known after apply)

      + website (known after apply)
    }

  # module.identity.aws_iam_policy.audit_read_only will be created
  + resource "aws_iam_policy" "audit_read_only" {
      + arn              = (known after apply)
      + attachment_count = (known after apply)
      + id               = (known after apply)
      + name             = "pre-entrega1-dev-audit-read-only"
      + name_prefix      = (known after apply)
      + path             = "/"
      + policy           = (known after apply)
      + policy_id        = (known after apply)
      + tags_all         = {
          + "Environment" = "dev"
          + "Project"     = "pre-entrega1"
        }
    }

  # module.identity.aws_iam_policy.data_processing_s3 will be created
  + resource "aws_iam_policy" "data_processing_s3" {
      + arn              = (known after apply)
      + attachment_count = (known after apply)
      + id               = (known after apply)
      + name             = "pre-entrega1-dev-s3-processing-policy"
      + name_prefix      = (known after apply)
      + path             = "/"
      + policy           = (known after apply)
      + policy_id        = (known after apply)
      + tags_all         = {
          + "Environment" = "dev"
          + "Project"     = "pre-entrega1"
        }
    }

  # module.identity.aws_iam_role.audit will be created
  + resource "aws_iam_role" "audit" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + Service = [
                              + "lambda.amazonaws.com",
                            ]
                        }
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "pre-entrega1-dev-audit-role"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags                  = {
          + "Environment" = "dev"
          + "Project"     = "pre-entrega1"
        }
      + tags_all              = {
          + "Environment" = "dev"
          + "Project"     = "pre-entrega1"
        }
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # module.identity.aws_iam_role.data_processing will be created
  + resource "aws_iam_role" "data_processing" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + Service = [
                              + "lambda.amazonaws.com",
                            ]
                        }
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "pre-entrega1-dev-data-processing-role"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags                  = {
          + "Environment" = "dev"
          + "Project"     = "pre-entrega1"
        }
      + tags_all              = {
          + "Environment" = "dev"
          + "Project"     = "pre-entrega1"
        }
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # module.identity.aws_iam_role_policy_attachment.audit will be created
  + resource "aws_iam_role_policy_attachment" "audit" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = "pre-entrega1-dev-audit-role"
    }

  # module.identity.aws_iam_role_policy_attachment.data_processing will be created
  + resource "aws_iam_role_policy_attachment" "data_processing" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = "pre-entrega1-dev-data-processing-role"
    }

  # module.network.aws_route_table.private will be created
  + resource "aws_route_table" "private" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = (known after apply)
      + tags             = {
          + "Name" = "pre-entrega1-private-route-table"
        }
      + tags_all         = {
          + "Environment" = "dev"
          + "Name"        = "pre-entrega1-private-route-table"
          + "Project"     = "pre-entrega1"
        }
      + vpc_id           = (known after apply)
    }

  # module.network.aws_route_table_association.private["private-1"] will be created
  + resource "aws_route_table_association" "private" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.network.aws_route_table_association.private["private-2"] will be created
  + resource "aws_route_table_association" "private" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.network.aws_subnet.private["private-1"] will be created
  + resource "aws_subnet" "private" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.1.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Environment" = "dev"
          + "Name"        = "pre-entrega1-private-1"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "Name"        = "pre-entrega1-private-1"
          + "Project"     = "pre-entrega1"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.network.aws_subnet.private["private-2"] will be created
  + resource "aws_subnet" "private" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1b"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.2.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Environment" = "dev"
          + "Name"        = "pre-entrega1-private-2"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "Name"        = "pre-entrega1-private-2"
          + "Project"     = "pre-entrega1"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.network.aws_vpc.main will be created
  + resource "aws_vpc" "main" {
      + arn                                  = (known after apply)
      + cidr_block                           = "10.0.0.0/16"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_dns_hostnames                 = true
      + enable_dns_support                   = true
      + enable_network_address_usage_metrics = (known after apply)
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + tags                                 = {
          + "Environment" = "dev"
          + "Name"        = "pre-entrega1-vpc"
        }
      + tags_all                             = {
          + "Environment" = "dev"
          + "Name"        = "pre-entrega1-vpc"
          + "Project"     = "pre-entrega1"
        }
    }

  # module.network.aws_vpc_endpoint.s3 will be created
  + resource "aws_vpc_endpoint" "s3" {
      + arn                   = (known after apply)
      + cidr_blocks           = (known after apply)
      + dns_entry             = (known after apply)
      + id                    = (known after apply)
      + ip_address_type       = (known after apply)
      + network_interface_ids = (known after apply)
      + owner_id              = (known after apply)
      + policy                = (known after apply)
      + prefix_list_id        = (known after apply)
      + private_dns_enabled   = (known after apply)
      + requester_managed     = (known after apply)
      + route_table_ids       = (known after apply)
      + security_group_ids    = (known after apply)
      + service_name          = "com.amazonaws.us-east-1.s3"
      + service_region        = (known after apply)
      + state                 = (known after apply)
      + subnet_ids            = (known after apply)
      + tags                  = {
          + "Name" = "pre-entrega1-s3-endpoint"
        }
      + tags_all              = {
          + "Environment" = "dev"
          + "Name"        = "pre-entrega1-s3-endpoint"
          + "Project"     = "pre-entrega1"
        }
      + vpc_endpoint_type     = "Gateway"
      + vpc_id                = (known after apply)

      + dns_options (known after apply)

      + subnet_configuration (known after apply)
    }

Plan: 14 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + audit_role_arn           = (known after apply)
  + bucket_name              = "coderhouse-datalake-raw-pre-entrega1-sbustos-2026"
  + data_processing_role_arn = (known after apply)
  + private_subnets_id       = [
      + (known after apply),
      + (known after apply),
    ]
  + vpc_id                   = (known after apply)

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.

```