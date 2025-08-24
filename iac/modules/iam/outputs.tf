# Author: tgibson
# Date: 08/23/25

output "instance_profile_name" { value = try(aws_iam_instance_profile.this.name, null) }
