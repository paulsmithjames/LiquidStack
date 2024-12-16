;; Loan Contract

(define-map loans
  { loan-id: uint }
  {
    borrower: principal,
    amount: uint,
    collateral: uint,
    interest-rate: uint,
    start-block: uint,
    duration: uint,
    status: (string-ascii 20)
  }
)

(define-data-var next-loan-id uint u0)

(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-loan (err u101))
(define-constant err-loan-not-active (err u102))

(define-public (create-loan (amount uint) (collateral uint) (interest-rate uint) (duration uint))
  (let
    (
      (loan-id (var-get next-loan-id))
    )
    (try! (contract-call? .lending-pool borrow amount))
    (try! (stx-transfer? collateral tx-sender (as-contract tx-sender)))
    (map-set loans
      { loan-id: loan-id }
      {
        borrower: tx-sender,
        amount: amount,
        collateral: collateral,
        interest-rate: interest-rate,
        start-block: block-height,
        duration: duration,
        status: "active"
      }
    )
    (var-set next-loan-id (+ loan-id u1))
    (ok loan-id)
  )
)

(define-public (repay-loan (loan-id uint))
  (let
    (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) err-invalid-loan))
    )
    (asserts! (is-eq (get borrower loan) tx-sender) err-unauthorized)
    (asserts! (is-eq (get status loan) "active") err-loan-not-active)
    (let
      (
        (repayment-amount (+ (get amount loan) (calculate-interest loan)))
      )
      (try! (contract-call? .lending-pool repay repayment-amount))
      (try! (as-contract (stx-transfer? (get collateral loan) tx-sender tx-sender)))
      (map-set loans
        { loan-id: loan-id }
        (merge loan { status: "repaid" })
      )
      (ok true)
    )
  )
)

(define-private (calculate-interest (loan {borrower: principal, amount: uint, collateral: uint, interest-rate: uint, start-block: uint, duration: uint, status: (string-ascii 20)}))
  (let
    (
      (blocks-elapsed (- block-height (get start-block loan)))
      (interest-per-block (/ (* (get amount loan) (get interest-rate loan)) u10000))
    )
    (* blocks-elapsed interest-per-block)
  )
)

(define-read-only (get-loan (loan-id uint))
  (ok (unwrap! (map-get? loans { loan-id: loan-id }) err-invalid-loan))
)

(define-public (update-loan-status (loan-id uint) (new-status (string-ascii 20)))
  (let
    (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) err-invalid-loan))
    )
    (asserts! (or (is-eq tx-sender (get borrower loan)) (is-eq tx-sender (as-contract tx-sender))) err-unauthorized)
    (ok (map-set loans
      { loan-id: loan-id }
      (merge loan { status: new-status })
    ))
  )
)

