# StacksPay

TaskPay is a decentralized task management system built on the Stacks blockchain that enables secure, transparent freelance work arrangements between clients and service providers.

## Overview

TaskPay facilitates the entire workflow of task-based freelance work:

1. Clients create jobs with clear scope and payment terms
2. Clients assign providers to jobs
3. Providers submit completed tasks
4. Clients accept tasks and release payments
5. Jobs are finalized when all tasks are completed

The contract enforces trust and transparency throughout the process, ensuring providers get paid for approved work and clients only pay for satisfactory deliverables.

## Features

- **Job Creation**: Define project scope, payment, and number of tasks
- **Provider Assignment**: Designate who will work on the job
- **Task Management**: Submit, accept, and compensate individual tasks
- **Payment Protection**: Funds are only released upon client approval
- **Completion Tracking**: Monitor progress toward job completion
- **Finalization**: Close completed projects

## Contract Functions

### Administrative Functions

- `create-job`: Create a new job with name, scope, payment amount, and task count
- `assign-provider`: Assign a service provider to a specific job

### Provider Functions

- `submit-task`: Submit a completed task for a job

### Client Functions

- `accept-task`: Mark a task as accepted
- `release-payment`: Release payment for a completed task
- `finalize-job`: Mark a job as complete when all tasks are finished

### Read-Only Functions

- `get-job-details`: Retrieve all details about a specific job
- `get-task-details`: Retrieve details about a specific task

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Not authorized |
| u101 | Job not found |
| u102 | Task not found |
| u103 | Invalid provider |
| u104 | Task already accepted |
| u105 | Task already compensated |
| u106 | Job already finalized |
| u107 | Invalid input |
| u108 | Task ID out of range |

## Getting Started

### Prerequisites

- A Stacks wallet (e.g., Hiro Wallet)
- STX tokens for transaction fees

### Deployment

1. Deploy the contract to the Stacks blockchain
2. Initialize jobs through the contract functions
3. Assign providers to begin task submissions

## Example Workflow

1. Admin creates a job with 5 tasks worth 1000 STX
2. Admin assigns a developer as provider
3. Developer submits task #0 with scope details
4. Admin accepts the task
5. Admin releases payment for the task
6. Process repeats until all tasks are complete
7. Admin finalizes the job when all tasks are completed

## Security Considerations

- Only the job creator can accept tasks, release payments, and finalize jobs
- Only the assigned provider can submit tasks
- Tasks must be accepted before payments can be released
- Jobs can only be finalized when all tasks are completed

