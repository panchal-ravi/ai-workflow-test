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
4. **Update Issue with Progress**: Comment on the issue at the start and completion of each Github spec-kit stage with a short summary and link to the generated artifacts:
   - Format: `🤖 **[Stage Name]** - [Started/Completed]: Brief summary`

## Execution Workflow
0. Create a new git branch off the main branch for the work to be done. Name the branch using the format feature/<descriptive-name>.
1. Generate Terraform code to implement the feature as per the GitHub issue description.
2. Commit and update GH ISSUE with summary of changes made. 
3. Request user to review and approve the code.
4. Update Git issue with user details and approval status.
5. Update Git issue with comment "@copilot run review-tf-design agent to review the changes". This should trigger copilot coding agent to create a PR and review the code changes.