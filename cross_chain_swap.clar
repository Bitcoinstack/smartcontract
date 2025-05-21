(define-map swaps
  ((sender principal) (receiver principal))
  ((amount uint) (hashlock (buff 32)) (timelock uint) (claimed bool)))

(define-public (initiate-swap (receiver principal) (hashlock (buff 32)) (timelock uint) (amount uint))
  (begin
    (asserts! (> timelock (block-height)) (err "Timelock must be in the future"))
    (stx-transfer? amount tx-sender (as-contract tx-sender))
    (map-set swaps (tuple (sender tx-sender) (receiver receiver))
             (tuple (amount amount) (hashlock hashlock) (timelock timelock) (claimed false)))
    (ok true)))

(define-public (redeem-swap (sender principal) (receiver principal) (preimage (buff 32)))
  (let (
        (key (tuple (sender sender) (receiver receiver)))
        (swap (map-get? swaps key))
        (now (block-height))
      )
    (match swap
      swap-data
      (begin
        (asserts! (not (get claimed swap-data)) (err "Already claimed"))
        (asserts! (< now (get timelock swap-data)) (err "Timelock expired"))
        (asserts! (is-eq (sha256 preimage) (get hashlock swap-data)) (err "Invalid preimage"))
        (stx-transfer? (get amount swap-data) (as-contract tx-sender) receiver)
        (map-set swaps key (merge swap-data (tuple (claimed true))))
        (ok true))
      (err "Swap not found"))))

(define-public (refund-swap (receiver principal))
  (let (
        (key (tuple (sender tx-sender) (receiver receiver)))
        (swap (map-get? swaps key))
        (now (block-height))
      )
    (match swap
      swap-data
      (begin
        (asserts! (not (get claimed swap-data)) (err "Already claimed"))
        (asserts! (>= now (get timelock swap-data)) (err "Timelock not expired"))
        (stx-transfer? (get amount swap-data) (as-contract tx-sender) tx-sender)
        (ok true))
      (err "Swap not found"))))
