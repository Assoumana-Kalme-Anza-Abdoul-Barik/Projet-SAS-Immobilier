* ============================================================================== ;
* PROJET : ANALYSE DES TRANSACTIONS IMMOBILIÈRES (2023)
* AUTEURS : ASSOUMANA KALME ANZA Abdoul Barik
* ============================================================================== ;

* ============================================================================== ;
* 1. IMPORTATION DES DONNÉES ET VÉRIFICATION
* ============================================================================== ;
FILENAME REFFILE '/home/u64080648/sasuser.v94/Data_TP_6.csv';

PROC IMPORT DATAFILE=REFFILE
    DBMS=CSV
    REPLACE
    OUT=work.immo_data;
    GETNAMES=YES;
RUN;

PROC CONTENTS DATA=work.immo_data; RUN;

proc means data=work.immo_data nmiss n;
    var _numeric_;
run;

* ============================================================================== ;
* 2. PRÉPARATION DES DONNÉES (FILTRAGE 2023 ET SÉLECTION)
* ============================================================================== ;
data immo2023;
    set work.immo_data;
    year = year(date); 
    if year = 2023;
run;

data immo2023;
    set immo2023;
    keep house_type no_rooms purchase_price sqm_price year_build;
run;

* Étape 1 : Réconstituer la variable 'sqm' (surface);
data immo2023;
    set immo2023;
    sqm = purchase_price / sqm_price;
run;

* ============================================================================== ;
* 3. ANALYSE EXPLORATOIRE (GRAPHIQUES ET DISTRIBUTIONS)
* ============================================================================== ;
* Filtrer les biens construits après 1950 pour l'analyse visuelle;
data immo_post_1950;
    set immo2023;
    if year_build > 1950;
run;

* Nuage de points : Surface vs Prix d'achat;
proc sgplot data=immo_post_1950;
    scatter x=sqm y=purchase_price / group=year_build 
        markerattrs=(symbol=circlefilled) 
        transparency=0.5;
    title "Nuage de Points : Surface vs Prix d'achat (Biens > 1950)";
    xaxis label="Surface (m²)";
    yaxis label="Prix d'achat";
run;

* Heatmap : Nombre de pièces vs Prix d'achat;
proc sgplot data=immo2023;
    heatmap x=no_rooms y=purchase_price / colormodel=(violet red);
    xaxis label="Nombre de pièces";
    yaxis label="Prix d’achat";
    title "Heatmap : Nombre de pièces vs Prix d’achat";
run;

* Statistiques de la surface (Moyenne et Variance);
proc means data=immo2023 mean var;
    var sqm;
    output out=stats mean=mean_sqm var=var_sqm;
run;

data _null_;
    set stats;
    call symputx('mean_sqm', mean_sqm);
    call symputx('var_sqm', var_sqm);
run;

* Histogramme de la surface par année de construction;
proc sgplot data=immo2023;
    histogram sqm / group=year_build transparency=0.5 nbins=20 scale=count;
    keylegend / title="Année de construction";
    refline &mean_sqm / axis=x label="Moyenne" lineattrs=(color=blue thickness=2);
    refline &var_sqm / axis=x label="Variance" lineattrs=(color=red pattern=shortdash thickness=2);
    title "Histogramme de la surface (sqm) par année de construction";
    xaxis label="Surface (m²)";
    yaxis label="Fréquence";
run;

* ============================================================================== ;
* 4. CRÉATION DE NOUVELLES VARIABLES CATÉGORIELLES
* ============================================================================== ;
* Variable Binaire : Price (Cher / Pas cher);
data immo2023;
    set immo2023;
    length price $ 10; 
    if sqm_price > 18000 then price = "cher";
    else price = "pas cher";
run;

* Catégories par année de construction (Quantiles);
proc univariate data=immo2023 noprint;
    var year_build;
    output out=quantiles pctlpts=20 40 60 80 pctlpre=Q;
run;

data immo2023;
    set immo2023;
    if _n_ = 1 then set quantiles;
    if year_build <= Q20 then year_cat = "-1965";
    else if year_build <= Q40 then year_cat = "-1971";
    else if year_build <= Q60 then year_cat = "-1977";
    else if year_build <= Q80 then year_cat = "-2001";
    else year_cat = "+2001";
run;

* Tableau de contingence;
proc freq data=immo2023;
    tables price*year_cat / chisq norow nocol nopercent;
    title "Tableau de contingence : Prix vs Année de construction";
run;

* ============================================================================== ;
* 5. MODÉLISATION LINÉAIRE (MCO ET ROBUSTE)
* ============================================================================== ;
* Transformation Logarithmique de la surface;
data immo2023;
    set immo2023;
    log_sqm = log(sqm);
run;

* Régression Linéaire Classique;
proc glm data=immo2023;
    class house_type;
    model purchase_price = year_build log_sqm no_rooms house_type / solution;
run;

* Régression Linéaire avec estimateurs robustes (Hétéroscédasticité);
proc robustreg data=immo2023;
    class house_type; 
    model purchase_price = year_build log_sqm no_rooms house_type;
run;

* ============================================================================== ;
* 6. MODÉLISATION LOGISTIQUE (PRIX > 900 000)
* ============================================================================== ;
* Création de la variable cible binaire;
data immo2023;
    set immo2023;
    high_price = (purchase_price > 900000);
run;

* Régression Logistique Principale;
proc logistic data=immo2023;
    class house_type(ref='Villa');
    model high_price(event='1') = year_build log_sqm no_rooms house_type;
    output out=logistic_out p=predicted_prob;
    roc; * Courbe ROC et calcul de l'AUC;
run;

* Régression Logistique sans logarithme pour calcul des cotes;
proc logistic data=immo2023;
    class house_type(ref='Villa');
    model high_price(event='1') = year_build sqm no_rooms house_type;
    output out=logistic_outa p=predicted_proba;
run;

* ============================================================================== ;
* 7. ÉVALUATION DU MODÈLE ET MATRICE DE CONFUSION
* ============================================================================== ;
* Création des classes prédites (Seuil = 0.5);
data confusion_matrix;
    set logistic_out;
    if predicted_prob >= 0.5 then predicted_class = 1; 
    else predicted_class = 0;
run;

* Matrice de confusion;
proc freq data=confusion_matrix;
    tables high_price*predicted_class / chisq;
    ods output CrossTabFreqs=confusion_counts;
run;

* Heatmap des probabilités prédites;
proc sgplot data=logistic_out;
    heatmap x=log_sqm y=no_rooms / colorresponse=predicted_prob colormodel=(green yellow red);
    xaxis label="Log(Surface)";
    yaxis label="Nombre de pièces";
    title "Heatmap des probabilités prédites par le modèle logistique";
run;