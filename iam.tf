resource "aws_iam_role" "default_role" {
  name = "test"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          },
          "Effect" : "Allow",
          "Sid" : ""
        }
      ]
    }
  )
  tags = merge(
    local.common_tags,
    map(
      "Name", "test",
    )
  )
}

resource "aws_iam_instance_profile" "default_profile" {
  name = "test"
  role = aws_iam_role.default_role.name
}

# ---- attach the basic AWS managed SSM EC2 policies ---------------------------
resource "aws_iam_role_policy_attachment" "default_amzn_ssm_instance_core" {
  role       = aws_iam_role.default_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "default_policy_allow_all_ssm" {
  name = "secretmanagerpolicy"
  role = aws_iam_role.default_role.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "secretsmanager:GetSecretValue",
          "Resource" : [
            data.aws_secretsmanager_secret_version.creds.arn,
            data.aws_secretsmanager_secret.adunjoin.arn
          ]
        }
      ]
    }
  )
}


resource "aws_iam_role" "cloudwatch_event" {
  name = "cloudwatch-event"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "events.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy" "policy_cloudwatch" {
  name = "cloudwatch-policy"
  role = aws_iam_role.cloudwatch_event.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "ssm:StartAutomationExecution",
          "Effect" : "Allow",
          "Resource" : [
            "arn:aws:ssm:ap-southeast-2:${local.account_id}:automation-definition/ad-domain-unjoin:$DEFAULT"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role" "ssm" {
  name = "ssm-assumerole"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "",
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ssm.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )
}
resource "aws_iam_role_policy" "ssm" {
  name = "ssm-assumerole-policy"
  role = aws_iam_role.ssm.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "VisualEditor0",
          "Effect" : "Allow",
          "Action" : [
            "ssm:ListDocumentVersions",
            "ssm:GetDefaultPatchBaseline",
            "ssm:SendCommand",
            "ssm:DescribeDocument",
            "ssm:DescribeMaintenanceWindowTasks",
            "ssm:GetPatchBaselineForPatchGroup",
            "ssm:ListInstanceAssociations",
            "ssm:GetParameter",
            "ssm:DescribeMaintenanceWindowExecutions",
            "ssm:GetMaintenanceWindowTask",
            "ssm:GetDocument",
            "ssm:GetParametersByPath",
            "ssm:GetMaintenanceWindow",
            "ssm:DescribeInstanceAssociationsStatus",
            "ssm:GetPatchBaseline",
            "ssm:DescribeAssociation",
            "ssm:GetParameterHistory",
            "ssm:DescribeMaintenanceWindowTargets",
            "ssm:DescribeEffectiveInstanceAssociations",
            "ssm:GetParameters",
            "ssm:GetOpsSummary",
            "ssm:StartAutomationExecution",
            "ssm:ListTagsForResource",
            "ssm:DescribeDocumentParameters",
            "ssm:DescribeEffectivePatchesForPatchBaseline",
            "ssm:GetServiceSetting",
            "ssm:DescribeDocumentPermission",
            "ssm:GetCalendarState"
          ],
          "Resource" : "*"
        },
        {
          "Sid" : "VisualEditor1",
          "Effect" : "Allow",
          "Action" : [
            "ssm:GetAutomationExecution",
            "ssm:DescribePatchGroups",
            "ssm:ListCommands",
            "ssm:DescribeMaintenanceWindowSchedule",
            "ssm:ListAssociationVersions",
            "ssm:DescribeInstancePatches",
            "ssm:PutConfigurePackageResult",
            "ssm:DescribePatchGroupState",
            "ssm:GetMaintenanceWindowExecutionTaskInvocation",
            "ssm:DescribeAutomationExecutions",
            "ssm:GetManifest",
            "ssm:DescribeMaintenanceWindowExecutionTaskInvocations",
            "ssm:DescribeMaintenanceWindowExecutionTasks",
            "ssm:DescribeAutomationStepExecutions",
            "ssm:DescribeInstancePatchStates",
            "ssm:DescribeInstancePatchStatesForPatchGroup",
            "ssm:DescribeParameters",
            "ssm:ListResourceDataSync",
            "ssm:GetInventorySchema",
            "ssm:ListDocuments",
            "ssm:DescribeMaintenanceWindowsForTarget",
            "ssm:DescribeAssociationExecutionTargets",
            "ssm:DescribeInstanceProperties",
            "ssm:ListInventoryEntries",
            "ssm:ListComplianceItems",
            "ssm:GetConnectionStatus",
            "ssm:GetMaintenanceWindowExecutionTask",
            "ssm:GetDeployablePatchSnapshotForInstance",
            "ssm:GetOpsItem",
            "ssm:DescribeSessions",
            "ssm:GetMaintenanceWindowExecution",
            "ssm:DescribePatchBaselines",
            "ssm:DescribeInventoryDeletions",
            "ssm:ListResourceComplianceSummaries",
            "ssm:DescribePatchProperties",
            "ssm:GetInventory",
            "ssm:DescribeActivations",
            "ssm:DescribeOpsItems",
            "ssm:GetCommandInvocation",
            "ssm:ListComplianceSummaries",
            "ssm:DescribeInstanceInformation",
            "ssm:DescribeMaintenanceWindows",
            "ssm:DescribeAssociationExecutions",
            "ssm:ListAssociations",
            "ssm:ListCommandInvocations",
            "ssm:DescribeAvailablePatches"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}
