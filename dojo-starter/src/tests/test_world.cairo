#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use debug::PrintTrait;

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};

    use alexandria_encoding::base64::Base64FeltEncoder;
    use alexandria_bytes::Bytes;   
    use alexandria_bytes::BytesTrait;

    use dojo_starter::tests::utils;
    use dojo_starter::tests::constants::{
        ZERO, OWNER, SPENDER, RECIPIENT, OPERATOR, OTHER, NAME, SYMBOL, URI, TOKEN_ID
    };
    use dojo_starter::token::erc721::ERC721::ERC721Impl;
    use dojo_starter::token::erc721::ERC721::ERC721CamelOnlyImpl;
    use dojo_starter::token::erc721::ERC721::ERC721MetadataImpl;
    use dojo_starter::token::erc721::ERC721::InternalImpl;
    use dojo_starter::token::erc721::ERC721::WorldInteractionsImpl;
    use dojo_starter::token::erc721::ERC721::{Approval, ApprovalForAll, Transfer};
    use dojo_starter::token::erc721::ERC721;
    use dojo_starter::token::models::{
        ERC721Meta, erc_721_meta, ERC721OperatorApproval, erc_721_operator_approval, ERC721Owner,
        erc_721_owner, ERC721Balance, erc_721_balance, ERC721TokenApproval, erc_721_token_approval
    };
    use dojo_starter::token::erc721::ERC721::_worldContractMemberStateTrait;

    // import test utils
    use dojo_starter::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::{position::{Position, Vec2, position}, moves::{Moves, Direction, moves}}
    };

    fn STATE() -> (IWorldDispatcher, ERC721::ContractState) {
        let world = spawn_test_world(
            array![
                erc_721_meta::TEST_CLASS_HASH,
                erc_721_operator_approval::TEST_CLASS_HASH,
                erc_721_owner::TEST_CLASS_HASH,
                erc_721_balance::TEST_CLASS_HASH,
                erc_721_token_approval::TEST_CLASS_HASH,
            ]
        );
        let mut state = ERC721::contract_state_for_testing();
        state._world.write(world.contract_address);
        (world, state)
    }

    fn setup() -> ERC721::ContractState {
        let (world, mut state) = STATE();
        ERC721::constructor(ref state, world.contract_address, NAME, SYMBOL, URI, OWNER(), TOKEN_ID);
        utils::drop_event(ZERO());
        state
    }

    #[test]
    #[available_gas(20000000)]
    fn test_constructor() {
        let (world, mut state) = STATE();
        ERC721::constructor(ref state, world.contract_address, NAME, SYMBOL, URI, OWNER(), TOKEN_ID);

        assert(ERC721MetadataImpl::name(@state) == NAME, 'Name should be NAME');
        assert(ERC721MetadataImpl::symbol(@state) == SYMBOL, 'Symbol should be SYMBOL');
        assert(ERC721Impl::balance_of(@state, OWNER()) == 1, 'Balance should be one');
        assert(ERC721Impl::owner_of(@state, TOKEN_ID) == OWNER(), 'OWNER should be owner');
    }


    #[test]
    #[available_gas(30000000)]
    fn test_move() {
        // caller
        let caller = starknet::contract_address_const::<0x0>();

        // models
        let mut models = array![position::TEST_CLASS_HASH, moves::TEST_CLASS_HASH];

        // deploy world with models
        let world = spawn_test_world(models);

        // deploy systems contract
        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        // call spawn()
        actions_system.spawn();

        // call move with direction right
        actions_system.move(Direction::Right);

        // Check world state
        let moves = get!(world, caller, Moves);

        // casting right direction
        let right_dir_felt: felt252 = Direction::Right.into();

        // check moves
        assert(moves.remaining == 99, 'moves is wrong');

        // check last direction
        assert(moves.last_direction.into() == right_dir_felt, 'last direction is wrong');

        // get new_position
        let new_position = get!(world, caller, Position);

        // check new position x
        assert(new_position.vec.x == 11, 'position x is wrong');

        // check new position y
        assert(new_position.vec.y == 10, 'position y is wrong');
    }



    #[test]
    #[available_gas(30000000)]
    fn test_base64() {

        let mut bm = Base64FeltEncoder::encode('BM');
        let mut bytes: Bytes = BytesTrait::new(0, ArrayTrait::new());
        let hash = bytes.keccak();
    }
}
