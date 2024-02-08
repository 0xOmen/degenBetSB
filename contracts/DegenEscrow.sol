// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

// Escrow app using Degen as collateral for bets on the 2024 Super Bowl
// Users (Maker) can open a bet and another user can take the bet (Taker); Taker can be specified by address
// Contract owner acts as oracle

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error BettingClosed();
error InsufficientAmount();
error TakerCannotBeMaker();
error AddressInelligible();
error AddressNotAllowed();
error WrongStatus();
error BetDoesNotExist();
error ClaimsNotAvailable();
error OracleError();

contract DegenEscrow is Ownable {
    enum Status {
        WAITING_FOR_TAKER,
        KILLED,
        IN_PROCESS,
        MAKER_WINS,
        TAKER_WINS,
        CANCELED
    }

    struct Bets {
        address maker; // address of the bet maker
        address taker; // address of the bet taker
        uint betAmount; // ammount of Degen each bettor must wager
        Status betStatus; // Status of bet as enum: WAITING_FOR_TAKER, KILLED, IN_PROCESS, MAKER_WINS, TAKER_WINS, CANCELED
        bool makerBetsChiefs; // boolean true if bet maker bets Chiefs to win, false if bets Niners win
        bool makerCancel; // define if Maker has agreed to cancel bet
        bool takerCancel; // defines if Taker has agreed to cancel bet
    }

    // Mapping of all opened bets
    mapping(uint256 => Bets) public allBets;
    // Universal counter of every bet made
    uint256 public betNumber;
    bool public bettingOpen;
    address DEGEN_ADDRESS;
    uint8 winningTeam; // 0 is default state, 1 is Chiefs, 2 is Niners

    event betCreated(
        address indexed maker,
        address indexed taker,
        uint256 indexed amount,
        uint256 betNumberID
    );
    event betTaken(uint256 indexed betNumberID);
    event betKilled(uint256 indexed _betNumber);
    event betClosed(
        address indexed winningAddress,
        uint256 indexed winAmount,
        uint256 indexed betNumberID
    );
    event oracleUpdate(uint8 indexed nflChamp);

    constructor(
        address collateralToken //  = 0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed  0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8
    ) Ownable(msg.sender) {
        bettingOpen = true;
        betNumber = 0;
        DEGEN_ADDRESS = collateralToken;
    }

    function createBet(
        uint256 _amount,
        address _takerAddress,
        bool _makerBetsChiefs
    ) public {
        if (bettingOpen == false) {
            revert BettingClosed();
        }
        if (_amount <= 0) {
            revert InsufficientAmount();
        }
        if (_takerAddress == msg.sender) {
            revert TakerCannotBeMaker();
        }
        allBets[betNumber].maker = msg.sender;
        allBets[betNumber].taker = _takerAddress;
        allBets[betNumber].betAmount = _amount;
        allBets[betNumber].betStatus = Status.WAITING_FOR_TAKER;
        allBets[betNumber].makerBetsChiefs = _makerBetsChiefs;
        allBets[betNumber].makerCancel = false;
        allBets[betNumber].takerCancel = false;

        betNumber++;
        emit betCreated(msg.sender, _takerAddress, _amount, betNumber);

        IERC20(DEGEN_ADDRESS).transferFrom(msg.sender, address(this), _amount);
    }

    function cancelBet(uint _betNumber) public {
        Bets memory currentBet = allBets[_betNumber];
        // Check that request was sent by bet Maker
        if (msg.sender != currentBet.maker) {
            revert AddressInelligible();
        }
        // check that bet is not taken
        if (currentBet.betStatus != Status.WAITING_FOR_TAKER) {
            revert WrongStatus();
        }

        // Change status to "KILLED"
        allBets[_betNumber].betStatus = Status.KILLED;
        emit betKilled(_betNumber);

        IERC20(DEGEN_ADDRESS).transfer(
            msg.sender,
            allBets[_betNumber].betAmount
        );
    }

    function takeBet(uint256 _betNumber) public {
        Bets memory currentBet = allBets[_betNumber];
        // check _betNumber exists
        if (_betNumber >= betNumber) {
            revert BetDoesNotExist();
        }
        //check if msg.sender can be taker
        if (msg.sender != currentBet.taker && currentBet.taker != address(0)) {
            revert AddressInelligible();
        }
        // require that the bet is not taken, killed, cancelled, or completed
        if (
            currentBet.betStatus != Status.WAITING_FOR_TAKER ||
            bettingOpen == false
        ) {
            revert BettingClosed();
        }

        // Assign msg.sender to Taker if Taker is unassigned
        if (currentBet.taker == address(0)) {
            allBets[_betNumber].taker = msg.sender;
        }

        allBets[_betNumber].betStatus = Status.IN_PROCESS;
        emit betTaken(_betNumber);

        IERC20(DEGEN_ADDRESS).transferFrom(
            msg.sender,
            address(this),
            currentBet.betAmount
        );
    }

    function closeBetting() public onlyOwner {
        bettingOpen = false;
    }

    function openBetting() public onlyOwner {
        bettingOpen = true;
    }

    function oracleDeclareWinner(uint8 _winner) public onlyOwner {
        // _winner
        // 0 = not updated
        // 1 = Chiefs
        // 2 = Niners
        winningTeam = _winner;
        bettingOpen = false;
        emit oracleUpdate(_winner);
    }

    function manuallyCloseBet(uint _betNumber) public {
        Bets memory currentBet = allBets[_betNumber];
        // check _betNumber exists
        if (_betNumber >= betNumber) {
            revert BetDoesNotExist();
        }
        // check bet status
        if (currentBet.betStatus != Status.IN_PROCESS) {
            revert WrongStatus();
        }
        // check claiming is available
        if (bettingOpen) {
            revert ClaimsNotAvailable();
        }

        // check winner
        address winningAddress;

        if (currentBet.makerBetsChiefs) {
            if (winningTeam == 1) {
                winningAddress = currentBet.maker;
            } else if (winningTeam == 2) {
                winningAddress = currentBet.taker;
            } else {
                revert OracleError();
            }
        } else {
            if (winningTeam == 1) {
                winningAddress = currentBet.taker;
            } else if (winningTeam == 2) {
                winningAddress = currentBet.maker;
            } else {
                revert OracleError();
            }
        }

        emit betClosed(winningAddress, (currentBet.betAmount * 2), _betNumber);

        if (winningAddress == currentBet.maker) {
            allBets[_betNumber].betStatus = Status.MAKER_WINS;
        } else {
            allBets[_betNumber].betStatus = Status.TAKER_WINS;
        }

        IERC20(DEGEN_ADDRESS).transfer(
            winningAddress,
            (currentBet.betAmount * 2)
        );
    }

    function ownerTransferERC20(
        address _tokenAddress,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(_tokenAddress).transfer(to, amount);
    }
}
