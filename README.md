# SocialStack

A decentralized social media platform built on the Stacks blockchain that enables users to create, share, and monetize content while maintaining ownership of their data.

## Overview

SocialStack is a Web3 social platform that combines traditional social media features with blockchain capabilities. Users can create profiles, share content, follow other users, and engage with content through reactions. All interactions are recorded on the Stacks blockchain, ensuring transparency and data ownership.

## Features

- **Decentralized Accounts**
  - Create unique profiles with customizable handles
  - Update profile information
  - Full ownership of account data

- **Content Management**
  - Publish content with up to 1000 characters
  - Content is minted as NFTs, ensuring creator ownership
  - Store up to 50 pieces of content per account

- **Social Interactions**
  - Follow/unfollow other accounts
  - React to content with messages (up to 280 characters)
  - Support content creators through direct STX rewards

- **Tokenization**
  - All content is automatically minted as NFTs
  - Content creators retain full ownership rights
  - Enable monetization through direct tipping

## Smart Contract Functions

### Account Management
```clarity
(register-account (handle (string-utf8 50)) (profile (string-utf8 200)))
(update-account (new-profile (string-utf8 200)))
(get-account-profile (account principal))
```

### Content Management
```clarity
(publish-content (body (string-utf8 1000)))
(get-content (content-id uint))
(get-account-content (account principal))
```

### Social Interactions
```clarity
(follow-account (account-to-follow principal))
(unfollow-account (account-to-unfollow principal))
(get-following (account principal))
```

### Engagement
```clarity
(add-reaction (content-id uint) (message (string-utf8 280)))
(get-reactions (content-id uint))
(reward-content (content-id uint) (amount uint))
```

## Technical Specifications

- **Platform**: Stacks Blockchain
- **Language**: Clarity
- **Storage**: On-chain data maps
- **NFT Standard**: Native Stacks NFT standard
- **Maximum Limits**:
  - Handle length: 50 characters
  - Profile length: 200 characters
  - Content length: 1000 characters
  - Reaction length: 280 characters
  - Content per account: 50 items
  - Following limit: 500 accounts
  - Reactions per content: 200

## Installation

1. Ensure you have the Stacks development environment set up
2. Clone the repository
3. Deploy the contract to the Stacks blockchain:
```bash
clarinet contract deploy social-stack
```

## Usage Example

```clarity
;; Register a new account
(contract-call? .social-stack register-account "alice" "Web3 enthusiast")

;; Publish content
(contract-call? .social-stack publish-content "Hello Web3 World!")

;; Follow another account
(contract-call? .social-stack follow-account 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; React to content
(contract-call? .social-stack add-reaction u1 "Great post!")
```

## Security Considerations

- All functions include appropriate checks for valid inputs
- Data length restrictions prevent spam and ensure efficient storage
- Following/unfollowing mechanisms include duplicate prevention
- Reward system includes checks for valid amounts and ownership
- NFT minting is integrated with content creation for ownership verification

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

Project Link: [https://github.com/hamat7/social-stack](https://github.com/hamat7/social-stack)

## Acknowledgments

- Stacks Blockchain Team
- Clarity Language Documentation
- Web3 Social Media Standards