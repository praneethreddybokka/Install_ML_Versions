#URL=http://jenkins1.marklogic.com/view/Server%20Builds/job/ServerBuild_xdmp-trunk_build_linux64/lastSuccessfulBuild/artifact/xdmp/src/
echo "----->Initiating Marklogic RPM download"

if [[ "$1" == "8" ]]; then
	URL=http://jenkins1.marklogic.com/view/Server%20Builds/job/ServerBuild_b8_0_linux64/lastSuccessfulBuild/artifact/xdmp/src/
	p1=2000
	p2=2001
elif [ "$1" == "9" ]; then
        URL=http://jenkins1.marklogic.com/view/Server%20Builds/job/ServerBuild_b90_build_linux64/lastSuccessfulBuild/artifact/xdmp/src/
	p1=3000
	p2=3001
else [[ "$1" == "10" ]]
        URL=http://jenkins1.marklogic.com/view/Server%20Builds/job/ServerBuild_xdmp-trunk_build_linux64/lastSuccessfulBuild/artifact/xdmp/src/
	p1=4000
	p2=4001
fi

package=MarkLogic-$1.0-`date +%Y%m%d`.x86_64.rpm

if [ -f ./MarkLogic.rpm ]  ; then
	echo "Older RPM exist. Deleting them now..."
	rm -rf ./MarkLogic.rpm
else 
	echo -e "\n----->No previous RPM exist"
fi




wget --auth-no-challenge --no-check-certificate  ${URL}/${package} --directory-prefix= .

if [ ! -f "./$package" ]
        then
         echo "ERROR : Package file download failed"
         echo "--- Exiting the script ---"
         exit -1
        fi
        echo -e "\nPackage file downloaded : $PWD/$package"
	mv $PWD/$package ./MarkLogic.rpm
	chmod -R 777 ./MarkLogic.rpm

echo "----->Completed RPM download. Proceeding with Docker File Creation"
#sed -i -e 's/MarkLogic*/'$package'/g' ./Dockerfile
echo -e "\n----->Completed Docker File creation. Proceeding with Image creation"



echo -e "\n\n----->Initiating Docker Images creation"
echo "Running Pre-reqs"
echo -e "\nPre-req1: Checking if Docker is installed on Host"

if [[ $(which docker) && $(sudo docker --version) ]]; then
	echo "[SUCCESS]: Docker is installed"
else
	echo "[FAIL]: Docker is not installed on this Host"
	exit 0
fi

echo -e "\nPre-req2: Checking existence of Dockerfile"
[ -f ./Dockerfile ] && echo "[SUCCESS]: Docker File exists at $PWD" || echo "File does not exist Hence exiting" exit 0


echo -e  "\nPre-req3: Checking existence of Marklogic RPM"
if [ -f "./MarkLogic.rpm" ]; then
	echo "[SUCCESS]: Marklogic RPM Exists at $pwd/MarkLogic.rpm"
else 
	echo "File does not Exist"
	exit 0 
fi

echo -e "Completed Pre-req's... Proceeding with Image Creation....\n"
#Image_name="Marklogic-$1:`date +%H:%M:%S`"
Image_name="marklogic-$1"
echo "Building docker Image:$Image_name"

before_image_status=$(sudo docker images| grep $Image_name | wc -l)
if [ $before_image_status  == "1" ] ; then\
	echo "Status for before_image_status:$before_image_status"
	echo "This Docker Image was already installed. So removing previous image:$before_image_status"
	`sudo docker rmi $Image_name`
else 
	echo "Status for before_image_status:$before_image_status"
	echo "No Image with name $Image_name. So proceeding with creating a new one"
fi



Image_output=$(sudo docker build -t $Image_name .)

echo "----->Image creation completed from docker command"

echo "----->Verifying that the image is created"

image_status=$(sudo docker images| grep $Image_name | wc -l)

if [ $image_status  == "1" ] ; then
	echo "$image_status"
	echo "Docker Image is created"
else
	echo "$image_status"
	echo "Failure while creating Docker Image"
	echo -e "Output while creating docker Image:\n $Image_output"
	exit 1;
fi

container_name="$Image_name-container"
echo -e "\n----->Creating containers for the images created:$container_name"
containter_status=$(sudo docker ps -a | grep $container_name | wc -l)

if [ "$containter_status" == "1" ] ; then
	echo "Stopping and removing the previous container"
	sudo docker stop $container_name
	sudo docker rm $container_name
fi


Container_output=$(sudo docker run -d --name=$container_name -p $p1:8000 -p $p2:8001 $Image_name)
if [ "$?" == "0" ] ; then
        echo "Container is created"
else
        echo "Failure while creating containers"
        echo "Output while creating Containers: $Container_output"
	exit 1;
fi

echo -e "\n Containter is created with the ML server installed"
echo -e  "\n Proceeding with ML initializing"
[$(sudo docker exec -it  $container_name /bin/sh -c "mladmin start;init-marklogic")] && echo -e "\n ML server is initialized and ready to use" || echo -e "\n ML initialization failed"
