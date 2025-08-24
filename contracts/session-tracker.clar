;; Crisis Intervention Alert System Contract
;; Emergency alert system for mental health crisis situations

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-not-found (err u301))
(define-constant err-unauthorized (err u302))
(define-constant err-invalid-priority (err u303))
(define-constant err-already-responded (err u304))

;; Data Variables
(define-data-var next-alert-id uint u1)
(define-data-var emergency-threshold uint u10) ;; minutes

;; Data Maps
(define-map crisis-alerts
  { alert-id: uint }
  {
    reporter: principal,
    priority-level: uint,
    location-hash: (buff 32),
    situation-hash: (buff 32),
    timestamp: uint,
    status: (string-ascii 20),
    responder: (optional principal),
    response-time: (optional uint)
  }
)

(define-map crisis-responders
  { responder: principal }
  {
    certified: bool,
    specializations: (list 3 (string-ascii 50)),
    response-count: uint,
    avg-response-time: uint,
    active-status: bool
  }
)

(define-map alert-responses
  { alert-id: uint, responder: principal }
  {
    response-type: (string-ascii 30),
    action-taken: (buff 32),
    outcome-hash: (buff 32),
    responded-at: uint
  }
)

(define-map escalation-protocols
  { protocol-id: uint }
  {
    priority-level: uint,
    max-response-time: uint,
    required-responders: uint,
    escalation-contacts: (list 3 principal)
  }
)

;; Responder Management Functions
(define-public (register-responder (specializations (list 3 (string-ascii 50))))
  (begin
    (map-set crisis-responders
      { responder: tx-sender }
      {
        certified: false,
        specializations: specializations,
        response-count: u0,
        avg-response-time: u0,
        active-status: true
      }
    )
    (ok true)
  )
)

(define-public (certify-responder (responder principal))
  (let
    (
      (responder-data (unwrap! (map-get? crisis-responders { responder: responder }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set crisis-responders
      { responder: responder }
      (merge responder-data { certified: true })
    )
    (ok true)
  )
)

(define-public (toggle-responder-status)
  (let
    (
      (responder-data (unwrap! (map-get? crisis-responders { responder: tx-sender }) err-not-found))
    )
    (map-set crisis-responders
      { responder: tx-sender }
      (merge responder-data { active-status: (not (get active-status responder-data)) })
    )
    (ok true)
  )
)

;; Alert Management Functions
(define-public (create-crisis-alert (priority-level uint) (location-hash (buff 32)) (situation-hash (buff 32)))
  (let
    (
      (alert-id (var-get next-alert-id))
    )
    (asserts! (and (>= priority-level u1) (<= priority-level u5)) err-invalid-priority)
    (map-set crisis-alerts
      { alert-id: alert-id }
      {
        reporter: tx-sender,
        priority-level: priority-level,
        location-hash: location-hash,
        situation-hash: situation-hash,
        timestamp: stacks-block-height,
        status: "active",
        responder: none,
        response-time: none
      }
    )
    (var-set next-alert-id (+ alert-id u1))
    (ok alert-id)
  )
)

(define-public (respond-to-alert (alert-id uint) (response-type (string-ascii 30)) (action-taken (buff 32)))
  (let
    (
      (alert (unwrap! (map-get? crisis-alerts { alert-id: alert-id }) err-not-found))
      (responder-data (unwrap! (map-get? crisis-responders { responder: tx-sender }) err-not-found))
      (response-time (- stacks-block-height (get timestamp alert)))
    )
    (asserts! (get certified responder-data) err-unauthorized)
    (asserts! (get active-status responder-data) err-unauthorized)
    (asserts! (is-eq (get status alert) "active") err-already-responded)
    
    ;; Update alert with responder info
    (map-set crisis-alerts
      { alert-id: alert-id }
      (merge alert {
        status: "responding",
        responder: (some tx-sender),
        response-time: (some response-time)
      })
    )
    
    ;; Record response details
    (map-set alert-responses
      { alert-id: alert-id, responder: tx-sender }
      {
        response-type: response-type,
        action-taken: action-taken,
        outcome-hash: 0x,
        responded-at: stacks-block-height
      }
    )
    
    ;; Update responder statistics
    (map-set crisis-responders
      { responder: tx-sender }
      (merge responder-data {
        response-count: (+ (get response-count responder-data) u1),
        avg-response-time: (calculate-avg-response-time responder-data response-time)
      })
    )
    
    (ok true)
  )
)

(define-public (close-alert (alert-id uint) (outcome-hash (buff 32)))
  (let
    (
      (alert (unwrap! (map-get? crisis-alerts { alert-id: alert-id }) err-not-found))
      (responder (unwrap! (get responder alert) err-unauthorized))
    )
    (asserts! (is-eq tx-sender responder) err-unauthorized)
    (asserts! (is-eq (get status alert) "responding") err-unauthorized)
    
    ;; Update alert status
    (map-set crisis-alerts
      { alert-id: alert-id }
      (merge alert { status: "resolved" })
    )
    
    ;; Update response outcome
    (match (map-get? alert-responses { alert-id: alert-id, responder: responder })
      response (map-set alert-responses
                 { alert-id: alert-id, responder: responder }
                 (merge response { outcome-hash: outcome-hash }))
      false
    )
    
    (ok true)
  )
)

;; Protocol Management Functions
(define-public (create-escalation-protocol (priority-level uint) (max-response-time uint) (required-responders uint) (escalation-contacts (list 3 principal)))
  (let
    (
      (protocol-id (var-get next-alert-id))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set escalation-protocols
      { protocol-id: protocol-id }
      {
        priority-level: priority-level,
        max-response-time: max-response-time,
        required-responders: required-responders,
        escalation-contacts: escalation-contacts
      }
    )
    (ok protocol-id)
  )
)

;; Read-only Functions
(define-read-only (get-crisis-alert (alert-id uint))
  (map-get? crisis-alerts { alert-id: alert-id })
)

(define-read-only (get-responder-profile (responder principal))
  (map-get? crisis-responders { responder: responder })
)

(define-read-only (get-alert-response (alert-id uint) (responder principal))
  (map-get? alert-responses { alert-id: alert-id, responder: responder })
)

(define-read-only (is-responder-available (responder principal))
  (match (map-get? crisis-responders { responder: responder })
    responder-data (and (get certified responder-data) (get active-status responder-data))
    false
  )
)

(define-read-only (get-emergency-threshold)
  (var-get emergency-threshold)
)

;; Private Functions
(define-private (calculate-avg-response-time (responder-data { certified: bool, specializations: (list 3 (string-ascii 50)), response-count: uint, avg-response-time: uint, active-status: bool }) (new-response-time uint))
  (let
    (
      (current-count (get response-count responder-data))
      (current-avg (get avg-response-time responder-data))
    )
    (if (is-eq current-count u0)
      new-response-time
      (/ (+ (* current-avg current-count) new-response-time) (+ current-count u1))
    )
  )
)