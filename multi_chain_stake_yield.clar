(define-map stakes
  ((user principal))
  ((amount uint) (last-claim uint)))

(define-constant reward-rate u10) ;; 10 tokens per block per 1000 staked

(define-public (stake-btc (amount uint))
  (begin
    (stx-transfer? amount tx-sender (as-contract tx-sender))
    (map-set stakes (tuple (user tx-sender))
             (tuple (amount amount) (last-claim (block-height))))
    (ok true)))

(define-read-only (get-reward (user principal))
  (let (
        (stake-info (map-get? stakes (tuple (user user))))
        (now (block-height))
      )
    (match stake-info
      info
      (let (
            (blocks (- now (get last-claim info)))
            (reward (/ (* blocks (get amount info) reward-rate) u1000))
          )
        reward)
      u0)))

(define-public (claim-yield)
  (let (
        (reward (get-reward tx-sender))
      )
    (begin
      ;; In real implementation: Mint/transfer sBTC or other yield token
      (map-set stakes (tuple (user tx-sender))
               (tuple (amount (get amount (unwrap! (map-get? stakes (tuple (user tx-sender))) (err "Not staked"))))
                      (last-claim (block-height))))
      (ok reward))))

(define-public (unstake-btc)
  (let (
        (stake-info (map-get? stakes (tuple (user tx-sender))))
      )
    (match stake-info
      info
      (begin
        (stx-transfer? (get amount info) (as-contract tx-sender) tx-sender)
        (map-delete stakes (tuple (user tx-sender)))
        (ok true))
      (err "No stake found"))))
