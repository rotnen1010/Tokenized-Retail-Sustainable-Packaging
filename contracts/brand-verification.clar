;; Brand Verification Contract
;; Validates consumer goods companies for sustainable packaging program

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-verified (err u101))
(define-constant err-not-verified (err u102))

;; Data structures
(define-map verified-brands principal {
  company-name: (string-ascii 100),
  verification-date: uint,
  sustainability-score: uint,
  verified: bool
})

(define-map brand-applications principal {
  company-name: (string-ascii 100),
  application-date: uint,
  status: (string-ascii 20)
})

;; Read-only functions
(define-read-only (is-brand-verified (brand principal))
  (match (map-get? verified-brands brand)
    brand-data (get verified brand-data)
    false
  )
)

(define-read-only (get-brand-info (brand principal))
  (map-get? verified-brands brand)
)

(define-read-only (get-application-status (brand principal))
  (map-get? brand-applications brand)
)

;; Public functions
(define-public (apply-for-verification (company-name (string-ascii 100)))
  (begin
    (map-set brand-applications tx-sender {
      company-name: company-name,
      application-date: block-height,
      status: "pending"
    })
    (ok true)
  )
)

(define-public (verify-brand (brand principal) (company-name (string-ascii 100)) (sustainability-score uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (is-brand-verified brand)) err-already-verified)
    (map-set verified-brands brand {
      company-name: company-name,
      verification-date: block-height,
      sustainability-score: sustainability-score,
      verified: true
    })
    (map-set brand-applications brand {
      company-name: company-name,
      application-date: block-height,
      status: "approved"
    })
    (ok true)
  )
)

(define-public (revoke-verification (brand principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-brand-verified brand) err-not-verified)
    (map-delete verified-brands brand)
    (ok true)
  )
)
