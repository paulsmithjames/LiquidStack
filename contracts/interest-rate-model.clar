;; Interest Rate Model Contract

(define-constant base-rate u200) ;; 2% base rate
(define-constant rate-multiplier u50) ;; 0.5% increase per 10% utilization

(define-read-only (calculate-interest-rate (total-borrowed uint) (pool-balance uint))
  (let
    (
      (utilization-rate (/ (* total-borrowed u10000) pool-balance))
      (variable-rate (* (/ utilization-rate u1000) rate-multiplier))
    )
    (+ base-rate variable-rate)
  )
)

