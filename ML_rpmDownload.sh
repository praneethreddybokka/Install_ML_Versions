branch=b9_0
[ "$1" = "-y" ] && run_defaults=true || run_defaults=''

#TODO:Parameterize above variables so it works for all platforms.
# Please do not modify below this line
URL=https://jenkins.marklogic.com/view/Server%20Builds/job/ServerBuild_xdmp-trunk_build_linux64/lastSuccessfulBuild/artifact/xdmp/src/
package=MarkLogic-10.0-`date +%Y%m%d`.x86_64.rpm


        rm -f /tmp/${package}*
        echo "Please enter your jenkins.marklogic.com username:"
        read user
        echo "Please enter your jenkins.marklogic.com password for $user:"
        wget --auth-no-challenge  --user=${user} --ask-password --no-check-certificate  ${URL}/${package} --directory-prefix=/tmp
        if [ ! -f "/tmp/$package" ]
        then
         echo "ERROR : Package file download failed"
         echo "--- Exiting the script ---"
         exit -1
        fi
        chmod 777 /tmp/$package
        echo -e "\nPackage file downloaded : /tmp/$package"
        echo -e "Build Timestamp: " `stat  /tmp/$package | grep Modify | cut -d: -f2,3,4,5,6,7,8`
        echo -e "current Timestamp: " `date`

if [ ! -f ./scripts/tests/zzDummyTest.xml ]
then
        echo -e "\n***Please run from QA_HOME if you want the downloaded package to be installed"
        exit 1
else
        echo "==============================================================="
        echo -e "\nWARNING:Package $package will be installed. This will wipe out your data directory, scripts/results etc..."
        [ $run_defaults ] || read -p "To Quit: Hit ctrl+c or hit return (enter) to continue. "
fi
make clean
svn update
make
make tests tname=foo pkg=/tmp/$package clean=yes
echo -e "\n-------- End of script -----------"

