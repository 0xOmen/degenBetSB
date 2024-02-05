# Degen Escrow

Escrow contract for P2P betting on the 2024 Super Bowl using $DEGEN as collateral.

Smart contract to be used with JeevesBot on Farcaster. Contract owner acts as oracle and updates contract when the SuperBowl winner is determined.

### DEFINITIONS

**Maker** - bet creator  
**Taker** - user who accepts bet
**CollateralToken** - Token used as collateral to settle a escrow , this is set to $DEGEN

A Maker creates a bet and inputs 3 parameters: Amount, Taker Address, and if they think the Chiefs will win. These inputs will be performed by JeevesBot on the frontend. Amount is in wei and needs to be converted from a frontend with 10^18 decimals as the $DEGEN contract indicates. Maker inputs "false" if they think the Niners will win and "True" if they think the Chiefs will win

Anyone can close an escrow once all necessary checks are cleared.

Maker can define taker address as "0x0000000000000000000000000000000000000000" allowing anyone to be Taker or they can limit it to a specific address. JeevesBot can work this out on the frontend.

Betting can be paused at any time by the contract owner. To be deteremined if users can continue to bet during the game or if betting will stop at kickoff.

### Contracts - Base

**DegenEscrow** -
