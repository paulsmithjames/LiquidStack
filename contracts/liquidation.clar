;; Liquidation Contract

(define-constant liquidation-threshold u7500) ;; 75% collateralization ratio
(define-constant liquidation-bonus u200) ;; 2% bonus for liquidators

(define-public (liquidate (loan-id uint))
(let
  (
    (loan (unwrap! (contract-call? .loan get-loan loan-id) err-invalid-loan))
    (current-price (unwrap! (contract-call? .price-oracle get-price) err-price-not-available))
  )
  (asserts! (is-eq (get status loan) "active") err-loan-not-active)
  (asserts! (< (* (get collateral loan) current-price) (* (get amount loan) liquidation-threshold)) err-not-liquidatable)
  (let
    (
      (liquidation-amount (/ (* (get amount loan) liquidation-threshold) u10000))
      (reward (/ (* liquidation-amount liquidation-bonus) u10000))
    )
    (try! (stx-transfer? (+ liquidation-amount reward) tx-sender (as-contract tx-sender)))
    (try! (as-contract (stx-transfer? (get collateral loan) tx-sender (get borrower loan))))
    (try! (contract-call? .loan update-loan-status loan-id "liquidated"))
    (ok true)
  )
)
)

(define-constant err-invalid-loan (err u100))
(define-constant err-loan-not-active (err u101))
(define-constant err-price-not-available (err u102))
(define-constant err-not-liquidatable (err u103))
(define-constant err-unauthorized (err u104))

