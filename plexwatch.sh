#!/bin/bash
#writen by Tyler Wallenstein 01/03/2018
##################################################################################################
###### user settings #############################################################################
##################################################################################################

watchFolder=/mnt/nfs/plexwatch # What folder do you want me to watch for updates?
timer=60 # how long do you want me to wait in seconds between checks?
logFile=$watchFolder/Watch.Log # were should i put my log file?

##################################################################################################
###### end of user settings ######################################################################
##################################################################################################
#14.04
#PV () {
# #getting the installed version of Plex Media Server when called
# plexVersionDirty=`/usr/bin/dpkg -p plexmediaserver | grep Version`
# plexVersion=${plexVersionDirty##*: }
# plexVersionND=${plexVersion%%-*}
# plexVersionND=${plexVersionND//.}
# plexVersionND1=$plexVersionND
#}

#18.04
PV () {
 #getting the installed version of Plex Media Server when called
 plexVersionDirty=`/usr/bin/dpkg -l plexmediaserver | grep plex`
 plexVersion=${plexVersionDirty##*er }
 plexVersionND1=${plexVersion%%-*}
 plexVersionND=${plexVersionND1//.}
}


LOOK () {
	plexWatch=`ls | grep plexmediaserver*.deb`
	plexWatchND=${plexWatch##*r_}
	plexWatchND=${plexWatchND%%-*}
	plexWatchND=${plexWatchND//.}
}

LOG () {
	#logs input in a standered format when called
	now=`date`
	echo $now -- $1 >> $logFile
}

COMPARE () {
	if [ $plexWatchND -gt $plexVersionND ] 
		then
		 compared=1
		else
		 compared=0
	fi
}
LOG "Plex watch started!"

#setting some needed enviroment varuibles dpkg to run 
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

while(true)
 do
  # Start of watch
  cd $watchFolder
  LOOK
  while [ "$plexWatch" != "" ] #checking to see if we found anything in watch folder
   do
    LOG "$plexWatch detected, running update"
    #saving version number that is curently installed to compare later
    PV
    COMPARE
    case $compared in
     1)
     oldVersion=$plexVersion
     #running update
     /usr/bin/dpkg -i $watchFolder/$plexWatch
     PV #Pulling version that is now installed on the server
     while [ $oldVersion == $plexVersion ] #comparing new and old version to ensrue we installed it if not
     									  #we will try it again
      do
       LOG "Install of $plexWatch failed trying again"
       /usr/bin/dpkg -i $watchFoler/$plexWatch
       PV #getting current version after second attempt
       break #breaking out of loop
      done
     if  [ $oldVersion == $plexVersion ] # comparing versions if it still failes at this poit me note it and abort
      then
       LOG "Install of $plexWatch Failed not trying again, removing .deb assuming bad, and aborting opperation."
      else
       LOG "Updated from $oldVersion to $plexVersionND1 removing .deb since job is complete!"
      fi
     ;;
     0)
     LOG "$plexWatch is either older or the same as what is intalled now, removing .deb, aborting opperation"
     ;;
    esac
    rm $plexWatch #removing the .deb from the folder since we are done no matter the out come!
     break # breaking out of install logic
     done
    sleep $timer #waiting for user set amount of time then we will look again.
 done
#end of watch
