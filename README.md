# decentralized-event-ticketing-system

A decentralized event ticketing platform built on the Sui blockchain that enables secure ticket creation, sales, transfers, and validation with features like dynamic pricing, NFT benefits, and promotional codes.

## Features

### Core Functionality

- Event creation and management by verified organizers
- Multiple ticket types with customizable benefits
- Secure ticket purchases with SUI tokens
- QR code generation for ticket validation
- Ticket transfers and resale capabilities
- Venue section management with custom pricing

### Advanced Features

- Dynamic pricing based on time and demand
- Promotional code support
- NFT-based benefits and priority access
- Attendee profiles with loyalty points
- Platform revenue sharing model
- Comprehensive transfer history tracking

## Getting Started

### Prerequisites

- Sui CLI installed
- Sui wallet configured
- Basic understanding of Move programming

### Installation

1. Clone the repository:

```bash
git clone https://github.com/alia-chela/decentralized-event-ticketing-system.git
cd decentralized-event-ticketing-system
```

2.  Run the test network locally:

```bash
RUST_LOG="off,sui_node=info" sui-test-validator
```

3. Build the project:

```bash
sui move build
```

4. Deploy to the Sui network:

```bash
sui client publish --gas-budget 30000
```

## Usage

### Platform Initialization

The platform is automatically initialized upon deployment with:

- Platform admin assignment
- Default fee percentage (2.5%)
- Organizer registry setup

### Register as an Organizer

```move
register_organizer(platform, name, ctx)
```

### Create an Event

```move
create_event(
    platform,
    name,
    description,
    venue,
    start_time,
    end_time,
    max_capacity,
    ctx
)
```

### Add Ticket Types

```move
add_ticket_type(
    event,
    name,
    base_price,
    benefits,
    transferable,
    resellable,
    max_resell_price,
    quantity,
    valid_from,
    valid_until,
    ctx
)
```

### Purchase Tickets

```move
purchase_ticket(
    platform,
    event,
    ticket_type_name,
    section_name,
    promo_code,
    payment,
    ctx
)
```

## Core Components

### Platform

- Central registry for organizers
- Fee collection and distribution
- Platform-wide settings management

### Events

- Customizable venue sections
- Multiple ticket types
- Promotional code support
- Dynamic pricing rules

### Tickets

- Unique QR codes
- Transfer history tracking
- Usage validation
- Custom metadata support

### Profiles

- Organizer reputation system
- Attendee loyalty program
- Event attendance history
- Customizable preferences

## Error Handling

The system includes comprehensive error handling for common scenarios:

- `ENotOrganizer`: Unauthorized organizer access
- `EEventNotFound`: Event doesn't exist
- `ETicketNotFound`: Invalid ticket reference
- `EInsufficientFunds`: Insufficient payment
- `EEventSoldOut`: No tickets available
- `ETicketExpired`: Ticket validity period ended
- `EInvalidPromoCode`: Invalid or expired promo code
- `ETicketAlreadyUsed`: Attempt to reuse ticket
- `EInvalidTransfer`: Unauthorized ticket transfer
- `EEventCancelled`: Event no longer active
- `EInvalidRefund`: Refund validation failed

## Security Features

- Ownership validation for all operations
- Secure ticket transfer mechanisms
- Platform fee enforcement
- Price manipulation prevention
- Usage tracking and validation

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request
