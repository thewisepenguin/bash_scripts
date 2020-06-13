#!/bin/bash


#SRVR_IP='172.16.120.130'
#USRNAME='ali'
#PRJCT_DIR='/home/ali/files'
#PRJCT_NAME=`basename $(readlink -f $1)`
#echo "Project name: $PRJCT_NAME"



password_process()
{
	#echo 'password process started'
	read -s -p "$USRNAME@$SRVR_IP's password: " SSHPASS
	export SSHPASS
}


run()
{
	#echo 'run started'
	#echo $SRVR_IP
	#echo $USRNAME
	if [[ -n $USRNAME && -n $SRVR_IP ]]; then
		password_process
		#IFS=' ' read -r OS OS_VER <<< $(sshpass -e ssh $USRNAME@$SRVR_IP '. /etc/os-release; echo $ID $VERSION_ID')
		#export OS
		#export OS_VER
		#echo
		#echo "Detected Distro: $OS"
		#echo "Version: $OS_VER"


	else
		echo 'You MUST specify both Username and Server Address.'
		show_help
		exit 1
	fi
}



####################################################################
###########################FUNCTION DEFENITIONS#####################
####################################################################

#########################INSTALL DOTNET#############################

install_dotnet() 
{
	echo 'STARTING TO INSTALL DOTNET'
	echo '--------------------------'
	IFS=' ' read -r OS OS_VER <<< $(. /etc/os-release; echo $ID $VERSION_ID)
	echo "Your OS: $OS	$OS_VER"
	echo -e "\n\n"
	############UBUNTU##############
	if [[ $OS == 'ubuntu' ]]; then
		wget https://packages.microsoft.com/config/ubuntu/$OS_VER/packages-microsoft-prod.deb -O packages-microsoft-prod.deb; sudo dpkg -i packages-microsoft-prod.deb; rm packages-microsoft-prod.deb; sudo add-apt-repository universe; sudo apt-get update; sudo apt-get install apt-transport-https; sudo apt-get update; sudo apt-get install dotnet-sdk-3.1



	############CENTOS##############
	elif [[ $OS == 'centos' ]]; then
		if [ $OS_VER == '7' ]; then
			sudo rpm -Uvh https://packages.microsoft.com/config/centos/$OS_VER/packages-microsoft-prod.rpm; sudo yum install dotnet-sdk-3.1
		elif [ $OS_VER == '8' ]; then
			sudo dnf install dotnet-sdk-3.1
		fi
	fi
	exit 0
}


#########################SHOW HELP#################################

show_help()
{
	echo -e "\n====================== HELP ======================\n\n"
	echo -e "--install-dotnet    ==>    To install DOTNET SDK on your machine (It's essential to build projects)\n\n"
	echo -e "--build -<i> <local project directory>"
	echo -e "--send -<i> <local project directory> -<p> <where to place on server> -<s> <server's IP> -<u> <your username on server>"
	echo -e "--deploy -<p> <project directory on server> -<s> <server's IP> -<u> <your username on server>"
	echo -e "--help | -h\n\n"
}


#########################SEND TO SERVER/BUILD############################

build()
{
	echo
	echo 'START BUILDING THE PROJECT'
	echo '--------------------------------------'

	cd $IF; dotnet publish -r linux-x64 --self-contained -o ./pub
	if [ $? -eq 0 ]; then
		echo "Build was successful."
	else
		echo "Build Faild, exiting..."
	exit 1
	fi

}


send()
{
	echo	
	echo 'START SENDING...'
	echo "To $PRJCT_DIR/$PRJCT_NAME on $SRVR_IP"
	if [ -d "$IF/pub" ]; then
		sshpass -e scp -r "$IF/pub" $USRNAME@$SRVR_IP:"$PRJCT_DIR/$PRJCT_NAME" 
		if [ $? != 0 ] ; then echo "Sending error. Terminating..." >&2 ; exit 1 ;else echo "Sent!"; fi
	else 
		echo 'pub directory under your project not found! Have you built the project?'
	fi
}




########################SERVICE CREATOR############################

service_dispatch()
{
	echo
	echo 'STARTING TO CREATE A SERVICE AND START IT'
	echo '-----------------------------------------'
	#DOTNET_PATH=$(sshpass -e ssh $USRNAME@$SRVR_IP "which dotnet")
	PRJCT_NAME="${PRJCT_DIR##*/}"; echo $PRJCT_NAME;	
	#echo "'$DOTNET_PATH'"

	echo "[Unit]
	Description=Sample service for .NET Web API App running on Linux

	[Service]
	WorkingDirectory=$PRJCT_DIR
	ExecStart=$DOTNET_PATH $PRJCT_DIR/$PRJCT_NAME
	Restart=always
	# Restart service after 10 seconds if the dotnet service crashes:
	RestartSec=10
	KillSignal=SIGINT
	SyslogIdentifier=dotnet-example
	User=$USRNAME
	Environment=ASPNETCORE_ENVIRONMENT=Production 

	[Install]
	WantedBy=multi-user.target" | sshpass -e ssh $USRNAME@$SRVR_IP "cat > /home/$USRNAME/.service"
	echo
	echo  "To copy service file to '/etc/systemd/system', and performing systemctl commands, You need to be a [sudoer]..."
	sshpass -e ssh -t $USRNAME@$SRVR_IP "sudo mv /home/$USRNAME/.service /etc/systemd/system/$PRJCT_NAME.service; sudo systemctl daemon-reload; \
	sudo systemctl stop $PRJCT_NAME.service; sleep 3; sudo systemctl start $PRJCT_NAME.service"
	if [ $? != 0 ] ; then echo "Error while moving and starting service." >&2 ; exit 1 ;else echo "Done!"; fi
}




###############################FLOW CONTROL#################

opt='-'

# options=`getopt -o i:p:s:u: --long build::,deploy::,install-requirements::,send:: -- "$@"`
# if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

# echo "$options"

# eval set -- "$options"

# while true; do
# 	case $1 in
# 		-i|--input-file)
# 			IF="$2"
# 			PRJCT_NAME=`basename $(readlink -f $IF)`
# 			echo $IF
# 			shift
# 			shift;;
# 		-p)
# 			PRJCT_DIR="$2"
# 			shift
# 			shift;;
# 		-s)
# 			SRVR_IP="$2"
# 			shift
# 			shift;;
# 		-u)
# 			USRNAME="$2"
# 			shift
# 			shift;;

# ############################OPERATIONS####################	
# 		--build)
# 			echo "build"
# 			opt='b'
# 			shift;;
# 		--deploy)
# 			echo "deploy"
# 			opt='d'
# 			shift;;
# 		--install-requirements)
# 			opt='r'
# 			shift;;
# 		--send)	opt='s'
# 			shift;;

# 		--) echo "end"; shift ; break ;;
	    	
		
		
		
# 		/?)
# 	      		echo "Invalid option: -$2"
# 			show_help
# 	      		exit 1;;
# 	  	:)
# 	     		echo "Option -$2 requires an argument."
# 			show_help     			
# 			exit 1;;
# 		* ) if [ -z "$1" ]; then break;fi;;

# 	esac
# break
# done







TEMP=`getopt -o i:p:s:u:h --long build,deploy,install-dotnet,send,help -n 'publishscript' -- "$@"`

if [ $? != 0 ] ; then echo "getopt faced an error. Terminating..." >&2 ; exit 1 ; fi

eval set -- "$TEMP"

while true; do
  case "$1" in
    -i | --input ) IF="$2"; PRJCT_NAME=`basename $(readlink -f "$IF")`; shift 2;;
    -s | --server ) SRVR_IP="$2"; shift 2;;
    -u | --user ) USRNAME="$2"; shift 2 ;;
	-p | --project-directory ) PRJCT_DIR="$2"; shift 2;;
	-h | --help ) opt='h'; shift;;    
	--build ) opt='b'; shift ;;
    --install-dotnet ) opt='r'; shift;;
    --send ) opt='s'; shift;;
	--deploy ) opt='d'; shift;;    
	-- ) shift; break ;;
    * ) break ;;
  esac
done






##################OPERATIONS HADLER################

if [ $opt == 'b' ]; then

	
	if [[ -d $IF ]]; then
		build
	else
		echo 'Build error, you need to specify input(project) directory'
		show_help
		exit 1
	fi


elif [ $opt == 's' ]; then
	
	if [[ -d $IF && -n $PRJCT_DIR && -n $SRVR_IP && -n $USRNAME ]]; then
		run		
		send
	else
		echo 'Invalid arguments! Please take a look at help:'
		show_help
		exit 1
	fi




elif [ $opt == 'd' ]; then


	if [[ -n $PRJCT_DIR && -n $SRVR_IP && -n $USRNAME ]]; then
		run
		service_dispatch
	else
		echo 'You need to specify project directory, server address and username.'
		echo 'Take a look at help:'
		show_help
	fi


elif [ $opt == 'r' ]; then
	install_dotnet


elif [ $opt == 'h' ]; then
	show_help

else
	echo "You haven't specified an operation mode --<build deploy send install-dotnet> for this script."
	show_help
	exit 1
fi


###################FOR FURTHER SECURITY#################
#export SSHPASS=''
#apparently there was no need for this, becuase 'export' only makes a variable available to sub-shells, not parent shells!! :))




#https://medium.com/faun/net-core-projects-ci-cd-with-jenkins-ubuntu-and-nginx-642aa9d272c9
