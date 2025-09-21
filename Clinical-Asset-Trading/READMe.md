# Clinical Data Monetization Smart Contract

## Overview

The Clinical Data Monetization Smart Contract is a comprehensive blockchain-based solution for securely monetizing clinical data while ensuring privacy, compliance, and fair revenue distribution. Built on the Stacks blockchain using Clarity smart contract language, this platform enables healthcare providers and researchers to monetize their clinical datasets while maintaining strict privacy and compliance standards.

## Features

### Core Functionality
- **Data Registration**: Register clinical datasets with metadata, pricing, and privacy controls
- **Access Management**: Purchase and manage time-based access to datasets
- **Revenue Sharing**: Automated revenue distribution between data owners and platform
- **Quality Ratings**: Community-driven data quality assessment system
- **Compliance Verification**: Administrative approval system for regulatory compliance
- **Privacy Controls**: Built-in anonymization level tracking (1-5 scale)

### Security Features
- **Access Control**: Role-based permissions for data owners, consumers, and administrators
- **Time-based Access**: Granular access control with expiration dates
- **Emergency Controls**: Contract pause functionality for emergency situations
- **Input Validation**: Comprehensive validation for all user inputs

## Contract Structure

### Constants
- **Platform Fee**: 5% platform fee on all transactions
- **Access Duration**: Minimum 1 day, maximum 1 year
- **Data ID Range**: 1 to 999,999,999
- **Revenue Share**: Up to 100% customizable revenue sharing

### Data Structures

#### Clinical Data Registry
```clarity
{
  owner: principal,
  title: string-ascii 100,
  description: string-ascii 500,
  category: string-ascii 50,
  price-per-access: uint,
  revenue-share-percentage: uint,
  total-earnings: uint,
  access-count: uint,
  is-active: bool,
  created-at: uint,
  updated-at: uint,
  compliance-verified: bool,
  anonymization-level: uint
}
```

#### Data Access Permissions
```clarity
{
  granted-at: uint,
  expires-at: uint,
  access-type: string-ascii 20,
  payment-amount: uint,
  is-active: bool
}
```

## Usage Guide

### For Data Providers

#### 1. Register Clinical Data
```clarity
(register-clinical-data 
  "Patient Outcome Study 2024"
  "Comprehensive patient outcome data from clinical trial involving 1000 participants"
  "Clinical Trials"
  1000000  ;; 1 STX per access
  80       ;; 80% revenue share to contributors
  4)       ;; High anonymization level
```

#### 2. Update Data Information
```clarity
(update-data-info 
  data-id
  "Updated Title"
  "Updated description with additional details"
  1500000) ;; New price: 1.5 STX
```

#### 3. Toggle Data Availability
```clarity
(toggle-data-availability data-id)
```

### For Data Consumers

#### 1. Purchase Data Access
```clarity
(purchase-data-access 
  data-id
  2592000    ;; 30 days access duration in seconds
  "analyze") ;; Access type: "read", "analyze", or "download"
```

#### 2. Check Access Permissions
```clarity
(check-access-permission data-id accessor-principal)
```

#### 3. Rate Data Quality
```clarity
(rate-data-quality
  data-id
  8    ;; Quality score (1-10)
  9    ;; Completeness score (1-10)
  7    ;; Accuracy score (1-10)
  "High quality dataset with comprehensive patient data")
```

### For Administrators

#### 1. Verify Compliance
```clarity
(verify-compliance data-id true)
```

#### 2. Emergency Controls
```clarity
(pause-contract)   ;; Pause all contract operations
(resume-contract)  ;; Resume normal operations
```

## Read-Only Functions

### Data Information
- `get-data-info(data-id)`: Retrieve complete dataset information
- `get-access-info(data-id, accessor)`: Check user's access permissions
- `get-quality-rating(data-id, rater)`: Get quality ratings for dataset

### User Profiles
- `get-provider-profile(provider)`: Get data provider statistics
- `get-consumer-profile(consumer)`: Get data consumer statistics

### Platform Statistics
- `get-platform-stats()`: Get overall platform metrics
- `calculate-access-cost(data-id, duration)`: Calculate access costs

## Error Codes

| Code | Error | Description |
|------|--------|-------------|
| 100 | ERR-UNAUTHORIZED | User lacks required permissions |
| 101 | ERR-NOT-FOUND | Requested resource not found |
| 102 | ERR-ALREADY-EXISTS | Resource already exists |
| 103 | ERR-INSUFFICIENT-FUNDS | Insufficient funds for transaction |
| 104 | ERR-INVALID-AMOUNT | Invalid amount specified |
| 105 | ERR-ACCESS-EXPIRED | Data access has expired |
| 106 | ERR-INVALID-DURATION | Invalid access duration |
| 107 | ERR-DATA-NOT-AVAILABLE | Dataset is not available |
| 108 | ERR-INVALID-PERCENTAGE | Invalid percentage value |
| 109 | ERR-PAYMENT-FAILED | Payment processing failed |
| 110 | ERR-ALREADY-PAID | Payment already processed |
| 111 | ERR-INVALID-INPUT | Invalid input parameter |
| 112 | ERR-INVALID-STRING | Invalid string format |
| 113 | ERR-INVALID-DATA-ID | Invalid data ID |
| 114 | ERR-INVALID-ACCESS-TYPE | Invalid access type |
| 115 | ERR-INVALID-RATING | Invalid rating score |

## Security Considerations

### Access Control
- Only data owners can update their datasets
- Only contract owner can verify compliance
- Time-based access prevents unauthorized long-term access
- Emergency pause functionality for critical situations

### Privacy Protection
- Anonymization level tracking (1-5 scale)
- No storage of actual clinical data in the contract
- Access type restrictions (read, analyze, download)
- Compliance verification requirement

### Financial Security
- Automated fee calculation and distribution
- Payment history tracking
- Revenue sharing transparency
- Platform fee collection