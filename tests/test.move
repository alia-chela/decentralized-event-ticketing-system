#[test_only]
module ticketing::test {
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::coin::{mint_for_testing};
    use sui::sui::{SUI};

    use std::string::{Self, String};

    use ticketing::helpers::init_test_helper;
    use ticketing::events::{Self as ticket, Platform, OrganizerProfile, Event, PromoCode};

    const ADMIN: address = @0xe;
    const TEST_ADDRESS1: address = @0xee;
    const TEST_ADDRESS2: address = @0xbb;


    #[test]
    #[expected_failure(abort_code = 0x2::dynamic_field::EFieldDoesNotExist)]     
    public fun test1() {
        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        // test shared objects with init 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let platfrom = ts::take_shared<Platform>(scenario);

            ts::return_shared(platfrom);
        };

        // Register as event organizer 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut platfrom = ts::take_shared<Platform>(scenario);
            let name = string::utf8(b"alice");

            ticket::register_organizer(&mut platfrom, name, ts::ctx(scenario));

            ts::return_shared(platfrom);
        };

        // create_event
        next_tx(scenario, TEST_ADDRESS1);
        {
            let platfrom = ts::take_shared<Platform>(scenario);
            let name = string::utf8(b"alice");
            let description = string::utf8(b"event");

            let start_time:u64 = 0;
            let end_time: u64 = 100;
            let max_capacity: u64 = 50;

            ticket::create_event(&platfrom, name, description, start_time, end_time, max_capacity, ts::ctx(scenario));

            ts::return_shared(platfrom);
        };

        // Add ticket type to event
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut event = ts::take_shared<Event>(scenario);
            let name = string::utf8(b"alice");
            let base_price: u64 = 100;
            let benefits = vector::empty<String>();
            let transferable = true;
            let resellable = true;
            let max_resell_price = option::some<u64>(100);
            let quantity: u64 = 100;
            let valid_from: u64 = 50;
            let valid_until = option::some<u64>(100);

            ticket::add_ticket_type(
                &mut event,
                name,
                base_price,
                benefits,
                transferable,
                resellable,
                max_resell_price,
                quantity,
                valid_from,
                valid_until,
                ts::ctx(scenario)
                );

            ts::return_shared(event);
        };

        // Purchase_ticket
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut platform = ts::take_shared<Platform>(scenario);
            let mut event = ts::take_shared<Event>(scenario);
            let ticket_type_name = string::utf8(b"alice");

            let section_name = string::utf8(b"event");
            let mut promo_code = option::none<String>();

            let coin_ = mint_for_testing<SUI>(100, ts::ctx(scenario));

            ticket::purchase_ticket(
                &mut platform,
                &mut event,
                ticket_type_name,
                section_name,
                &mut promo_code,
                coin_,
                ts::ctx(scenario)
                );

            ts::return_shared(event);
            ts::return_shared(platform);
        };

        ts::end(scenario_test);
    }


}