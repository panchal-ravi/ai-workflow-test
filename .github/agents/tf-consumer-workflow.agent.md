---
name: tf-consumer-workflow
description: Orchestrates the full workflow from design to implementation for infrastructure provisioning using Terraform. Manages GitHub issues and coordinates subagents for each stage.
model: Claude Sonnet 4.5 (copilot)
---

## User Input

```text
$ARGUMENTS
```/

## Execution Workflow
1. Create a new GH ISSUE for creating an AWS IAM role with access to only EC2 resources.
2. Generate Terraform code to create the IAM role with least privilege access to EC2.
3. Commit and update GH ISSUE with summary of changes made. 
4. Request user to review and approve the code
5. Upon approval, create a PULL REQUEST with the Terraform code changes.
6. Delegate the PR review to Copilot coding agent using review-tf-design agent. Update PR with the review summary.