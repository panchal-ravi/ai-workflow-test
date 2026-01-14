---
name: tf-consumer-workflow
description: Orchestrates the full workflow from design to implementation for infrastructure provisioning using Terraform. Manages GitHub issues and coordinates subagents for each stage.
model: Claude Sonnet 4.5 (copilot)
---

## User Input

```text
$ARGUMENTS
```


### GitHub Issue Setup

Before starting the workflow, create and configure a GitHub issue:

1. **Create GitHub Issue**: 
   - Use `gh issue create` with the user provided input 
   - Title format: `[AGENT PROVISION] <descriptive-name>`
   - Labels: `agent-driven`, `terraform`, `infrastructure`, `provisioning`
   - Populate all fields from the template 
2. **Validate Issue**: Confirm the GitHub issue is valid and contains all required information
3. **Mark as In Progress**: Add `in-progress` label when starting work using `gh issue edit <issue-number> --add-label "in-progress"`
4. **Update Issue with Progress**: Comment on the issue at the start and completion of each workflow stage with a short summary and link to the generated artifacts:
   - Format: `🤖 **[Stage Name]** - [Started/Completed]: Brief summary`

work on the GitHub issue autonomously

## Execution Workflow
1. Generate Terraform code as per the Git issue details.
2. Commit and update Git issue. 
3. Request user to review and approve the code
4. Upon approval, create a Git PR with the Terraform code changes.
5. Delegate and assign the PR review to Copilot coding agent using review-tf-design agent. 
6. Update PR with the Copilot review summary and findings.