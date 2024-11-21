#[test_only]
module ticketing::test {
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::coin::{mint_for_testing};
    use sui::sui::{SUI};

    use std::string::{Self};

    use ticketing::helpers::init_test_helper;
    use ticketing::events::{Self as ticket, Platform, OrganizerProfile, Event, PromoCode, DynamicPricing};

    const ADMIN: address = @0xe;
    const TEST_ADDRESS1: address = @0xee;
    const TEST_ADDRESS2: address = @0xbb;


    #[test]  
    public fun test1() {
        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        // test shared objects with init 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let platfrom = ts::take_shared<Platform>(scenario);

            ts::return_shared(platfrom);
        };

        // tRegister as event organizer 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut platfrom = ts::take_shared<Platform>(scenario);
            let name = string::utf8(b"alice");

            ticket::register_organizer(&mut platfrom, name, ts::ctx(scenario));

            ts::return_shared(platfrom);
        };


        ts::end(scenario_test);
    }


}