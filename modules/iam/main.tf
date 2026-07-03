locals {
  oidc_issuer_host = replace(var.oidc_provider_url, "https://", "")
}

# ---------------------------------------------------------------------------
# stagecraft-webhook — publishes to SQS only
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "webhook_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:sub"
      values   = ["system:serviceaccount:${var.namespace}:stagecraft-webhook"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "webhook" {
  name               = "${var.cluster_name}-webhook"
  assume_role_policy = data.aws_iam_policy_document.webhook_trust.json
}

resource "aws_iam_role_policy" "webhook_sqs" {
  name = "sqs-publish"
  role = aws_iam_role.webhook.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:SendMessage"]
      Resource = var.sqs_queue_arn
    }]
  })
}

# ---------------------------------------------------------------------------
# stagecraft-worker — consumes SQS, calls Bedrock, optionally SES + KB S3
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "worker_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:sub"
      values   = ["system:serviceaccount:${var.namespace}:stagecraft-worker"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "worker" {
  name               = "${var.cluster_name}-worker"
  assume_role_policy = data.aws_iam_policy_document.worker_trust.json
}

resource "aws_iam_role_policy" "worker_sqs" {
  name = "sqs-consume"
  role = aws_iam_role.worker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
      ]
      Resource = var.sqs_queue_arn
    }]
  })
}

resource "aws_iam_role_policy" "worker_bedrock" {
  name = "bedrock-invoke"
  role = aws_iam_role.worker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
      Resource = "arn:aws:bedrock:*::foundation-model/*"
    }]
  })
}

resource "aws_iam_role_policy" "worker_ses" {
  name = "ses-send"
  role = aws_iam_role.worker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ses:SendEmail", "ses:SendRawEmail"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "worker_kb_s3" {
  count = var.kb_s3_bucket_arn == "" ? 0 : 1
  name  = "knowledge-base-s3"
  role  = aws_iam_role.worker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject"]
      Resource = "${var.kb_s3_bucket_arn}/*"
    }]
  })
}

# ---------------------------------------------------------------------------
# stagecraft-api — publishes to SQS, calls Bedrock (Pipeline Chat)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "api_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:sub"
      values   = ["system:serviceaccount:${var.namespace}:stagecraft-api"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api" {
  name               = "${var.cluster_name}-api"
  assume_role_policy = data.aws_iam_policy_document.api_trust.json
}

resource "aws_iam_role_policy" "api_sqs" {
  name = "sqs-publish"
  role = aws_iam_role.api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:SendMessage"]
      Resource = var.sqs_queue_arn
    }]
  })
}

resource "aws_iam_role_policy" "api_bedrock" {
  name = "bedrock-invoke"
  role = aws_iam_role.api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
      Resource = "arn:aws:bedrock:*::foundation-model/*"
    }]
  })
}

# ---------------------------------------------------------------------------
# AWS Load Balancer Controller — required so the "expose via load balancer"
# requirement works; installed into the cluster via stagecraft-helm, this
# just provisions the IAM side. Policy JSON is the canonical upstream file —
# see modules/iam/policies/README.md for how to fetch/refresh it.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "lb_controller_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lb_controller" {
  name               = "${var.cluster_name}-lb-controller"
  assume_role_policy = data.aws_iam_policy_document.lb_controller_trust.json
}

resource "aws_iam_role_policy" "lb_controller" {
  name   = "aws-load-balancer-controller"
  role   = aws_iam_role.lb_controller.id
  policy = file("${path.module}/policies/aws-load-balancer-controller-policy.json")
}
