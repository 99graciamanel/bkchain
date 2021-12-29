
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract BetAP7 {                                   // Girona - Barça, Guanya el Barça
    
    address payable owner;                          // Creador de l'aposta
    uint256 public endorsement;                     // Aval

    uint256 public betPrize;                        // Preu fixe de l'aposta
    uint256 public timeOfCreation;                  // Temps de creació de l'aposta
    uint256 public timeOfEnd;                       // Temps de finalització de l'aposta
    uint256 public fee;                             // Comissió que s'emporta el creador de l'aposta
    
    bool public isFormalized;                       // L'owner ha acabat d'inicialitzar l'aposta

    uint256 public totalBets;                       // Total d'apostes acumulades
    uint256 public winnerOptionId;                  // Aposta guanyadora final
    
    uint256 public nOptions;
    struct Option {
        string name;                                // Victoria, Empat, Perdut
        uint256 totalOptionBets;                    // Apostes acumulades de l'opció
    }

    struct Bet {
        uint256 optionId;                           // Key del mapa de Options pel que ha apostat
        address payable gambler;                    // Adreça de l'apostador
        uint256 nBets;                              // Número d'apostes realitzades en aquesta transacció
    }

    mapping(uint256 => Option) public options;      // Mapa d'options (la clau és l'identificador)
    Bet[] bets;                                     // Mapa d'apostes (la clau és l'adreça de l'apostador)

    constructor(uint256 _timeOfEnd, uint256 _fee, uint256 _betPrize) payable {
        // El final de l'aposta és mínim al cap d'una setmana
        require(_timeOfEnd > block.timestamp + 7 days, "At least a margin of 7 days must be present");
        // L'interés és un percentatge del total
        require(_fee < 100, "Not a valid fee");

        owner = payable(msg.sender);
        endorsement = msg.value;
        timeOfCreation = block.timestamp;

        timeOfEnd = _timeOfEnd;
        fee = _fee;
        betPrize = _betPrize;
    }

    
    // Comprova si és abans d'haver acabat l'aposta
    modifier isBeforeExpirationBet() {
        require(block.timestamp < timeOfEnd, "Is not before expiration bet");
        _;
    }

    // Comprova si és després d'haver acabat l'aposta
    modifier isAfterExpirationBet() {
        // For test porpuses this is deactivated
        require(block.timestamp < timeOfEnd, "Is not after expiration bet");
        //require(block.timestamp > timeOfEnd, "Is not after expiration bet");
        _;
    }

    // Comprova si és el creador de l'aposta
    modifier isOwner() {
        require(msg.sender == owner, "You are not an owner of the bet");
        _;
    }

    // Crea una opció
    function createOption(string memory _name) isOwner isBeforeExpirationBet public {
        require(!isFormalized, "The bet has already been formalized");

        options[nOptions] = Option({
                                        name: _name,
                                        totalOptionBets: 0
                                    });
        nOptions = nOptions + 1;
    }

    // Una vegada s'ha formalitzat, no es poden crear més opcions
    function formalizeBet() isOwner isBeforeExpirationBet external {
        require(!isFormalized, "The bet has already been formalized");

        isFormalized = true;
    }

    // Finalitzar l'aposta, s'aplica la fee de l'owner al balanç i s'envien els guanys corresponents. 
    // Si ningú guanya, la banca siempre gana
    function endBet(uint256 _winnerOptionId) isOwner isAfterExpirationBet external {
        require(isFormalized, "The bet cannot be endeded because it was not initialized");
        require(_winnerOptionId < nOptions, "The option does not exist");

        winnerOptionId = _winnerOptionId;
        uint256 jackPot = balance() - endorsement - (balance() * fee / 100);

        bool success;

        for (uint256 i; i < bets.length; i++) {
            if (bets[i].optionId == winnerOptionId) {
                uint256 addressPot = jackPot * bets[i].nBets / options[_winnerOptionId].totalOptionBets;
                (success,) = bets[i].gambler.call{value: addressPot}("");
                require(success, "Failed to send money");
            }
        }

        (success,) = owner.call{value: balance()}("");
        require(success, "Failed to send money to owner");
    }

    // Crea una Bet amb la teva adressa i la pasta que has posat
    function bet(uint256 _optionId) isBeforeExpirationBet public payable {
        require(isFormalized, "The bet was not initialized");
        require(_optionId < nOptions, "The option does not exist");

        require(msg.value > 0, "Not a valid payment");
        require(msg.value % betPrize == 0, "Not a valid payment");

        bets.push(
            Bet({
                optionId: _optionId,
                nBets: uint256(msg.value / betPrize),
                gambler: payable(msg.sender)
            }));

        options[_optionId].totalOptionBets = options[_optionId].totalOptionBets + uint256(msg.value / betPrize);
        totalBets = totalBets + uint256(msg.value / betPrize);
    }

    // JackPot
    function balance() public view returns (uint256) {
        return address(this).balance;
    }
}
