# Obligations Légales, CGU & Politique de Confidentialité — Life RPG

## 1. Mentions Légales

### Éditeur du service
- Nom de l'application : Life RPG
- Statut : Édité à titre individuel (personne physique)
- Contact : argam7300@gmail.com

### Hébergement
- Hébergeur : Oracle Cloud Infrastructure (Oracle Corporation)
- Localisation des serveurs : France (Région Paris)
- Site web : https://www.oracle.com/cloud/

### Propriété intellectuelle et Code Source
- **Application client (Flutter) :** Le code source de la dernière version officielle est toujours disponible publiquement sur GitHub.
- **Serveur (Backend) :** Le code source du serveur est publié en Open Source. La mise à jour du dépôt public peut intervenir avec un léger décalage par rapport aux déploiements en production.
- Les utilisateurs conservent l'intégralité des droits sur leurs créations personnelles.

---

## 2. Conditions Générales d'Utilisation (CGU)

### Condition d'âge
- Réservé aux personnes âgées d'au moins 13 ans (ou l'âge légal de consentement numérique de votre pays de résidence).

### Interdictions
- Utilisation frauduleuse ou tentative de perturbation des services et API.
- Diffusion de contenus illégaux, haineux ou offensants dans les espaces communautaires (guildes).
- Harcèlement ou comportements nuisibles envers les autres utilisateurs.

### Biens et monnaie virtuelle
- Les éléments virtuels (XP, badges, niveaux, monnaies du jeu) n'ont aucune valeur réelle ou financière.
- Ils ne peuvent faire l'objet d'aucun échange, vente ou remboursement en devise réelle.

### Limite de responsabilité
- Le service est fourni « en l'état » sans garantie de disponibilité continue.
- L'éditeur ne peut être tenu responsable en cas de perte d'accès au compte résultant de la perte de la clé de chiffrement ou des identifiants par l'utilisateur.

---

## 3. Politique de Protection des Données (RGPD)

### Architecture de chiffrement et sécurité des données

Life RPG distingue deux niveaux de protection selon la nature des données :

#### 1. Données individuelles de jeu (Chiffrement de bout en bout / Zero-Knowledge)
Vos données de progression personnelles (quêtes, objectifs, tâches, habitudes) sont chiffrées sur votre appareil avant tout envoi vers le serveur.
- **Principe :** L'administrateur du serveur ne détient pas vos clés de chiffrement client et ne peut en aucun cas lire le contenu de vos quêtes et données personnelles de progression.
- **Champs chiffrés :** `encrypted_data`, `encrypted_data_iv`, `encrypted_data_salt`, `encrypted_data_updated`.

#### 2. Données de guilde et messages communautaires (Chiffrement au repos)
Les données partagées au sein des guildes (messages, informations de groupe) sont chiffrées en base de données (*encrypted at rest* avec AES-256 ou équivalent) au moyen de clés gérées côté serveur.

#### 3. Données de compte non chiffrées (Nécessaires au fonctionnement)
- **Identifiants :** Nom d'utilisateur (*username*), adresse e-mail.
- **Mots de passe :** Hachés de manière sécurisée (Argon2 ou Bcrypt), jamais stockés en clair.
- **Informations de jeu publiques :** Niveau global, XP, badges non confidentiels.

### Base légale du traitement
- **Exécution du contrat :** Nécessaire pour fournir le service, la connexion et la synchronisation multiplateforme.
- **Intérêt légitime :** Sécurisation des infrastructures, prévention des fraudes et limitation de débit (*rate limiting*).

### Cookies et identifiants de session
- Aucun cookie publicitaire, traceur d'analyse tierce ou cookie de ciblage n'est utilisé.
- Seuls des jetons de session ou cookies techniques strictement nécessaires à la connexion sont exploités.

### Droits des utilisateurs (RGPD)
Conformément à la réglementation européenne, vous disposez des droits suivants :
1. **Accès :** Demander un export de vos données stockées.
2. **Rectification :** Corriger vos informations inexactes.
3. **Effacement :** Suppression définitive de votre compte et des données associées.
4. **Portabilité :** Récupération de vos données dans un format réutilisable.

### Conservation et suppression des données
- Vos données sont conservées tant que votre compte reste actif.
- Lors d'une demande de suppression de compte via l'application, l'effacement de vos données sur le serveur de production est exécuté.
- Les journaux d'accès techniques (*logs* serveur) sont conservés 12 mois maximum à des fins strictes de sécurité.

---

### Contact pour exercer vos droits :
📩 Courriel : argam7300@gmail.com

*Document mis à jour le : 6 septembre 2026*