#!/bin/bash

#fonction de présentation des options
man(){
	echo " "	
	echo "NAME ayoSvg.sh, permet de gérer des sauvegardes unitaires/incrémentales sur différentes périodes"
	echo " "
	echo "OPTION"
	echo " "
	echo "-p, Définit le chemin raçine de la sauvegarde. Ce répertoire doit être existant."
	echo "-i, Permet d'initialiser une sauvegarde en créant un module, passé en argument, ainsi que les fichiers de configuration."
	echo "-f, affiche la liste des modules"
	echo "-s, sauvegarde ponctuelle d'un module"
	echo "-q, sauvegarde en mode automatique"
	echo "-m, module"
	echo "-x, edite la liste des fichiers à exclure"
	echo "-n, edite la liste des fichiers à inclure"
}



# function testant/créant les répertoires utilisés pour la sauvegarde
# $1 = nom du module 
# si $2=c alors création du répertoire manquant
# retour : 0=repertoire manquant, 1=répertoire ok, 2= creation err
checkRep(){
	ret=1
	pathModule=$pathBase".aoySvg/"$1
	if [ ! -d $pathBase".aoySvg" ]
	then
		if [ $2 = "c" ]
		then
			mkdir $pathBase".aoySvg"
		else
			return 0
		fi	
	fi
	
	if [ ! -d  $pathModule"/_conf" ]

	then 
		ret=0
		if [ $2 = "c" ]
		then
			echo "Création du fichier de configuration "$pathModule"_conf"
			#creation fichier de configuration
			echo "# Fichier de configuration" > $pathModule"_conf"
			echo " " >> $pathModule"_conf"
			echo " " >> $pathModule"_conf"
			echo " " >> $pathModule"_conf"
			echo " " >> $pathModule"_conf"
			echo " " >> $pathModule"_conf"
			echo " " >> $pathModule"_conf"
			echo " " >> $pathModule"_conf"
			echo " " >> $pathModule"_conf"
			echo "Création du fichier des ajouts "$pathModule"_inc"
			echo " " > $pathModule"_inc"
			echo "Création du fichier des exclus "$pathModule"_exc"
			echo " " > $pathModule"_exc"

		fi
	fi

	periode=(single dayO dayE week month year)
	pathModuleSvg=$pathBase$1
	echo "Création du répertoire "$pathModuleSvg
	mkdir $pathModuleSvg
	pathModuleSvg=$pathModuleSvg/
	for per in ${!periode[*]}
	do
		if [ ! -e  "$pathModuleSvg${periode[per]}" ]
		then 
			ret=0
			if [ $2 = "c" ]
			then
				mkdir "$pathModuleSvg${periode[per]}"
				echo "Création du répertoire : $pathModuleSvg${periode[per]}"
			fi
		fi
		
	done

	if [ $ret=0 ] 
	then 
		return 0 
	fi
	if [ $ret=1 ] 
	then 
		return 1 
	fi
	return ret

}

# fonction affichant les modules
affiche_module(){
	list=$pathBase".aoySvg/*conf"
	ls $list | cut -d_ -f1 | cut -d/ -f2
}

# fonction de sauvegarde ponctuelle
sauvegarde_uniq(){
   	#tar -zcvf /home/sebock/svg/local/$1/prod-`date +%u`.tar.gz /var/www/prod/   
	if [ ! -e $pathBase".aoySvg/"$module"_conf" ]
	then
		echo "le fichier de configuration du module $module est introuvable dans "$pathBase".aoySvg/"$module"_conf"
		exit 5
	fi	
	source $pathBase".aoySvg/"$module"_conf"

	tar -zcvf $pathBase$module"/single/"$module"_"`date +%Y_%m_%d-%H_%M_%S`.tar.gz -T $pathBase".aoySvg/"$module"_inc" -X $pathBase".aoySvg/"$module"_exc"  
}

# fonction de sauvegarde incrémentale
sauvegarde_incr(){
   	#tar -zcvf /home/sebock/svg/local/$1/prod-`date +%u`.tar.gz /var/www/prod/   
	if [ ! -e $pathBase".aoySvg/"$module"_conf" ]
	then
		echo "le fichier de configuration du module $module est introuvable dans "$pathBase".aoySvg/"$module"_conf"
		exit 5
	fi	
	source $pathBase".aoySvg/"$module"_conf"

	tar --listed-incremental=$pathBase".aoySvg/"$module"_incr" -zcvf $pathBase$module"/single/"$module"_"`date +%Y_%m_%d-%H_%M_%S`.tar.gz -T $pathBase".aoySvg/"$module"_inc" -X $pathBase".aoySvg/"$module"_exc"  
}

# fonction supprime le fichier référant pour l'incrémental
suppr_incr(){
	rm $pathBase".aoySvg/"$module"_incr" 

}

# function d'edition de la liste a inclure dans la sauvegade
edite_inclure(){

	vim $pathBase".aoySvg/"$module"_inc"

}

# function d'edition de la liste a inclure dans la sauvegade
edite_exclure(){

	vim $pathBase".aoySvg/"$module"_exc"

}

# function d'edition de la liste a inclure dans la sauvegade
edite_conf(){

	vim $pathBase".aoySvg/"$module"_conf"

}


#affiche l'aide
#if [ $1="" ]
#	then 
#		man
#		exit 0
#fi		

# fonction testant l'existance d'un module
isModule_existe(){
	if [[ -z $1 ]]
	then
		return 10
	fi
	if [ ! -e $2".aoySvg/"$1 ]
	then
		return 10
	else
		return 100
	fi
}

pathBase=""
periode=""
pathOri=""
pathDest=""
prefix=""
fichier_config=""
module=""
action=""


while getopts "ip:fhsq:m:nxo" option
do
	case $option in
		p) # path
			pathBase=$OPTARG/
		   	;;
		i) # init
			action="action_initialisation"
			;;
		f) # affiche les modules
			action="action_affichage_module"
			;;
		h) # affiche l'aide
			action="action_man"
			;;
		m) #module
			module=$OPTARG
			;;	
		s) # sauvegarde ponctuelle dans le repertoire single
			action="action_sauvegarde_uniq"	
			;;
		q) # sauvegarde en mode automatique
			action="action_sauvegarde_automatique"	
			;;	
		x) # edite la liste des fichiers à exclure
			action="action_edite_exclure"	
			;;
		n) # edite la liste des fichiers à inclure
			action="action_edite_inclure"	
			;;	
		o) # edite la conf
			action="action_edite_conf"	
			;;	
	esac
done

# Traitement des différents cas
# initialisation d'un module
case $action in

		action_initialisation)
			if [ -z $module ]
			then
				echo "préciser -m (module)"
				exit 0
			fi	
	    	checkRep $module "c"
			;;
		
		action_sauvegarde_uniq)
			sauvegarde_uniq
			;;	
		
		action_man)
			man
			;;	
		
		action_affichage_module)
			affiche_module
			;;	
		
		action_edite_exclure)
			ret=$(isModule_existe $module $pathBase)	
			if [[ $ret -eq 10 ]]
			then
				echo "préciser -m (module existant)"
				exit 0
			fi	
			edite_exclure
			;;
		action_edite_conf)
			ret=$(isModule_existe $module $pathBase)	
			if [[ $ret -eq 10 ]]
			then
				echo "préciser -m (module existant)"
				exit 0
			fi	
			edite_conf
			;;


		action_edite_inclure)
			ret=$(isModule_existe $module $pathBase)	
			if [[ $ret -eq 10 ]]
			then
				echo "préciser -m (module existant)"
				exit 0
			fi	
			edite_inclure
			;;
esac



#Chargement du fichier de configuration
exit 0

