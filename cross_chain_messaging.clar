(define-constant admin 'SP3FBR2AGK8X9Z0EWTJ1NVG5KJ0WR6Y6TKY0KP27B) ;; Replace with bridge admin address

(define-map btc-locks
  ((user principal))
  ((amount uint) (destination-chain (buff 32)) (timestamp uint)))

(define-event btc-locked (user principal) (amount uint) (destination (buff 32)))
(define-event btc-unlocked (user principal) (amount uint))

(define-public (lock-btc (destination (buff 32)) (amount uint))
  (begin
    (asserts! (> amount u0) (err u100)) ;; Error code 100: Invalid amount
    (stx-transfer? amount tx-sender (as-contract tx-sender)) ;; lock the BTC
    (map-set btc-locks 
      (tuple (user tx-sender))
      (tuple (amount amount) (destination-chain destination) (timestamp (block-height))))
    (emit-event btc-locked tx-sender amount destination)
    (ok true)))

(define-public (get-lock-info (user principal))
  (map-get? btc-locks (tuple (user user))))

(define-public (unlock-btc (user principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender admin) (err u401)) ;; Error code 401: Unauthorized
    (asserts! (> amount u0) (err u100))
    (stx-transfer? amount (as-contract tx-sender) user)
    (emit-event btc-unlocked user amount)
    (ok true)))

