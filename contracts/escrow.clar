;; Define the contract
(define-constant taskpay-admin tx-sender)

;; Data structures
(define-data-var current-job-id uint u0)

(define-map jobs
  uint ;; job-id
  {
    client: principal,
    provider: (optional principal),
    name: (string-utf8 100),
    scope: (string-utf8 500),
    payment: uint,
    task-count: uint,
    completed-tasks: uint,
    is-finalized: bool
  }
)

(define-map task-details
  { job-id: uint, task-id: uint }
  {
    scope: (string-utf8 200),
    is-accepted: bool,
    is-compensated: bool
  }
)

;; Errors
(define-constant err-not-authorized (err u100))
(define-constant err-job-not-found (err u101))
(define-constant err-task-not-found (err u102))
(define-constant err-invalid-provider (err u103))
(define-constant err-task-already-accepted (err u104))
(define-constant err-task-already-compensated (err u105))
(define-constant err-job-already-finalized (err u106))
(define-constant err-invalid-input (err u107))
(define-constant err-task-id-out-of-range (err u108))

;; Create a new job
(define-public (create-job (name (string-utf8 100)) (scope (string-utf8 500)) (payment uint) (total-tasks uint))
  (let ((new-job-id (+ (var-get current-job-id) u1)))
    ;; Validate inputs
    (asserts! (is-eq tx-sender taskpay-admin) err-not-authorized)
    (asserts! (> (len name) u0) err-invalid-input)
    (asserts! (> (len scope) u0) err-invalid-input)
    (asserts! (> payment u0) err-invalid-input)
    (asserts! (> total-tasks u0) err-invalid-input)
    
    ;; Create the job entry
    (map-set jobs new-job-id
      {
        client: tx-sender,
        provider: none,
        name: name,
        scope: scope,
        payment: payment,
        task-count: total-tasks,
        completed-tasks: u0,
        is-finalized: false
      }
    )
    (var-set current-job-id new-job-id)
    (ok new-job-id)
  )
)

;; Assign a provider to a job
(define-public (assign-provider (job-id uint) (provider principal))
  (let ((job (map-get? jobs job-id)))
    ;; Validate inputs
    (asserts! (> job-id u0) err-invalid-input)
    (asserts! (is-some job) err-job-not-found)
    (asserts! (is-eq (get client (unwrap-panic job)) tx-sender) err-not-authorized)
    (asserts! (not (is-eq provider tx-sender)) err-invalid-input)
    
    ;; Update job with provider
    (map-set jobs job-id
      (merge (unwrap-panic job)
        {
          provider: (some provider)
        }
      )
    )
    (ok true)
  )
)

;; Submit a task
(define-public (submit-task (job-id uint) (task-id uint) (scope (string-utf8 200)))
  (let ((job (map-get? jobs job-id)))
    ;; Validate inputs
    (asserts! (> job-id u0) err-invalid-input)
    (asserts! (is-some job) err-job-not-found)
    (asserts! (is-eq (get provider (unwrap-panic job)) (some tx-sender)) err-invalid-provider)
    (asserts! (< task-id (get task-count (unwrap-panic job))) err-task-id-out-of-range)
    (asserts! (> (len scope) u0) err-invalid-input)
    
    ;; Create task submission
    (map-set task-details { job-id: job-id, task-id: task-id }
      {
        scope: scope,
        is-accepted: false,
        is-compensated: false
      }
    )
    (ok true)
  )
)

;; Accept a task
(define-public (accept-task (job-id uint) (task-id uint))
  (let ((job (map-get? jobs job-id))
        (task (map-get? task-details { job-id: job-id, task-id: task-id })))
    ;; Validate inputs
    (asserts! (> job-id u0) err-invalid-input)
    (asserts! (is-some job) err-job-not-found)
    (asserts! (< task-id (get task-count (unwrap-panic job))) err-task-id-out-of-range)
    (asserts! (is-some task) err-task-not-found)
    (asserts! (is-eq (get client (unwrap-panic job)) tx-sender) err-not-authorized)
    (asserts! (not (get is-accepted (unwrap-panic task))) err-task-already-accepted)
    
    ;; Mark task as accepted and update completion count
    (map-set task-details { job-id: job-id, task-id: task-id }
      (merge (unwrap-panic task)
        {
          is-accepted: true
        }
      )
    )
    (map-set jobs job-id
      (merge (unwrap-panic job)
        {
          completed-tasks: (+ (get completed-tasks (unwrap-panic job)) u1)
        }
      )
    )
    (ok true)
  )
)

;; Release compensation for a task
(define-public (release-payment (job-id uint) (task-id uint))
  (let ((job (map-get? jobs job-id))
        (task (map-get? task-details { job-id: job-id, task-id: task-id })))
    ;; Validate inputs
    (asserts! (> job-id u0) err-invalid-input)
    (asserts! (is-some job) err-job-not-found)
    (asserts! (< task-id (get task-count (unwrap-panic job))) err-task-id-out-of-range)
    (asserts! (is-some task) err-task-not-found)
    (asserts! (is-eq (get client (unwrap-panic job)) tx-sender) err-not-authorized)
    (asserts! (get is-accepted (unwrap-panic task)) err-task-not-found)
    (asserts! (not (get is-compensated (unwrap-panic task))) err-task-already-compensated)
    
    ;; Mark task as compensated
    (map-set task-details { job-id: job-id, task-id: task-id }
      (merge (unwrap-panic task)
        {
          is-compensated: true
        }
      )
    )
    (ok true)
  )
)

;; Mark job as finalized
(define-public (finalize-job (job-id uint))
  (let ((job (map-get? jobs job-id)))
    ;; Validate inputs
    (asserts! (> job-id u0) err-invalid-input)
    (asserts! (is-some job) err-job-not-found)
    (asserts! (is-eq (get client (unwrap-panic job)) tx-sender) err-not-authorized)
    (asserts! (not (get is-finalized (unwrap-panic job))) err-job-already-finalized)
    (asserts! (is-eq (get completed-tasks (unwrap-panic job)) (get task-count (unwrap-panic job))) err-not-authorized)
    
    ;; Mark job as finalized
    (map-set jobs job-id
      (merge (unwrap-panic job)
        {
          is-finalized: true
        }
      )
    )
    (ok true)
  )
)

;; Helper function to get job details
(define-read-only (get-job-details (job-id uint))
  (asserts! (> job-id u0) err-invalid-input)
  (map-get? jobs job-id)
)

;; Helper function to get task details
(define-read-only (get-task-details (job-id uint) (task-id uint))
  (asserts! (> job-id u0) err-invalid-input)
  (map-get? task-details { job-id: job-id, task-id: task-id })
)