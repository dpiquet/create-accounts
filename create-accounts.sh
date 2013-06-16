#!/bin/bash

###################################################################
#
#	Ajout des comptes du CRIM sur un serveur Linux
#
###################################################################
#
#  Script ecrit par Damien PIQUET: damien.piquet@iutbeziers.fr || piqudam@gmail.com
#
#  Ajoute les membres du CRIM listes dans le fichier members.lst et ajoute la cle publique (SSH) contenu dans le fichier <login>.pub
#  Les utilisateurs ajoutes par ce script ne peuvent se connecter que par cle publique
#  Attention quand même à la configuration de SSHD ;-)
#

loginShell="/bin/bash"

passwdFile='/etc/passwd'
shadowFile='/etc/shadow'
groupFile='/etc/group'
homePath='/home'
membersFile="./members.lst"

userID=1000
groupID=1000

# check required files exists
if [ ! -f $passwdFile ]; then	
    echo "Erreur, $passwdFile n'existe pas ! Abandon..."
    exit 1;
fi

if [ ! -f $shadowFile ]; then
    echo "Erreur, $shadowFile n'existe pas ! Abandon..."
    exit 1;
fi

if [ ! -f $groupFile ]; then
    echo "Erreur, $groupFile n'existe pas ! Abandon..."
    exit 1;
fi

if [ ! -f $membersFile ]; then
    echo "Erreur, $membersFile n'existe pas ! Abandon..."
    exit 1;
fi

if [ ! -d $homePath ]; then
    echo "Erreur, le repertoire $homePath n'existe pas ! Abandon..."
    exit 1;
fi

function create_account() {

    if [ $# -ne 1 ]; then
        echo "Erreur d'utilisation de la fonction utilisateur create_account !"
	return 1;
    fi

    userCreated=1
    groupCreated=1

    # initialized at 9999 because 0 is root's userid /!\
    curUserId=9999
    curGroupId=9999

    userName=$1

    # Do not add duplicate users !!
    grep $userName $passwdFile
    if [ $? -eq 0 ]; then
	echo "Erreur, l'utilisateur $userName existe deja !!! Passage au suivant..."
	return 1;
    fi

    # /etc/passwd entry
    while [ $userCreated -ne 0 ]
    do
	grep $userID $passwdFile
	if [ $? -eq 1 ]; then
	    echo "$userName:x:$userID:65534::/home/$userName:$loginShell" >> $passwdFile
	    userCreated=0;
            curUserId=$userID
	    ((++userID));
	else	
	    ((++userID));
	fi
    done

    # Shadow entry
    echo "$userName:*:15811:0:99999:7:::" >> $shadowFile

    # do not create duplicate groups !!
    # skip creation if group already exists
    grep $userName $groupFile
    if [ $? -eq 0 ]; then
	echo "Attention ! le groupe $userName existe deja !"
    else

        # /etc/group entry
        while [ $groupCreated -ne 0 ]
        do
	    grep $groupID $groupFile
	    if [ $? -eq 1 ]; then
	        echo "$userName:x:$groupID:$userName" >> $groupFile
	        groupCreated=0
		curGroupId=$groupID
		((++groupID));
	    else
	        ((++groupID));
	    fi
        done;
    fi

    # home and .ssh directory
    mkdir $homePath/$userName
    if [ $? -ne 0 ]; then
	echo "Erreur ! la creation du repertoire utilisateur de $userName a echoue !"
	return 1;
    fi

    mkdir $homePath/$userName/.ssh
    if [ $? -ne 0 ]; then
	echo "Erreur, la creation du repertoire .ssh de l'utilisateur $userName a echoue !"
	return 1;
    fi

    cat ./$userName.pub > $homePath/$userName/.ssh/authorized_keys
    if [ $? -ne 0 ]; then
	echo "Erreur, l'ajout de la cle publique de l'utilisateur $userName a echoue !"
	return 1;
    fi

    chmod 600 $homePath/$userName/.ssh/authorized_keys
    if [ $? -ne 0 ]; then
        echo "Attention ! l'application des droits sur la cle publique de l'utilisateur $userName a echoue !";
    fi

    chmod 700 $homePath/$userName/.ssh
    if [ $? -ne 0 ]; then
	echo "Attention ! L'application des droits sur le repertoire .ssh de l'utilisateur $userName a echoue !";
    fi

    chown -R $curUserId:$curGroupId $homePath/$userName
    if [ $? -ne 0 ]; then
	echo "Attention ! l'operation chown $curUserId:$curGroupId sur le repertoire utilisateur de $userName a echoue !"
    fi

    echo "Utilisateur $userName ajoute au systeme"
    return 0

}

# Read members.lst file
while read line
do
    create_account "$line"
done < ./members.lst

echo "Ajout des utilisateurs termine !"

