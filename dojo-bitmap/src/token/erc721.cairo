#[starknet::contract]
mod ERC721 {
    use dojo_starter::token::models::{
        ERC721Meta, ERC721OperatorApproval, ERC721Owner, ERC721Balance, ERC721TokenApproval
    };
    use dojo_starter::token::interface;
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use integer::BoundedInt;
    use starknet::ContractAddress;
    use starknet::{get_caller_address, get_contract_address};
    use zeroable::Zeroable;


    #[storage]
    struct Storage {
        _world: ContractAddress,
    }

    #[event]
    #[derive(Copy, Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
        ApprovalForAll: ApprovalForAll
    }

    #[derive(Copy, Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }

    #[derive(Copy, Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        approved: ContractAddress,
        token_id: u256
    }

    #[derive(Copy, Drop, starknet::Event)]
    struct ApprovalForAll {
        owner: ContractAddress,
        operator: ContractAddress,
        approved: bool
    }

    mod Errors {
        const INVALID_TOKEN_ID: felt252 = 'ERC721: invalid token ID';
        const INVALID_ACCOUNT: felt252 = 'ERC721: invalid account';
        const UNAUTHORIZED: felt252 = 'ERC721: unauthorized caller';
        const APPROVAL_TO_OWNER: felt252 = 'ERC721: approval to owner';
        const SELF_APPROVAL: felt252 = 'ERC721: self approval';
        const INVALID_RECEIVER: felt252 = 'ERC721: invalid receiver';
        const ALREADY_MINTED: felt252 = 'ERC721: token already minted';
        const WRONG_SENDER: felt252 = 'ERC721: wrong sender';
        const SAFE_MINT_FAILED: felt252 = 'ERC721: safe mint failed';
        const SAFE_TRANSFER_FAILED: felt252 = 'ERC721: safe transfer failed';
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        world: ContractAddress,
        name: felt252,
        symbol: felt252,
        base_uri: felt252,
        recipient: ContractAddress,
        token_id: u256
    ) {
        self._world.write(world);
        self.initializer(name, symbol, base_uri);
        self._mint(recipient, token_id);
    }

    #[external(v0)]
    impl ERC721MetadataImpl of interface::IERC721Metadata<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.get_meta().name
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.get_meta().symbol
        }

        fn token_uri(self: @ContractState, token_id: u256) -> Array<felt252> {
            assert(self._exists(token_id), Errors::INVALID_TOKEN_ID);
            // TODO : concat with id
            self.get_uri(token_id)
        }
    }

    #[external(v0)]
    impl ERC721MetadataCamelOnlyImpl of interface::IERC721MetadataCamelOnly<ContractState> {
        fn tokenURI(self: @ContractState, tokenId: u256) -> Array<felt252> {
            assert(self._exists(tokenId), Errors::INVALID_TOKEN_ID);
            self.get_uri(tokenId)
        }
    }

    #[external(v0)]
    impl ERC721Impl of interface::IERC721<ContractState> {
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            assert(account.is_non_zero(), Errors::INVALID_ACCOUNT);
            self.get_balance(account).amount
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            self._owner_of(token_id)
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            assert(self._exists(token_id), Errors::INVALID_TOKEN_ID);
            self.get_token_approval(token_id).address
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.get_operator_approval(owner, operator).approved
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = self._owner_of(token_id);

            let caller = get_caller_address();
            assert(
                owner == caller || ERC721Impl::is_approved_for_all(@self, owner, caller),
                Errors::UNAUTHORIZED
            );
            self._approve(to, token_id);
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            self._set_approval_for_all(get_caller_address(), operator, approved)
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            assert(
                self._is_approved_or_owner(get_caller_address(), token_id), Errors::UNAUTHORIZED
            );
            self._transfer(from, to, token_id);
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            assert(
                self._is_approved_or_owner(get_caller_address(), token_id), Errors::UNAUTHORIZED
            );
            self._safe_transfer(from, to, token_id, data);
        }
    }

    #[external(v0)]
    impl ERC721CamelOnlyImpl of interface::IERC721CamelOnly<ContractState> {
        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            ERC721Impl::balance_of(self, account)
        }

        fn ownerOf(self: @ContractState, tokenId: u256) -> ContractAddress {
            ERC721Impl::owner_of(self, tokenId)
        }

        fn getApproved(self: @ContractState, tokenId: u256) -> ContractAddress {
            ERC721Impl::get_approved(self, tokenId)
        }

        fn isApprovedForAll(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            ERC721Impl::is_approved_for_all(self, owner, operator)
        }

        fn setApprovalForAll(ref self: ContractState, operator: ContractAddress, approved: bool) {
            ERC721Impl::set_approval_for_all(ref self, operator, approved)
        }

        fn transferFrom(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, tokenId: u256
        ) {
            ERC721Impl::transfer_from(ref self, from, to, tokenId)
        }

        fn safeTransferFrom(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            tokenId: u256,
            data: Span<felt252>
        ) {
            ERC721Impl::safe_transfer_from(ref self, from, to, tokenId, data)
        }
    }

    //
    // Internal
    //

    #[generate_trait]
    impl WorldInteractionsImpl of WorldInteractionsTrait {
        fn world(self: @ContractState) -> IWorldDispatcher {
            IWorldDispatcher { contract_address: self._world.read() }
        }

        fn get_meta(self: @ContractState) -> ERC721Meta {
            get!(self.world(), get_contract_address(), ERC721Meta)
        }

        fn get_uri(self: @ContractState, token_id: u256) -> Array<felt252> {
            // TODO : concat with id when we have string type
            let mut content = ArrayTrait::<felt252>::new();

            // Name & Description
            content.append('data:application/json;utf8,');
            content.append('{"name":"Golden Token",');
            content.append('"description":"One free game, ');
            content.append('every day, forever"');

            // Image
            content.append(',"image":"');
            content.append('data:image/svg+xml;utf8,<svg%20');
            content.append('width=\\"100%\\"%20height=\\"100%\\');
            content.append('"%20viewBox=\\"0%200%2020000%202');
            content.append('0000\\"%20xmlns=\\"http://www.w3.');
            content.append('org/2000/svg\\"><style>svg{backg');
            content.append('round-image:url(');
            content.append('data:image/png;base64,');

            // Golden Token Base64 Encoded PNG
            content.append('iVBORw0KGgoAAAANSUhEUgAAAUAAAAF');
            content.append('ABAMAAAA/vriZAAAAD1BMVEUAAAD4+A');
            content.append('CJSQL/pAD///806TM9AAACgUlEQVR4A');
            content.append('WKgGAjiBUqoANDOHdzGDcRQAK3BLaSF');
            content.append('tJD+awriQwh8zDd2srlQfjxJGGr4xhf');
            content.append('Csuj3ywEC7gcCAgKeCD9bVC8gICAg4H');
            content.append('cDVtGvP/G5MKIXvKF8MhAQEBAQMFifo');
            content.append('rmK+Iho8uh8zwMCAgICAk65aouaEVM9');
            content.append('WL3zAQICAgJuBqYtth7brEZHC2CcMI6');
            content.append('Z1FQCAgICAm4GTnZsGL8WRaW4inPVV3');
            content.append('eAgICAgI8CVls0uIr+WnnR7wABAQEBF');
            content.append('wAvbBn3ytrvuhIQEBAQcCvwa8IbygCm');
            content.append('DRAQEBBwK7DbTt8A/OdWl7ZUAgICAgL');
            content.append('uAp5slXD1+i2BzQYICAgIuBsYtigyf8');
            content.append('2Z+GjRkhMYNQABAQEBdwFfsVXgRLd1Y');
            content.append('Dl/yAEBAQEB9wDrO7OoOQtRvdpeGKec');
            content.append('AAQEBATcCsxWd7qNwh1YItG15EYgICA');
            content.append('gIOAopyudHp6FuApgTRlgKbkTCAgICA');
            content.append('g4jhAl8NCz/u31W2+na4GAgICAgHFVh');
            content.append('+ZPtkmJvEiuNeYMa4CAgICAgPlxWSxP');
            content.append('nERhS0zE4XDR78rAyw4gICAgIGASYte');
            content.append('UN1soJyV+CGOL7QEBAQEBnwTs20yl+t');
            content.append('VZvFGLhTpUsxAICAgICJjKfORvvD06O');
            content.append('cAL2zogICAgIODJFg+fvknL25vR+7nd');
            content.append('CQQEBAQELMrYIeQ/XoxJvrItBAICAgI');
            content.append('CpvK0w2l8pUak3Nn2AwEBAQEB6z+sj/');
            content.append('1jin/yTlsFdT8QEBAQELAro1PF/lEpI');
            content.append('lJGHgthAwQEBATcD8wI5dxOzRr1C7PO');
            content.append('AgQEBAR8GjA7X1SqyjqxP0/cAJYDAQE');
            content.append('BAQGDGt46cJ/JyQIEBAQEfD7w0nsl2g');
            content.append('8EBAQEBPwNOZbOIEJQph0AAAAASUVOR');
            content.append('K5CYII=');

            content.append(');background-repeat:no-repeat;b');
            content.append('ackground-size:contain;backgrou');
            content.append('nd-position:center;image-render');
            content.append('ing:-webkit-optimize-contrast;-');
            content.append('ms-interpolation-mode:nearest-n');
            content.append('eighbor;image-rendering:-moz-cr');
            content.append('isp-edges;image-rendering:pixel');
            content.append('ated;}</style></svg>"}');

            content
        }

        fn get_balance(self: @ContractState, account: ContractAddress) -> ERC721Balance {
            get!(self.world(), (get_contract_address(), account), ERC721Balance)
        }

        fn get_owner_of(self: @ContractState, token_id: u256) -> ERC721Owner {
            get!(self.world(), (get_contract_address(), token_id), ERC721Owner)
        }

        fn get_token_approval(self: @ContractState, token_id: u256) -> ERC721TokenApproval {
            get!(self.world(), (get_contract_address(), token_id), ERC721TokenApproval)
        }

        fn get_operator_approval(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> ERC721OperatorApproval {
            get!(self.world(), (get_contract_address(), owner, operator), ERC721OperatorApproval)
        }

        fn set_token_approval(
            ref self: ContractState,
            owner: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            emit: bool
        ) {
            set!(
                self.world(),
                ERC721TokenApproval { token: get_contract_address(), token_id, address: to, }
            );
            if emit {
                self.emit_event(Approval { owner, approved: to, token_id });
            }
        }

        fn set_operator_approval(
            ref self: ContractState,
            owner: ContractAddress,
            operator: ContractAddress,
            approved: bool
        ) {
            set!(
                self.world(),
                ERC721OperatorApproval { token: get_contract_address(), owner, operator, approved }
            );
            self.emit_event(ApprovalForAll { owner, operator, approved });
        }

        fn set_balance(ref self: ContractState, account: ContractAddress, amount: u256) {
            set!(self.world(), ERC721Balance { token: get_contract_address(), account, amount });
        }

        fn set_owner(ref self: ContractState, token_id: u256, address: ContractAddress) {
            set!(self.world(), ERC721Owner { token: get_contract_address(), token_id, address });
        }

        fn emit_event<
            S, impl IntoImp: traits::Into<S, Event>, impl SDrop: Drop<S>, impl SCopy: Copy<S>
        >(
            ref self: ContractState, event: S
        ) {
            self.emit(event);
            emit!(self.world(), event);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState, name: felt252, symbol: felt252, base_uri: felt252) {
            let meta = ERC721Meta { token: get_contract_address(), name, symbol, base_uri };
            set!(self.world(), (meta));
        }

        fn _owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let owner = self.get_owner_of(token_id).address;
            match owner.is_zero() {
                bool::False(()) => owner,
                bool::True(()) => panic_with_felt252(Errors::INVALID_TOKEN_ID)
            }
        }

        fn _exists(self: @ContractState, token_id: u256) -> bool {
            let owner = self.get_owner_of(token_id).address;
            owner.is_non_zero()
        }

        fn _is_approved_or_owner(
            self: @ContractState, spender: ContractAddress, token_id: u256
        ) -> bool {
            let owner = self._owner_of(token_id);
            let is_approved_for_all = ERC721Impl::is_approved_for_all(self, owner, spender);
            owner == spender
                || is_approved_for_all
                || spender == ERC721Impl::get_approved(self, token_id)
        }

        fn _approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = self._owner_of(token_id);
            assert(owner != to, Errors::APPROVAL_TO_OWNER);

            self.set_token_approval(owner, to, token_id, true);
        }

        fn _set_approval_for_all(
            ref self: ContractState,
            owner: ContractAddress,
            operator: ContractAddress,
            approved: bool
        ) {
            assert(owner != operator, Errors::SELF_APPROVAL);
            self.set_operator_approval(owner, operator, approved);
        }

        fn _mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            assert(!to.is_zero(), Errors::INVALID_RECEIVER);
            assert(!self._exists(token_id), Errors::ALREADY_MINTED);

            self.set_balance(to, self.get_balance(to).amount + 1);
            self.set_owner(token_id, to);

            self.emit_event(Transfer { from: Zeroable::zero(), to, token_id });
        }

        fn _transfer(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            assert(!to.is_zero(), Errors::INVALID_RECEIVER);
            let owner = self._owner_of(token_id);
            assert(from == owner, Errors::WRONG_SENDER);

            // Implicit clear approvals, no need to emit an event
            self.set_token_approval(owner, Zeroable::zero(), token_id, false);

            self.set_balance(from, self.get_balance(from).amount - 1);
            self.set_balance(to, self.get_balance(to).amount + 1);
            self.set_owner(token_id, to);

            self.emit_event(Transfer { from, to, token_id });
        }

        fn _burn(ref self: ContractState, token_id: u256) {
            let owner = self._owner_of(token_id);

            // Implicit clear approvals, no need to emit an event
            self.set_token_approval(owner, Zeroable::zero(), token_id, false);

            self.set_balance(owner, self.get_balance(owner).amount - 1);
            self.set_owner(token_id, Zeroable::zero());

            self.emit_event(Transfer { from: owner, to: Zeroable::zero(), token_id });
        }

        fn _safe_mint(
            ref self: ContractState, to: ContractAddress, token_id: u256, data: Span<felt252>
        ) {
            self._mint(to, token_id);
        }

        fn _safe_transfer(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            self._transfer(from, to, token_id);
        }
    }
}