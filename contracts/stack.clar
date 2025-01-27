;; SocialStack - Decentralized Social Platform Built on Stacks

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

;; Read-only functions

;; Get account profile
(define-read-only (get-account-profile (account principal))
    (map-get? Accounts account)
)

;; Get content details
(define-read-only (get-content (content-id uint))
    (map-get? Content content-id)
)

;; Get account's content
(define-read-only (get-account-content (account principal))
    (map-get? AccountContent account)
)

;; Follow an account
(define-public (follow-account (account-to-follow principal))
    (let ((current-account tx-sender)
          (current-following (default-to (list) 
            (map-get? Following { account: account-to-follow }))))
        (begin
            (asserts! (is-some (map-get? Accounts account-to-follow)) error-invalid-account)
            (asserts! (not (is-eq current-account account-to-follow)) error-invalid-params)
            (asserts! (is-none (index-of current-following current-account)) error-invalid-params)
            (match (as-max-len? (append current-following current-account) u500)
                updated-following (ok (map-set Following 
                    { account: account-to-follow }
                    updated-following))
                error-content-limit)
        )
    )
)

;; Get following for an account
(define-read-only (get-following (account principal))
    (default-to (list) (map-get? Following { account: account }))
)

;; Unfollow an account
(define-public (unfollow-account (account-to-unfollow principal))
    (let ((current-account tx-sender)
          (current-following (default-to (list) 
            (map-get? Following { account: account-to-unfollow }))))
        (begin
            (asserts! (is-some (map-get? Accounts account-to-unfollow)) error-invalid-account)
            (asserts! (is-some (index-of current-following current-account)) error-invalid-params)
            (ok (map-set Following 
                { account: account-to-unfollow }
                (filter not-current-account current-following)))
        )
    )
)

;; Helper function for unfollow-account
(define-private (not-current-account (account principal))
    (not (is-eq account tx-sender))
)

;; Add reaction to content
(define-public (add-reaction (content-id uint) (message (string-utf8 280)))
    (let ((content (unwrap! (map-get? Content content-id) error-content-not-found))
          (current-reactions (default-to (list) (map-get? Reactions { content-id: content-id })))
          (new-reaction { reactor: tx-sender, 
                         message: message, 
                         block-height: block-height }))
        (begin
            ;; Validate reaction message
            (asserts! (and (>= (len message) u1) (<= (len message) u280)) error-invalid-params)
            ;; Verify content exists before adding reaction
            (asserts! (is-some (map-get? Content content-id)) error-content-not-found)
            ;; Add reaction to list
            (match (as-max-len? (append current-reactions new-reaction) u200)
                updated-reactions (ok (map-set Reactions 
                    { content-id: content-id }
                    updated-reactions))
                error-content-limit)
        )
    )
)

;; Get reactions for content
(define-read-only (get-reactions (content-id uint))
    (default-to (list) (map-get? Reactions { content-id: content-id }))
)