#!/bin/bash

###################################################################
#
#	Ajout des comptes du CRIM sur un serveur Linux
#
###################################################################
#
#  Script created by Damien PIQUET: damien.piquet@iutbeziers.fr || piqudam@gmail.com
#
#  Add users listed in users.lst and add public key in from <login>.pub in .ssh directory
#

loginShell="/bin/bash"

passwdFile='/etc/passwd'
shadowFile='/etc/shadow'
groupFile='/etc/group'
homePath='/home'
membersFile="./users.lst"

userID=1000
groupID=1000

ret_err=1
ret_ok=0

# check required files exists
if [ ! -f $passwdFile ]; then	
    echo "ERROR, $passwdFile does not exists ! Aborting..."
    exit 1;
fi

if [ ! -f $shadowFile ]; then
    echo "ERROR, $shadowFile does not exists ! Aborting..."
    exit 1;
fi

if [ ! -f $groupFile ]; then
    echo "ERROR, $groupFile does not exists ! Aborting..."
    exit 1;
fi

if [ ! -f $membersFile ]; then
    echo "ERROR, $membersFile does not exists ! Aborting..."
    exit 1;
fi

if [ ! -d $homePath ]; then
    echo "ERROR, directory $homePath does not exists ! Aborting..."
    exit 1;
fi

function create_account() {

    if [ $# -ne 1 ]; then
        echo "ERROR in create_account function usage !"
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
	echo "ERROR, user $userName already exists !!! Skipping..."
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
	echo "Warning ! group $userName already exists !"
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
	echo "ERROR, Could not create $userName home directory !"
	return 1;
    fi

    mkdir $homePath/$userName/.ssh
    if [ $? -ne 0 ]; then
	echo "ERROR, Could not create $userName .ssh directory !"
	return 1;
    fi

    cat ./$userName.pub > $homePath/$userName/.ssh/authorized_keys
    if [ $? -ne 0 ]; then
	echo "ERROR, Could not create authorized_ key file for $userName !"
	return 1;
    fi

    chmod 600 $homePath/$userName/.ssh/authorized_keys
    if [ $? -ne 0 ]; then
        echo "WARNING, could not change $userName's authorized key file permission !";
    fi

    chmod 700 $homePath/$userName/.ssh
    if [ $? -ne 0 ]; then
	echo "WARNING, could not change $userName's .ssh directory permission !";
    fi

    chown -R $curUserId:$curGroupId $homePath/$userName
    if [ $? -ne 0 ]; then
	echo "WARNING, chown operation $curUserId:$curGroupId on $userName home directory failed !"
    fi

    echo "$userName added to system"
    return 0

}

# Read members.lst file
while read line
do
    create_account "$line"
done < ./members.lst

echo "User added to system !"

