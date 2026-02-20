# Analyse des Transactions Immobilières (2023)

## 👥 Auteurs
* **Abdoul Barik ASSOUMANA KALME ANZA**
* **Fatoumata Binta DIALLO**

## 📝 Description
Ce projet propose une analyse statistique et économétrique des transactions immobilières réalisées en 2023. Réalisé en **SAS**, il couvre l'importation des données, le nettoyage, l'analyse exploratoire (EDA), et la modélisation (régressions linéaires et logistiques).

## 📊 Méthodologie
1. **Préparation des données** : 
   * Filtrage des transactions de 2023.
   * Création de variables (surface `sqm`, catégories `year_build`, variable binaire `price`).
2. **Analyse Exploratoire** :
   * Nuages de points et Heatmaps pour étudier la relation entre le prix, la surface et le nombre de pièces.
   * Analyse de la distribution des surfaces (histogrammes avec moyenne/variance).
3. **Modélisation** :
   * **Régression linéaire** (MCO et estimateurs robustes) pour quantifier l'impact de la surface et de l'année de construction sur le prix d'achat.
   * **Régression logistique** pour prédire la probabilité qu'un bien dépasse 900 000 €. Évaluation via Courbe ROC (AUC = 0.7865) et matrice de confusion (Sensibilité = 98.37%).

## 🚀 Exécution
Le code principal se trouve dans le fichier `script.sas`. Les données d'entrée doivent être placées dans un fichier `immo_data.csv` accessible par l'environnement SAS.
