;; Consumer Education Contract
;; Provides sustainability information and rewards

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u500))
(define-constant err-not-found (err u501))
(define-constant err-already-completed (err u502))

;; Data structures
(define-map educational-content uint {
  title: (string-ascii 100),
  content-type: (string-ascii 20),
  sustainability-topic: (string-ascii 50),
  difficulty-level: uint,
  reward-points: uint,
  created-by: principal,
  creation-date: uint
})

(define-map user-progress principal {
  completed-modules: (list 20 uint),
  total-points: uint,
  level: uint,
  last-activity: uint
})

(define-map sustainability-tips uint {
  tip-text: (string-ascii 200),
  category: (string-ascii 30),
  impact-level: uint,
  created-date: uint
})

(define-map user-achievements principal {
  achievements: (list 10 (string-ascii 30)),
  badges-earned: uint,
  eco-warrior-level: uint
})

(define-data-var content-counter uint u0)
(define-data-var tip-counter uint u0)

;; Read-only functions
(define-read-only (get-educational-content (content-id uint))
  (map-get? educational-content content-id)
)

(define-read-only (get-user-progress (user principal))
  (map-get? user-progress user)
)

(define-read-only (get-sustainability-tip (tip-id uint))
  (map-get? sustainability-tips tip-id)
)

(define-read-only (get-user-achievements (user principal))
  (map-get? user-achievements user)
)

(define-read-only (calculate-user-level (points uint))
  (if (>= points u1000)
    u5
    (if (>= points u500)
      u4
      (if (>= points u200)
        u3
        (if (>= points u50)
          u2
          u1
        )
      )
    )
  )
)

;; Public functions
(define-public (create-educational-content
  (title (string-ascii 100))
  (content-type (string-ascii 20))
  (sustainability-topic (string-ascii 50))
  (difficulty-level uint)
  (reward-points uint))
  (let ((content-id (+ (var-get content-counter) u1)))
    (begin
      (map-set educational-content content-id {
        title: title,
        content-type: content-type,
        sustainability-topic: sustainability-topic,
        difficulty-level: difficulty-level,
        reward-points: reward-points,
        created-by: tx-sender,
        creation-date: block-height
      })
      (var-set content-counter content-id)
      (ok content-id)
    )
  )
)

(define-public (complete-module (content-id uint))
  (match (map-get? educational-content content-id)
    content-data
    (let ((current-progress (default-to {
            completed-modules: (list),
            total-points: u0,
            level: u1,
            last-activity: u0
          } (map-get? user-progress tx-sender)))
          (new-points (+ (get total-points current-progress) (get reward-points content-data)))
          (new-level (calculate-user-level new-points)))
      (begin
        (asserts! (is-none (index-of (get completed-modules current-progress) content-id)) err-already-completed)
        (map-set user-progress tx-sender {
          completed-modules: (unwrap-panic (as-max-len? (append (get completed-modules current-progress) content-id) u20)),
          total-points: new-points,
          level: new-level,
          last-activity: block-height
        })
        (ok new-points)
      )
    )
    err-not-found
  )
)

(define-public (add-sustainability-tip
  (tip-text (string-ascii 200))
  (category (string-ascii 30))
  (impact-level uint))
  (let ((tip-id (+ (var-get tip-counter) u1)))
    (begin
      (map-set sustainability-tips tip-id {
        tip-text: tip-text,
        category: category,
        impact-level: impact-level,
        created-date: block-height
      })
      (var-set tip-counter tip-id)
      (ok tip-id)
    )
  )
)

(define-public (award-achievement (user principal) (achievement (string-ascii 30)))
  (let ((current-achievements (default-to {
          achievements: (list),
          badges-earned: u0,
          eco-warrior-level: u1
        } (map-get? user-achievements user))))
    (begin
      (map-set user-achievements user {
        achievements: (unwrap-panic (as-max-len? (append (get achievements current-achievements) achievement) u10)),
        badges-earned: (+ (get badges-earned current-achievements) u1),
        eco-warrior-level: (get eco-warrior-level current-achievements)
      })
      (ok true)
    )
  )
)
