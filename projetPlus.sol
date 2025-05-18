// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;
// Projet n°1 : @solomontaffou promo - Berners-Lee
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Vote is Ownable {

    //contrat appelé uniquement par "adress owner"
    constructor() Ownable(msg.sender) {}
    // Etape 1, Etablir les variables demandées:

    
    enum WorkflowStatus {           //  les differents statut de vote
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public status;

    //  on creer la whitelist
    mapping(address => bool) public whitelist;
    address[] public listeWhitelisted;

    // constructeur de la proposition
    struct Proposal {
        string description;
        uint voteCount;
    }

    Proposal[] public proposals; //tableau de propostion => proposals

    
    mapping(address => bool) public hasVoted;  // on adresse un booléen à l'adresse pour savoir s'il a voté (true/false)
    mapping(address => uint) public votedProposalId; //

    
    uint public winningProposalId;   //  id du gagnant

    // Etape 2 : fonctions appelées par onlyOwner du contrat

    function ajouterAdresse(address _adresse) public onlyOwner {
        require(!whitelist[_adresse], "Adresse deja whitelistee !"); //require pour éviter tout doublon
        
        listeWhitelisted.push(_adresse); // on push ensuite l'adresse dans la whitelist que seul l'owner décide
        whitelist[_adresse] = true;    // on assigne true à l'adresse dans la whitelist
    }

    function estAutorise(address _adresse) public view returns (bool) { // view car n'interagit pas avec la blockchain uniquement visible
        return whitelist[_adresse]; //return si l'adresse est bien dans la whitelist
    }

    // creation des fonctions  selon les phases de la session vote
    // variable status change selon etape du vote, on applique require pour verifier que nous sommes bien à l'étape precedente pour lui affectuer sa nouvelle valeur de statut

    function startProposalsRegistration() public onlyOwner {
        require(status == WorkflowStatus.RegisteringVoters, "Etape precedente requise");
        status = WorkflowStatus.ProposalsRegistrationStarted; 
    }

    function endProposalsRegistration() public onlyOwner {
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "Etape incorrecte");
        status = WorkflowStatus.ProposalsRegistrationEnded;
    }

    function startVotingSession() public onlyOwner {
        require(status == WorkflowStatus.ProposalsRegistrationEnded, "Propositions pas terminees");
        status = WorkflowStatus.VotingSessionStarted;
    }

    function endVotingSession() public onlyOwner {
        require(status == WorkflowStatus.VotingSessionStarted, "Vote pas en cours");
        status = WorkflowStatus.VotingSessionEnded;
    }



    function tallyVotes() public onlyOwner {
        require(status == WorkflowStatus.VotingSessionEnded, "Vote pas encore termine"); // condition que le vote soit terminé pour appeler la fonction

        uint maxVotes = 0;
        uint gagnant;

        for (uint i = 0; i < proposals.length; i++) {       //on créer une boucle pour faire chacune des propositions vote tant que i soit < que le nbr total de proposition
            if (proposals[i].voteCount > maxVotes) {        // puis on augmente sa valeur de 1 => i = i+1
                maxVotes = proposals[i].voteCount;
                gagnant = i;
            }
        }

        winningProposalId = gagnant; //on stock id gagnant dans la variable winningProposalID
        status = WorkflowStatus.VotesTallied; // puis on change le statut du "vote validé"
    }

    // Etape 3 Fonctions pour les votants

    function ajouterProposition(string memory desc) public {
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "Phase de propositions requise");
        require(whitelist[msg.sender], "Tu n'es pas dans la whitelist");    // condition d'entré ; msg.sender inscrit dans la whitelist pour que les électeurs proposent leurs idées
        proposals.push(Proposal(desc, 0)); //creer nouvelle proposition et on la push
    }

    function voter(uint proposalId) public {
        require(status == WorkflowStatus.VotingSessionStarted, "Le vote n'est pas en cours");
        require(whitelist[msg.sender], "Tu n'es pas whiteliste"); //on verifie que celui qui appelle la fonction est bien dans la list
        require(!hasVoted[msg.sender], "Tu as deja vote"); // et qu'il a pas vote pour eviter les doublons !
        require(proposalId < proposals.length, "Proposition invalide"); //verifie que la proposition existe

        hasVoted[msg.sender] = true; //on valide l'adresse comme quoi elle a bien voté
        votedProposalId[msg.sender] = proposalId;
        proposals[proposalId].voteCount++; // on ajoute 1 pour la proposition id du vote
    }

    // Etape 4 : FONCTIONS GET

    function getWinner() public view returns (string memory) {
        require(status == WorkflowStatus.VotesTallied, "Votes pas encore comptabilises"); // condition sur le statut fin des votes obligatoires
        return proposals[winningProposalId].description; //retourne le gagnant
    }

    function getStatus() public view returns (string memory) {
    string memory currentStatus;

    if (status == WorkflowStatus.RegisteringVoters) {           // On retourne les statuts selon processus de vote
        currentStatus = "Enregistrement des votants";
    } else if (status == WorkflowStatus.ProposalsRegistrationStarted) {
        currentStatus = "Depot des propositions";                           // on vérifie si on est pas dans chacune des phases
    } else if (status == WorkflowStatus.ProposalsRegistrationEnded) {       // dès que la phase correspond on affiche un message du statut actuel de la phase
        currentStatus = "Fin depot";
    } else if (status == WorkflowStatus.VotingSessionStarted) {
        currentStatus = "Vote en cours";
    } else if (status == WorkflowStatus.VotingSessionEnded) {
        currentStatus = "Vote termine";
    } else {
        currentStatus = "Votes comptes";
    }

        return currentStatus;
    }

    //fonction non demandé (supplémentaire) : permet de consulter les infos d'un électeur pour plus de transparence
    function getVoter(address _voter) public view returns (bool isRegistered, bool hasVoted_, uint votedId) {
    isRegistered = whitelist[_voter];  //
    hasVoted_ = hasVoted[_voter];
    votedId = votedProposalId[_voter];
    }



    //  Etape 5 : REINITIALISATION DU VOTE

    function reinitialiserSession() public onlyOwner {
    // On vérifie qu'on est bien à la fin du vote ou au tout début
    bool finDuVote = (status == WorkflowStatus.VotesTallied);       //crée une variable finDuVote(bool) => si = votesTallied alors fin du vote

    bool debutDuVote = (status == WorkflowStatus.RegisteringVoters);    //crée une variable debutvote, true si on est au début du vote
    require(finDuVote || debutDuVote, "Tu ne peux pas reinitialiser maintenant");  // require si une des deux des conditions est vraie

    
    delete proposals;           // efface toutes les anciennes propositions
 
    winningProposalId  = 0;   // le gagnant à zéro reprend sa valeur 0

    
    status = WorkflowStatus.RegisteringVoters;  // retour à l'étape initial du vote
}

}
