;; Lending Pool Contract

(define-data-var pool-balance uint u0)
(define-data-var total-borrowed uint u0)

(define-map user-deposits { user: principal } { amount: uint })
(define-map user-borrows { user: principal } { amount: uint })

(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-insufficient-funds (err u101))
(define-constant err-insufficient-liquidity (err u102))

(define-public (deposit (amount uint))
  (let
    (
      (current-deposit (default-to { amount: u0 } (map-get? user-deposits { user: tx-sender })))
    )
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set user-deposits
      { user: tx-sender }
      { amount: (+ (get amount current-deposit) amount) }
    )
    (var-set pool-balance (+ (var-get pool-balance) amount))
    (ok true)
  )
)

(define-public (withdraw (amount uint))
  (let
    (
      (current-deposit (default-to { amount: u0 } (map-get? user-deposits { user: tx-sender })))
    )
    (asserts! (<= amount (get amount current-deposit)) err-insufficient-funds)
    (asserts! (<= amount (- (var-get pool-balance) (var-get total-borrowed))) err-insufficient-liquidity)
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (map-set user-deposits
      { user: tx-sender }
      { amount: (- (get amount current-deposit) amount) }
    )
    (var-set pool-balance (- (var-get pool-balance) amount))
    (ok true)
  )
)

(define-public (borrow (amount uint))
  (let
    (
      (current-borrow (default-to { amount: u0 } (map-get? user-borrows { user: tx-sender })))
    )
    (asserts! (<= amount (- (var-get pool-balance) (var-get total-borrowed))) err-insufficient-liquidity)
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (map-set user-borrows
      { user: tx-sender }
      { amount: (+ (get amount current-borrow) amount) }
    )
    (var-set total-borrowed (+ (var-get total-borrowed) amount))
    (ok true)
  )
)

(define-public (repay (amount uint))
  (let
    (
      (current-borrow (default-to { amount: u0 } (map-get? user-borrows { user: tx-sender })))
    )
    (asserts! (<= amount (get amount current-borrow)) err-insufficient-funds)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set user-borrows
      { user: tx-sender }
      { amount: (- (get amount current-borrow) amount) }
    )
    (var-set total-borrowed (- (var-get total-borrowed) amount))
    (var-set pool-balance (+ (var-get pool-balance) amount))
    (ok true)
  )
)

(define-read-only (get-pool-balance)
  (ok (var-get pool-balance))
)

(define-read-only (get-total-borrowed)
  (ok (var-get total-borrowed))
)

(define-read-only (get-user-deposit (user principal))
  (ok (get amount (default-to { amount: u0 } (map-get? user-deposits { user: user }))))
)

(define-read-only (get-user-borrow (user principal))
  (ok (get amount (default-to { amount: u0 } (map-get? user-borrows { user: user }))))
)

