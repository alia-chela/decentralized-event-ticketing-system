module ticketing::events {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::linked_table::{Self, LinkedTable};
    use std::string::String;
    
    // Error codes
    const ENotOrganizer: u64 = 0;
    // const EEventNotFound: u64 = 1;
    // const ETicketNotFound: u64 = 2;
    const EInsufficientFunds: u64 = 3;
    const EEventSoldOut: u64 = 4;
    // const ETicketExpired: u64 = 5;
    // const EInvalidPromoCode: u64 = 6;
    const ETicketAlreadyUsed: u64 = 7;
    const EInvalidTransfer: u64 = 8;
    const EEventCancelled: u64 = 9;
    // const EInvalidRefund: u64 = 10;

    // Core structs
    public struct Platform has key {
        id: UID,
        admin: address,
        revenue: Balance<SUI>,
        fee_percentage: u64,
        organizers: LinkedTable<address, OrganizerProfile>
    }

    public struct OrganizerProfile has store {
        name: String,
        reputation_score: u64,
        total_events: u64,
        successful_events: u64,
        verified: bool,
        revenue: Balance<SUI>
    }

    public struct Event has key {
        id: UID,
        organizer: address,
        name: String,
        description: String,
        venue: Venue,
        start_time: u64,
        end_time: u64,
        ticket_types: LinkedTable<String, TicketType>,
        promo_codes: LinkedTable<String, PromoCode>,
        max_capacity: u64,
        current_sales: u64,
        revenue: Balance<SUI>,
        cancelled: bool,
        nft_benefits: Option<NFTBenefits>
    }

    public struct Venue has store {
        name: String,
        location: String,
        sections: LinkedTable<String, Section>,
        amenities: vector<String>,
        access_rules: vector<String>
    }

    public struct Section has store {
        name: String,
        capacity: u64,
        remaining: u64,
        price_multiplier: u64
    }

    public struct TicketType has store {
        name: String,
        base_price: u64,
        benefits: vector<String>,
        transferable: bool,
        resellable: bool,
        max_resell_price: Option<u64>,
        quantity: u64,
        sold: u64,
        valid_from: u64,
        valid_until: Option<u64>
    }

    public struct Ticket has key {
        id: UID,
        event_id: ID,
        ticket_type: String,
        section: String,
        seat: Option<String>,
        owner: address,
        purchase_price: u64,
        purchase_time: u64,
        used: bool,
        qr_code: vector<u8>,
        metadata: LinkedTable<String, String>
    }

    public struct PromoCode has store {
        code: String,
        discount_percentage: u64,
        max_uses: u64,
        used: u64,
        valid_until: u64,
        specific_ticket_types: Option<vector<String>>
    }

    public struct NFTBenefits has store {
        collection_ids: vector<ID>,
        discount_percentage: u64,
        extra_benefits: vector<String>,
        priority_access: bool
    }

    public struct AttendeeProfile has key {
        id: UID,
        address: address,
        attendance_history: LinkedTable<ID, AttendanceRecord>,
        preferences: LinkedTable<String, String>,
        loyalty_points: u64,
        rewards: vector<Reward>
    }

    public struct AttendanceRecord has store {
        event_id: ID,
        ticket_type: String,
        attendance_time: u64,
        feedback: Option<String>,
        rating: Option<u8>
    }

    public struct Reward has store {
        name: String,
        description: String,
        value: u64,
        expiry: Option<u64>,
        used: bool
    }

    // Initialize platform
    fun init(ctx: &mut TxContext) {
        let platform = Platform {
            id: object::new(ctx),
            admin: tx_context::sender(ctx),
            revenue: balance::zero(),
            fee_percentage: 250, // 2.5%
            organizers: linked_table::new(ctx)
        };
        transfer::share_object(platform);
    }

    // Register as event organizer
    public fun register_organizer(
        platform: &mut Platform,
        name: String,
        ctx: &mut TxContext
    ) {
        let organizer = OrganizerProfile {
            name,
            reputation_score: 0,
            total_events: 0,
            successful_events: 0,
            verified: false,
            revenue: balance::zero()
        };
        linked_table::push_back(&mut platform.organizers, tx_context::sender(ctx), organizer);
    }

    // Create new event
    public fun create_event(
        platform: &Platform,
        name: String,
        description: String,
        start_time: u64,
        end_time: u64,
        max_capacity: u64,
        ctx: &mut TxContext
    ) {
        assert!(linked_table::contains(&platform.organizers, tx_context::sender(ctx)), ENotOrganizer);
        
        let venue = Venue {
            name: description,
            location: description,
            sections: linked_table::new(ctx),
            amenities: vector::empty(),
            access_rules: vector::empty()
        };

        let event = Event {
            id: object::new(ctx),
            organizer: tx_context::sender(ctx),
            name,
            description,
            venue,
            start_time,
            end_time,
            ticket_types: linked_table::new(ctx),
            promo_codes: linked_table::new(ctx),
            max_capacity,
            current_sales: 0,
            revenue: balance::zero(),
            cancelled: false,
            nft_benefits: option::none()
        };
        
        transfer::share_object(event);
    }

    // Add ticket type to event
    public fun add_ticket_type(
        event: &mut Event,
        name: String,
        base_price: u64,
        benefits: vector<String>,
        transferable: bool,
        resellable: bool,
        max_resell_price: Option<u64>,
        quantity: u64,
        valid_from: u64,
        valid_until: Option<u64>,
        ctx: &mut TxContext
    ) {
        assert!(event.organizer == tx_context::sender(ctx), ENotOrganizer);
        
        let ticket_type = TicketType {
            name,
            base_price,
            benefits,
            transferable,
            resellable,
            max_resell_price,
            quantity,
            sold: 0,
            valid_from,
            valid_until
        };
        
        linked_table::push_back(&mut event.ticket_types, name, ticket_type);
    }

    // Purchase ticket
    public fun purchase_ticket(
        platform: &mut Platform,
        event: &mut Event,
        ticket_type_name: String,
        section_name: String,
        promo_code: &mut Option<String>,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(!event.cancelled, EEventCancelled);
        let ticket_type = linked_table::borrow_mut(&mut event.ticket_types, ticket_type_name);
        let base_price = ticket_type.base_price;
        assert!(ticket_type.sold < ticket_type.quantity, EEventSoldOut);
        ticket_type.sold = ticket_type.sold + 1;

        let final_price = calculate_ticket_price(
            event,
            base_price,
            section_name,
            promo_code,
            ctx
        );
        
        assert!(coin::value(&payment) >= final_price, EInsufficientFunds);
        
        // Process payment
        let mut payment_balance = coin::into_balance(payment);
        let platform_fee = balance::split(&mut payment_balance, final_price * platform.fee_percentage / 10000);
        balance::join(&mut platform.revenue, platform_fee);
        balance::join(&mut event.revenue, payment_balance);
        
        // Create ticket
        let ticket = Ticket {
            id: object::new(ctx),
            event_id: object::id(event),
            ticket_type: ticket_type_name,
            section: section_name,
            seat: option::none(),
            owner: tx_context::sender(ctx),
            purchase_price: final_price,
            purchase_time: tx_context::epoch(ctx),
            used: false,
            qr_code: generate_qr_code(ctx),
            metadata: linked_table::new(ctx)
        };


        event.current_sales = event.current_sales + 1;
        
        transfer::transfer(ticket, tx_context::sender(ctx));
    }

        // Calculate ticket price based on various factors
    fun calculate_ticket_price(
        event: &mut Event,
        base_price: u64,
        section_name: String,
        promo_code: &mut Option<String>,
        ctx: &TxContext
    ): u64 {
        // Apply section multiplier
        let section = linked_table::borrow(&event.venue.sections, section_name);
        let mut _new_base_price = base_price * section.price_multiplier / 100;
        
        // Apply promo code if valid
        if (option::is_some(promo_code)) {
            let code = option::extract(promo_code);
            if (linked_table::contains(&event.promo_codes, code)) {
                let promo = linked_table::borrow_mut(&mut event.promo_codes, code);
                if (promo.used < promo.max_uses && tx_context::epoch(ctx) < promo.valid_until) {
                    _new_base_price = base_price * (100 - promo.discount_percentage) / 100;
                    promo.used = promo.used + 1;
                };
            };
        };
        
        base_price
    }

    // Use ticket at event
    public fun use_ticket(
        ticket: &mut Ticket,
        ctx: &mut TxContext
    ) {
        assert!(!ticket.used, ETicketAlreadyUsed);
        assert!(ticket.owner == tx_context::sender(ctx), EInvalidTransfer);
        
        ticket.used = true;
    }

    // Generate QR code (simplified)
    fun generate_qr_code(_ctx: &mut TxContext): vector<u8> {
        // In a real implementation, this would generate a proper QR code
        vector[1, 2, 3, 4]
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(ctx);
    }
}