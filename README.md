Solomon TAFFOU Formation Dev Blockchain Promo : Berners-Lee

Feuille de route de mon projet de vote.

J'ai décidé de construire le projet en 5 étapes.

Etape 1 : On importe la librairie openzepplin pour importer Ownable à notre contrat.
On instaure nos variables essentielles et event pour la session vote.
(WorkflowStatus, status, whitelist, listeWhitelisted, Proposal, proposals, winningProposalId)

Etape 2 : On construit les fonctions accessible uniquement par l'Owner.
(function ajouterAdresse,function startProposalsRegistration, function endProposalsRegistration, function startVotingSession, function endVotingSession, function tallyVotes)

Etape 3 : On créer les fonctions pour élécteurs.
(function ajouterProposition, function voter)

Etape 4 : On construit nos fonctions pour la lecture des résultats et la transparence.
(function getWinner, function getStatus, function getVoter)

Etape 5 : La rénitialisation de la session Par l'OWNER
(function reinitialiserSession)
