;; Clinical Data Monetization Smart Contract
;; Version: 1.1
;; Description: A comprehensive smart contract for monetizing clinical data
;; while ensuring privacy, compliance, and fair revenue distribution

;; =================
;; CONSTANTS & ERRORS
;; =================

;; Error constants
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))
(define-constant ERR-INVALID-AMOUNT (err u104))
(define-constant ERR-ACCESS-EXPIRED (err u105))
(define-constant ERR-INVALID-DURATION (err u106))
(define-constant ERR-DATA-NOT-AVAILABLE (err u107))
(define-constant ERR-INVALID-PERCENTAGE (err u108))
(define-constant ERR-PAYMENT-FAILED (err u109))
(define-constant ERR-ALREADY-PAID (err u110))
(define-constant ERR-INVALID-INPUT (err u111))
(define-constant ERR-INVALID-STRING (err u112))
(define-constant ERR-INVALID-DATA-ID (err u113))
(define-constant ERR-INVALID-ACCESS-TYPE (err u114))
(define-constant ERR-INVALID-RATING (err u115))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MIN-ACCESS-DURATION u86400) ;; 1 day in seconds
(define-constant MAX-ACCESS-DURATION u31536000) ;; 1 year in seconds
(define-constant PLATFORM-FEE-PERCENTAGE u5) ;; 5% platform fee
(define-constant MAX-REVENUE-SHARE u100) ;; 100% maximum revenue share
(define-constant MAX-DATA-ID u999999999) ;; Maximum allowed data ID
(define-constant MIN-TITLE-LENGTH u3)
(define-constant MIN-DESCRIPTION-LENGTH u10)
(define-constant MIN-CATEGORY-LENGTH u2)

;; =================
;; DATA VARIABLES
;; =================

;; Platform statistics
(define-data-var total-data-sets uint u0)
(define-data-var total-revenue uint u0)
(define-data-var platform-fee-collected uint u0)
(define-data-var contract-paused bool false)

;; =================
;; DATA MAPS
;; =================

;; Clinical data registry
(define-map clinical-data-registry
  { data-id: uint }
  {
    owner: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    price-per-access: uint,
    revenue-share-percentage: uint, ;; Percentage for data contributors
    total-earnings: uint,
    access-count: uint,
    is-active: bool,
    created-at: uint,
    updated-at: uint,
    compliance-verified: bool,
    anonymization-level: uint ;; 1-5 scale of anonymization
  }
)

;; Data access permissions
(define-map data-access-permissions
  { data-id: uint, accessor: principal }
  {
    granted-at: uint,
    expires-at: uint,
    access-type: (string-ascii 20), ;; "read", "analyze", "download"
    payment-amount: uint,
    is-active: bool
  }
)

;; User profiles for data providers
(define-map data-provider-profiles
  { provider: principal }
  {
    total-data-sets: uint,
    total-earnings: uint,
    reputation-score: uint, ;; 1-100 scale
    verified-status: bool,
    registration-date: uint
  }
)

;; Data consumer profiles
(define-map data-consumer-profiles
  { consumer: principal }
  {
    total-purchases: uint,
    total-spent: uint,
    access-history-count: uint,
    reputation-score: uint,
    registration-date: uint
  }
)

;; Revenue sharing records
(define-map revenue-shares
  { data-id: uint, contributor: principal }
  {
    share-percentage: uint,
    total-earned: uint,
    last-payout: uint
  }
)

;; Payment history
(define-map payment-history
  { payment-id: uint }
  {
    payer: principal,
    data-id: uint,
    amount: uint,
    platform-fee: uint,
    data-owner-share: uint,
    payment-date: uint,
    status: (string-ascii 20) ;; "completed", "pending", "failed"
  }
)

;; Data quality ratings
(define-map data-quality-ratings
  { data-id: uint, rater: principal }
  {
    quality-score: uint, ;; 1-10 scale
    completeness-score: uint, ;; 1-10 scale
    accuracy-score: uint, ;; 1-10 scale
    review-comment: (string-ascii 300),
    rating-date: uint
  }
)

;; =================
;; VALIDATION FUNCTIONS
;; =================

;; Validate string inputs
(define-private (is-valid-title (title (string-ascii 100)))
  (and (>= (len title) MIN-TITLE-LENGTH) (<= (len title) u100))
)

(define-private (is-valid-description (description (string-ascii 500)))
  (and (>= (len description) MIN-DESCRIPTION-LENGTH) (<= (len description) u500))
)

(define-private (is-valid-category (category (string-ascii 50)))
  (and (>= (len category) MIN-CATEGORY-LENGTH) (<= (len category) u50))
)

(define-private (is-valid-review-comment (comment (string-ascii 300)))
  (<= (len comment) u300)
)

;; Validate data ID
(define-private (is-valid-data-id (data-id uint))
  (and (> data-id u0) (<= data-id MAX-DATA-ID))
)

;; Validate access type
(define-private (is-valid-access-type (access-type (string-ascii 20)))
  (or (is-eq access-type "read")
      (is-eq access-type "analyze") 
      (is-eq access-type "download"))
)

;; Validate rating scores
(define-private (is-valid-rating-score (score uint))
  (and (>= score u1) (<= score u10))
)

;; =================
;; PRIVATE FUNCTIONS
;; =================

;; Generate unique data ID
(define-private (generate-data-id)
  (+ (var-get total-data-sets) u1)
)

;; Generate unique payment ID
(define-private (generate-payment-id)
  (+ burn-block-height (var-get total-revenue))
)

;; Validate revenue share percentage
(define-private (is-valid-percentage (percentage uint))
  (and (>= percentage u0) (<= percentage MAX-REVENUE-SHARE))
)

;; Calculate platform fee
(define-private (calculate-platform-fee (amount uint))
  (/ (* amount PLATFORM-FEE-PERCENTAGE) u100)
)

;; Calculate data owner share
(define-private (calculate-owner-share (amount uint))
  (- amount (calculate-platform-fee amount))
)

;; Check if access is still valid
(define-private (is-access-valid (expires-at uint))
  (<= burn-block-height expires-at)
)

;; Update provider statistics
(define-private (update-provider-stats (provider principal) (earnings uint))
  (let ((current-profile (default-to 
    { total-data-sets: u0, total-earnings: u0, reputation-score: u50, 
      verified-status: false, registration-date: burn-block-height }
    (map-get? data-provider-profiles { provider: provider }))))
    (begin
      (map-set data-provider-profiles
        { provider: provider }
        (merge current-profile 
          { total-earnings: (+ (get total-earnings current-profile) earnings) }))
      true
    )
  )
)

;; Update consumer statistics  
(define-private (update-consumer-stats (consumer principal) (spent uint))
  (let ((current-profile (default-to
    { total-purchases: u0, total-spent: u0, access-history-count: u0,
      reputation-score: u50, registration-date: burn-block-height }
    (map-get? data-consumer-profiles { consumer: consumer }))))
    (begin
      (map-set data-consumer-profiles
        { consumer: consumer }
        (merge current-profile 
          { total-purchases: (+ (get total-purchases current-profile) u1),
            total-spent: (+ (get total-spent current-profile) spent) }))
      true
    )
  )
)

;; =================
;; PUBLIC FUNCTIONS
;; =================

;; Register clinical data
(define-public (register-clinical-data 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
  (price-per-access uint)
  (revenue-share-percentage uint)
  (anonymization-level uint))
  
  (let ((data-id (generate-data-id))
        (current-height burn-block-height))
    
    ;; Validate inputs
    (asserts! (is-valid-title title) ERR-INVALID-STRING)
    (asserts! (is-valid-description description) ERR-INVALID-STRING)
    (asserts! (is-valid-category category) ERR-INVALID-STRING)
    (asserts! (> price-per-access u0) ERR-INVALID-AMOUNT)
    (asserts! (is-valid-percentage revenue-share-percentage) ERR-INVALID-PERCENTAGE)
    (asserts! (and (>= anonymization-level u1) (<= anonymization-level u5)) ERR-INVALID-INPUT)
    (asserts! (not (var-get contract-paused)) ERR-UNAUTHORIZED)
    
    ;; Register the data
    (map-set clinical-data-registry
      { data-id: data-id }
      {
        owner: tx-sender,
        title: title,
        description: description,
        category: category,
        price-per-access: price-per-access,
        revenue-share-percentage: revenue-share-percentage,
        total-earnings: u0,
        access-count: u0,
        is-active: true,
        created-at: current-height,
        updated-at: current-height,
        compliance-verified: false,
        anonymization-level: anonymization-level
      }
    )
    
    ;; Update provider profile
    (let ((current-profile (default-to
      { total-data-sets: u0, total-earnings: u0, reputation-score: u50,
        verified-status: false, registration-date: current-height }
      (map-get? data-provider-profiles { provider: tx-sender }))))
      (map-set data-provider-profiles
        { provider: tx-sender }
        (merge current-profile 
          { total-data-sets: (+ (get total-data-sets current-profile) u1) }))
    )
    
    ;; Update global counter
    (var-set total-data-sets data-id)
    
    (ok data-id)
  )
)

;; Purchase data access
(define-public (purchase-data-access 
  (data-id uint)
  (access-duration uint)
  (access-type (string-ascii 20)))
  
  (let ((data-info (unwrap! (map-get? clinical-data-registry { data-id: data-id }) ERR-NOT-FOUND))
        (payment-id (generate-payment-id))
        (current-height burn-block-height)
        (expires-at (+ current-height access-duration))
        (payment-amount (get price-per-access data-info))
        (platform-fee (calculate-platform-fee payment-amount))
        (owner-share (calculate-owner-share payment-amount)))
    
    ;; Validate inputs
    (asserts! (is-valid-data-id data-id) ERR-INVALID-DATA-ID)
    (asserts! (is-valid-access-type access-type) ERR-INVALID-ACCESS-TYPE)
    (asserts! (get is-active data-info) ERR-DATA-NOT-AVAILABLE)
    (asserts! (and (>= access-duration MIN-ACCESS-DURATION) 
                   (<= access-duration MAX-ACCESS-DURATION)) ERR-INVALID-DURATION)
    (asserts! (> payment-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (not (var-get contract-paused)) ERR-UNAUTHORIZED)
    
    ;; Check if user already has active access
    (let ((existing-access (map-get? data-access-permissions 
                            { data-id: data-id, accessor: tx-sender })))
      (match existing-access
        some-access (asserts! (not (is-access-valid (get expires-at some-access))) ERR-ALREADY-EXISTS)
        true
      )
    )
    
    ;; Process payment (simplified - in real implementation would handle STX transfers)
    (try! (stx-transfer? payment-amount tx-sender (get owner data-info)))
    
    ;; Grant access
    (map-set data-access-permissions
      { data-id: data-id, accessor: tx-sender }
      {
        granted-at: current-height,
        expires-at: expires-at,
        access-type: access-type,
        payment-amount: payment-amount,
        is-active: true
      }
    )
    
    ;; Record payment
    (map-set payment-history
      { payment-id: payment-id }
      {
        payer: tx-sender,
        data-id: data-id,
        amount: payment-amount,
        platform-fee: platform-fee,
        data-owner-share: owner-share,
        payment-date: current-height,
        status: "completed"
      }
    )
    
    ;; Update statistics
    (map-set clinical-data-registry
      { data-id: data-id }
      (merge data-info {
        total-earnings: (+ (get total-earnings data-info) owner-share),
        access-count: (+ (get access-count data-info) u1),
        updated-at: current-height
      })
    )
    
    ;; Update global revenue
    (var-set total-revenue (+ (var-get total-revenue) payment-amount))
    (var-set platform-fee-collected (+ (var-get platform-fee-collected) platform-fee))
    
    ;; Update user statistics
    (update-provider-stats (get owner data-info) owner-share)
    (update-consumer-stats tx-sender payment-amount)
    
    (ok { access-granted: true, expires-at: expires-at, payment-id: payment-id })
  )
)

;; Check data access permission
(define-public (check-access-permission (data-id uint) (accessor principal))
  (begin
    ;; Validate inputs
    (asserts! (is-valid-data-id data-id) ERR-INVALID-DATA-ID)
    
    (let ((access-info (unwrap! (map-get? data-access-permissions 
                                 { data-id: data-id, accessor: accessor }) ERR-NOT-FOUND)))
      (if (and (get is-active access-info) 
               (is-access-valid (get expires-at access-info)))
        (ok access-info)
        ERR-ACCESS-EXPIRED
      )
    )
  )
)

;; Rate data quality
(define-public (rate-data-quality 
  (data-id uint)
  (quality-score uint)
  (completeness-score uint) 
  (accuracy-score uint)
  (review-comment (string-ascii 300)))
  
  (let ((data-info (unwrap! (map-get? clinical-data-registry { data-id: data-id }) ERR-NOT-FOUND))
        (access-info (unwrap! (map-get? data-access-permissions 
                               { data-id: data-id, accessor: tx-sender }) ERR-UNAUTHORIZED)))
    
    ;; Validate inputs
    (asserts! (is-valid-data-id data-id) ERR-INVALID-DATA-ID)
    (asserts! (is-valid-rating-score quality-score) ERR-INVALID-RATING)
    (asserts! (is-valid-rating-score completeness-score) ERR-INVALID-RATING)
    (asserts! (is-valid-rating-score accuracy-score) ERR-INVALID-RATING)
    (asserts! (is-valid-review-comment review-comment) ERR-INVALID-STRING)
    
    ;; Validate user has access
    (asserts! (and (get is-active access-info) 
                   (is-access-valid (get expires-at access-info))) ERR-ACCESS-EXPIRED)
    
    ;; Record rating
    (map-set data-quality-ratings
      { data-id: data-id, rater: tx-sender }
      {
        quality-score: quality-score,
        completeness-score: completeness-score,
        accuracy-score: accuracy-score,
        review-comment: review-comment,
        rating-date: burn-block-height
      }
    )
    
    (ok true)
  )
)

;; Update data information (owner only)
(define-public (update-data-info 
  (data-id uint)
  (title (string-ascii 100))
  (description (string-ascii 500))
  (price-per-access uint))
  
  (let ((data-info (unwrap! (map-get? clinical-data-registry { data-id: data-id }) ERR-NOT-FOUND)))
    
    ;; Validate inputs
    (asserts! (is-valid-data-id data-id) ERR-INVALID-DATA-ID)
    (asserts! (is-valid-title title) ERR-INVALID-STRING)
    (asserts! (is-valid-description description) ERR-INVALID-STRING)
    (asserts! (> price-per-access u0) ERR-INVALID-AMOUNT)
    
    ;; Validate ownership
    (asserts! (is-eq tx-sender (get owner data-info)) ERR-UNAUTHORIZED)
    
    ;; Update data info
    (map-set clinical-data-registry
      { data-id: data-id }
      (merge data-info {
        title: title,
        description: description,
        price-per-access: price-per-access,
        updated-at: burn-block-height
      })
    )
    
    (ok true)
  )
)

;; Verify compliance (admin only)
(define-public (verify-compliance (data-id uint) (verified bool))
  (let ((data-info (unwrap! (map-get? clinical-data-registry { data-id: data-id }) ERR-NOT-FOUND)))
    
    ;; Validate inputs
    (asserts! (is-valid-data-id data-id) ERR-INVALID-DATA-ID)
    
    ;; Only contract owner can verify compliance
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    
    ;; Update compliance status
    (map-set clinical-data-registry
      { data-id: data-id }
      (merge data-info {
        compliance-verified: verified,
        updated-at: burn-block-height
      })
    )
    
    (ok true)
  )
)

;; Toggle data availability
(define-public (toggle-data-availability (data-id uint))
  (let ((data-info (unwrap! (map-get? clinical-data-registry { data-id: data-id }) ERR-NOT-FOUND)))
    
    ;; Validate inputs
    (asserts! (is-valid-data-id data-id) ERR-INVALID-DATA-ID)
    
    ;; Validate ownership
    (asserts! (is-eq tx-sender (get owner data-info)) ERR-UNAUTHORIZED)
    
    ;; Toggle availability
    (map-set clinical-data-registry
      { data-id: data-id }
      (merge data-info {
        is-active: (not (get is-active data-info)),
        updated-at: burn-block-height
      })
    )
    
    (ok (not (get is-active data-info)))
  )
)

;; Emergency pause contract (admin only)
(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set contract-paused true)
    (ok true)
  )
)

;; Resume contract (admin only)
(define-public (resume-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set contract-paused false)
    (ok true)
  )
)

;; =================
;; READ-ONLY FUNCTIONS
;; =================

;; Get data information
(define-read-only (get-data-info (data-id uint))
  (if (is-valid-data-id data-id)
    (map-get? clinical-data-registry { data-id: data-id })
    none
  )
)

;; Get user's data access info
(define-read-only (get-access-info (data-id uint) (accessor principal))
  (if (is-valid-data-id data-id)
    (map-get? data-access-permissions { data-id: data-id, accessor: accessor })
    none
  )
)

;; Get provider profile
(define-read-only (get-provider-profile (provider principal))
  (map-get? data-provider-profiles { provider: provider })
)

;; Get consumer profile
(define-read-only (get-consumer-profile (consumer principal))
  (map-get? data-consumer-profiles { consumer: consumer })
)

;; Get payment details
(define-read-only (get-payment-details (payment-id uint))
  (map-get? payment-history { payment-id: payment-id })
)

;; Get data quality rating
(define-read-only (get-quality-rating (data-id uint) (rater principal))
  (if (is-valid-data-id data-id)
    (map-get? data-quality-ratings { data-id: data-id, rater: rater })
    none
  )
)

;; Get platform statistics
(define-read-only (get-platform-stats)
  {
    total-data-sets: (var-get total-data-sets),
    total-revenue: (var-get total-revenue),
    platform-fee-collected: (var-get platform-fee-collected),
    is-paused: (var-get contract-paused)
  }
)

;; Check if contract is paused
(define-read-only (is-contract-paused)
  (var-get contract-paused)
)

;; Get revenue share info
(define-read-only (get-revenue-share (data-id uint) (contributor principal))
  (if (is-valid-data-id data-id)
    (map-get? revenue-shares { data-id: data-id, contributor: contributor })
    none
  )
)

;; Calculate access cost for duration
(define-read-only (calculate-access-cost (data-id uint) (duration uint))
  (if (is-valid-data-id data-id)
    (let ((data-info (unwrap! (map-get? clinical-data-registry { data-id: data-id }) ERR-NOT-FOUND)))
      (ok {
        base-cost: (get price-per-access data-info),
        platform-fee: (calculate-platform-fee (get price-per-access data-info)),
        total-cost: (get price-per-access data-info)
      })
    )
    ERR-INVALID-DATA-ID
  )
)