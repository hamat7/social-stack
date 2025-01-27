;; SocialStack - Decentralized Social Platform Built on Stacks
;; Author: Your Name
;; License: MIT

;; Constants
(define-constant contract-admin tx-sender)
(define-constant error-admin-only (err u100))
(define-constant error-not-token-owner (err u101))
(define-constant error-invalid-account (err u102))
(define-constant error-content-not-found (err u103))
(define-constant error-account-exists (err u104))
(define-constant error-content-limit (err u105))
(define-constant error-invalid-params (err u106))

;; Data Variables
(define-data-var content-id-counter uint u0)

;; Data Maps
(define-map Accounts 
    principal 
    { handle: (string-utf8 50),
      profile: (string-utf8 200),
      registration-height: uint }
)

(define-map Content 
    uint 
    { creator: principal,
      body: (string-utf8 1000),
      block-height: uint,
      rewards: uint }
)

(define-map AccountContent
    principal
    (list 50 uint)
)

(define-map Following
    { account: principal }
    (list 500 principal)
)

;; Data map for reactions
(define-map Reactions
    { content-id: uint }
    (list 200 { reactor: principal, message: (string-utf8 280), block-height: uint })
)

;; NFT Definition for Content
(define-non-fungible-token social-content uint)

;; Helper Functions
(define-private (validate-text (text (string-utf8 1000)))
    (and (>= (len text) u1) (<= (len text) u1000))
)

;; Public Functions

;; Register new account
(define-public (register-account (handle (string-utf8 50)) (profile (string-utf8 200)))
    (let ((account tx-sender))
        (asserts! (is-none (map-get? Accounts account)) error-account-exists)
        (asserts! (and (>= (len handle) u1) (<= (len handle) u50)) error-invalid-params)
        (asserts! (and (>= (len profile) u1) (<= (len profile) u200)) error-invalid-params)
        (ok (map-set Accounts 
            account 
            { handle: handle,
              profile: profile,
              registration-height: block-height }))
    )
)

;; Create new content
(define-public (publish-content (body (string-utf8 1000)))
    (let ((content-id (+ (var-get content-id-counter) u1))
          (account tx-sender)
          (existing-content (default-to (list) (map-get? AccountContent account))))
        (begin
            (asserts! (validate-text body) error-invalid-params)
            (asserts! (< (len existing-content) u50) error-content-limit)
            (try! (nft-mint? social-content content-id account))
            (map-set Content content-id
                { creator: account,
                  body: body,
                  block-height: block-height,
                  rewards: u0 })
            (var-set content-id-counter content-id)
            (match (as-max-len? (append existing-content content-id) u50)
                updated-list (ok (map-set AccountContent account updated-list))
                error-content-limit)
        )
    )
)

;; Reward content
(define-public (reward-content (content-id uint) (amount uint))
    (let ((content (unwrap! (map-get? Content content-id) error-content-not-found)))
        (let ((creator (get creator content))
              (current-rewards (get rewards content)))
            (begin
                (asserts! (> amount u0) error-invalid-params)
                (asserts! (is-some (map-get? Accounts creator)) error-invalid-account)
                (try! (stx-transfer? amount tx-sender creator))
                (ok (map-set Content content-id
                    (merge content { rewards: (+ current-rewards amount) })))
            )
        )
    )
)

;; Update account profile
(define-public (update-account (new-profile (string-utf8 200)))
    (let ((account-data (unwrap! (map-get? Accounts tx-sender) error-invalid-account)))
        (asserts! (and (>= (len new-profile) u1) (<= (len new-profile) u200)) error-invalid-params)
        (ok (map-set Accounts
            tx-sender
            (merge account-data { profile: new-profile })))
    )
)

