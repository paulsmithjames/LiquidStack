;; Price Oracle Contract

(define-data-var current-price uint u100000000) ;; Initial price: 1 STX = $1 (with 8 decimal places)
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))

(define-public (update-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (ok (var-set current-price new-price))
  )
)

(define-read-only (get-price)
  (ok (var-get current-price))
)

