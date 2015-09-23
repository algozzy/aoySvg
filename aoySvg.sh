#!/bin/bash

#===========================================================================
#fonction de présentation des options
#===========================================================================
man(){
	echo " "	
	tput bold
	echo "NAME"
	tput sgr0
	echo -e "\tayoSvg.sh, permet de gérer des sauvegardes unitaires/incrémentales sur différentes périodes"
	echo " "
	tput bold
	echo "DESCRIPTION"
	tput sgr0
	echo -e "\t-p, Définit le chemin raçine de la sauvegarde. Ce répertoire doit être existant."
	echo -e "\t-i, Permet d'initialiser une sauvegarde en créant un module, passé en argument, ainsi que les fichiers de configuration."
	echo -e "\t-f, affiche la liste des modules"
	echo -e "\t-s, sauvegarde ponctuelle d'un module"
	echo -e "\t-q, sauvegarde en mode automatique"
	echo -e "\t-m, module"
	echo -e "\t-x, edite la liste des fichiers à exclure"
	echo -e "\t-n, edite la liste des fichiers à inclure"
	echo -e "\t-o, edite le fichier de configuration du module"
	echo " "
	tput bold
	echo "AUTHOR"
	tput sgr0
	echo -e "\twritten by Sébastien BOCK"
	echo " "
	tput bold
	echo "REPORTING BUGS"
	tput sgr0
	echo " "
	tput bold
	echo "COPYRIGHT"
	tput sgr0
	echo -e "\tLicence MIT"
}



#===========================================================================
# function testant/créant les répertoires utilisés pour la sauvegarde
# $1 = nom du module 
# si $2=c alors création du répertoire manquant
# retour : 0=repertoire manquant, 1=répertoire ok, 2= creation err
#===========================================================================
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
			echo "# Jour de sauvegarde complète 0= Dimanche, 1= lundi ... " >> $pathModule"_conf"
			echo "conf_dayReset=0" >> $pathModule"_conf"
			echo " " >> $pathModule"_conf"
			echo "# nombre de jours entre 2 sauvegardes complètes" >> $pathModule"_conf"
			echo "conf_nbDaysBetweenFullSvg=7" >> $pathModule"_conf"
			echo " " >> $pathModule"_conf"
			echo "# Editeur" >> $pathModule"_conf"
			echo "conf_editor=vim" >> $pathModule"_conf"
			echo " " >> $pathModule"_conf"
			echo "# force la sauvegarde qu'importe le jour " >> $pathModule"_conf"
			echo "conf_dayNoMatter=1" >> $pathModule"_conf"
			
			echo " " >> $pathModule"_conf"
			echo "# Copie de la sauvegarde complète chaque mois ? " >> $pathModule"_conf"
			echo "conf_svgMonth=1" >> $pathModule"_conf"

			echo " " >> $pathModule"_conf"
			echo "# Copie de la sauvegarde complète chaque année ? " >> $pathModule"_conf"
			echo "conf_svgYear=1" >> $pathModule"_conf"


			echo "Création du fichier des ajouts "$pathModule"_inc"
			echo " " > $pathModule"_inc"

			echo "Création du fichier des exclus "$pathModule"_exc"
			echo " " > $pathModule"_exc"

		fi
	fi

	periode=(single day week month year)
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

#===========================================================================
# fonction affichant les modules
#===========================================================================
affiche_module(){
	list=$pathBase".aoySvg/*conf"
	#ls $list | cut -d_ -f1 | cut -d'/' -f2
	ls $list | rev | cut -d_ -f2 | cut -d'/' -f1 | rev
}

#===========================================================================
# fonction indiquant si la dernière sauvegarde est trop vieille
# 	$1 date de la dernière sauvegarde
#	$2 nb de jours entre 2 sauvegardes ponctuelles
#	$3 jour de la sauvegarde
#	$4 force la sauvegarde, qu'importe le jour
# Retour : 1 = sauvegarde complète à faire, 0 pas à faire
#===========================================================================
periode_done(){
	checkJour=false	
	if [[ -z $1 ]]
	then
		# date de derniere sauvegarde vide, faire la sauvegarde complete a tout prix
		return 1
	else
		#echo `date -d $1 +%s`
		#echo `date +%s` 
		
		# caclule la différence entre date du jour et la date de la dernière sauvegarde 
		diff=$((`date +%s` - `date -d $1 +%s`))
		#diff= $(( diff / 86400 ))
		diff=$(( $diff / 86400 ))
		if [[ $diff -ge $2 ]] 
		then
			# derniere sauvegarde trop vieille
			if [[ $4 -eq 1 ]]
			then
				# option impose la sauvegarde meme si pas le bon jour
				return 1
			else	
				if [[ $3 -eq `date +%w` ]]
				then
					return 1
				fi
			fi
		else	
			# dernière sauvegarde assez récente
			return 0
		fi
	fi

}

#===========================================================================
# fonction de sauvegarde ponctuelle
#===========================================================================
sauvegarde_uniq(){
	if [ ! -e $pathBase".aoySvg/"$module"_conf" ]
	then
		echo "le fichier de configuration du module $module est introuvable dans "$pathBase".aoySvg/"$module"_conf"
		exit 5
	fi	
	source $pathBase".aoySvg/"$module"_conf"

	tar -zcvf $pathBase$module"/single/"$module"_"`date +%Y_%m_%d-%H_%M_%S`.tar.gz -T $pathBase".aoySvg/"$module"_inc" -X $pathBase".aoySvg/"$module"_exc"  
}

#===========================================================================
# fonction de sauvegarde incrémentale
#===========================================================================
sauvegarde_incr(){
	
	# Determine si il y a besoin d'une sauvegarde complète
	doReset=false
	periode_done $state_date  $conf_nbDaysBetweenFullSvg $conf_dayReset $conf_dayNoMatter
	doReset=$?
	
	tar_incr=""
	tar_dest=""

	if [[ $doReset -eq 1 ]]
	then		
		# Sauvegarde complète
		echo "Sauvegarde complète"
		if [[ $state_indice -eq 1 ]]
		then
			state_indice=0
		else
			state_indice=1
		fi
		state_incr=0
		tar_incr=" --level=0 "
		state_date="$(date +"%Y-%m-%d")"
	else
		# Sauvegarde incrémentale
		state_incr=$(($state_incr+1))
	fi
	tar_dest=$pathBase$module"/day/"$module"_"$state_indice"_incr_"$state_incr".tar.gz" 
	echo "Fichier destination : "$tar_dest
	
	tar_duration=`date +%s`
	tar --listed-incremental=$pathBase"/.aoySvg/"$module_snapshot -zcvf $tar_dest $tar_incr -T $pathBase".aoySvg/"$module"_inc" -X $pathBase".aoySvg/"$module"_exc"  
	tar_duration=$((`date +%s` - $tar_duration))
	echo $tar_duration

	# Ecriture dans le fichier d'état
	new_file_svg_state  $state_date $state_indice $state_incr
	
	# ecriture dans le fichier log
	new_file_svg_log $tar_duration $tar_dest
}


#===========================================================================
# fonction créant le fichier de log de la sauvegarde complète
# $1 = date de la dernière sauvegarde complète
# $2 = indice de la sauvegarde encours
# $3 = indice incrémental. Remis à 0 à chaque nouvelle sauvegarde complète
#===========================================================================
new_file_svg_state(){
	fileLog=$pathBase".aoySvg/"$module"_state"	
	echo "# Date de la dernière sauvegarde" > $fileLog 
	echo "state_date="$1 >> $fileLog
	echo "# indice de semaine de la dernière sauvegarde"
	echo "state_indice="$2 >> $fileLog
	echo "# indice incrémental" >> $fileLog
	echo "state_incr=$3" >> $fileLog
}

#===========================================================================
# fonction créant un fichier log de la sauvegarde
# $1 = durée de la sauvegarde
# $2 = path fichier
# $3 = 
#===========================================================================
new_file_svg_log(){
	fileLog=$pathBase".aoySvg/"$module"_log"

	ligneAdd="date="`date +%Y_%m_%d-%H_%M_%S`
	ligneAdd=$ligneAdd";duration="$1
	ligneAdd=$ligneAdd";file="$2
	echo $ligneAdd >> $fileLog
}









#===========================================================================
# fonction supprime le fichier référant pour l incrémental
#===========================================================================
suppr_incr(){
	rm $pathBase".aoySvg/"$module"_incr" 

}

#===========================================================================
# function d edition de la liste a inclure dans la sauvegade
#===========================================================================
edite_inclure(){

	eval "$conf_editor" $pathBase".aoySvg/"$module"_inc"

}

#===========================================================================
# function d'edition de la liste a inclure dans la sauvegade
#===========================================================================
edite_exclure(){

	eval "$conf_editor"  $pathBase".aoySvg/"$module"_exc"

}

#===========================================================================
# function d'edition de la liste a inclure dans la sauvegade
#===========================================================================
edite_conf(){
	eval "$conf_editor" $pathBase".aoySvg/"$module"_conf"

}


#affiche l aide
#if [ $1="" ]
#	then 
#		man
#		exit 0
#fi		

# fonction testant l'existance d'un module
# $1 = module
# $2 = pathBase
# retour : <100 = non trouvé, 100 = trouvé
#===========================================================================
isModule_existe(){
#===========================================================================
	if [[ -z $1 ]]
	then
		return 11
	fi
	if [ ! -e $2".aoySvg/"$1"_conf" ]
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

state_date=""
state_indice=""
state_incr=0
conf_dayReset=0
conf_nbDaysBetweenFullSvg=7

while getopts "ip:fhsqm:nxo" option
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
# initialisation d un module
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
			if [ -z $module ]
			then
				echo "préciser -m (module)"
				exit 0
			fi	
			source $pathBase".aoySvg/"$module"_conf"
			sauvegarde_uniq
			;;

		action_sauvegarde_automatique)
			isModule_existe $module $pathBase
			ret=$?
			if [[ $ret -lt 100 ]]
			then
				echo "préciser -m (module existant)"
				exit 0
			fi	
			source $pathBase".aoySvg/"$module"_conf"
			source $pathBase".aoySvg/"$module"_state"	
			sauvegarde_incr
			;;	
		
		action_man)
			man
			;;	
		
		action_affichage_module)
			source $pathBase".aoySvg/"$module"_conf"
			affiche_module
			;;	
		
		action_edite_exclure)
			isModule_existe $module $pathBase
			ret=$?
			if [[ $ret -lt 100 ]]
			then
				echo "préciser -m (module existant)"
				exit 0
			fi	
			source $pathBase".aoySvg/"$module"_conf"
			edite_exclure
			;;
		action_edite_conf)
			isModule_existe $module $pathBase
			ret=$?
			if [[ $ret -lt 100 ]]
			then
				echo "préciser -m (module existant)"
				exit 0
			fi	
			source $pathBase".aoySvg/"$module"_conf"
			edite_conf
			;;


		action_edite_inclure)
			isModule_existe $module $pathBase
			ret=$?
			if [[ $ret -lt 100 ]]
			then
				echo "préciser -m (module existant)"
				exit 0
			fi	
			source $pathBase".aoySvg/"$module"_conf"
			edite_inclure
			;;
esac



#Chargement du fichier de configuration
exit 0
