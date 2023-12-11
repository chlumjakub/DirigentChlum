BasePath=../..;source $BasePath/Commons.sh

DAS="AVs/PhotronMiniUX100-a/Radial"


DeviceList="AVs/PhotronMiniUX100-a/Radial AVs/PhotronMiniUX100-b/Vertical ITs/PhotronCamerasPC/FastCameras"



function OpenSession()
{
    #mount /mnt/share/PhotronCamerasPC
    sleep 3
    SetupCams
}

function CloseSession()
{
    #umount /mnt/share/PhotronCamerasPC
    sleep 3
}


function Arming()
{
    echo OK;    
}

function GetReadyTheDischarge ()
{
    echo OK;
    #GeneralTableUpdateAtDischargeBeginning diagnostics.$diag_id #@Commons.sh
}




function PostDischargeAnalysis
{

    ln -s $BasePath/Devices/AVs/PhotronMiniUX100-a/Radial/ DAS_raw_data_dir
    #convert -resize $icon_size SpeedCamera.png analysis.jpg
    timeout=20
    while ! test -s /mnt/share/PhotronCamerasPC/AVI/CamRad.avi;
    do
        if [ "$timeout" == 0 ]; then
        LogItColor 1 "ERROR: Timeout while waiting for the file from $ThisDev"
        exit 1
    fi
    sleep 1
    echo $timeout s to wait for $ThisDev files .. pokud čeká dlouho, je OK mount PC?
    ((timeout--))
    done

    while ! test -s /mnt/share/PhotronCamerasPC/AVI/CamVert.avi;
    do
        if [ "$timeout" == 0 ]; then
        LogItColor 1 "ERROR: Timeout while waiting for the file from $ThisDev"
        exit 1
    fi
    sleep 1
    echo $timeout s to wait for $ThisDev files
    ((timeout--))
    done

    # Test if files are not older than specified time limit 
    tdiff=$(( `date +%s` - `stat -c %Y /mnt/share/PhotronCamerasPC/AVI/CamRad.avi` )); 
    if  [ $tdiff -ge 300 ] ;
    then  
        LogitColor 1 'Problem with camera files ... too old'; 
        Speaker Problems/there-is-a-problem-with-the-camera-files
        return
    fi

    
    sleep 10
    mkdir Camera_Radial
    mkdir Camera_Vertical
    #cp /mnt/share/`ls -1tr /mnt/share/|grep C002|tail -1`/*.* Camera_Radial/
    cp /mnt/share/PhotronCamerasPC/AVI/CamRad.avi Camera_Radial/Data.avi
    cp /mnt/share/PhotronCamerasPC/AVI/CamVert.avi Camera_Vertical/Data.avi
    cp /mnt/share/PhotronCamerasPC/OutputCamsConfig.json .
    cp /mnt/share/PhotronCamerasPC/CamsConfig.json .
    
    
    
    sed -i "s/shot_no=0/shot_no\ =\ `cat $SHMS/shot_no`/g" VisTomography.ipynb 
    jupyter-nbconvert --ExecutePreprocessor.timeout=-1 --to html --execute VisTomography.ipynb --output analysis.html > >(tee -a jup-nb_stdout.log) 2> >(tee -a jup-nb_stderr.log >&2)
    
    
    convert -resize $icon_size icon-fig.png graph.png
    convert -resize $icon_size ScreenShotAll.png rawdata.jpg 
    cp ScreenShotAll.png rawdata.jpg $SHM0/Devices/AVs/PhotronMiniUX100-a/
    
    GenerateDiagWWWs $instrument $setup $DAS 
}


function SetupCams()
{
echo '[
  {
    "BMPdataFolderPath": "BMP\\Vertical\\",
    "SettingsMode": "SetAll",
    "TriggerMode": "TrigStart",
    "framesToSave": 3072,
    "height": 24,
    "input1": "TrigPos",
    "input2": "SyncPos",
    "ipAddr": "192.168.2.12",
    "name": "Camera Vertical",
    "recordRate": 102400,
    "shotDurToSave": 30,
    "variableChannel": 1,
    "videoFileName": "AVI\\CamVert.avi",
    "width": 1280
  },
  {
    "BMPdataFolderPath": "BMP\\Radial\\",
    "SettingsMode": "SetAll",
    "TriggerMode": "TrigStart",
    "framesToSave": 3072,
    "height": 24,
    "input1": "TrigPos",
    "input2": "SyncPos",
    "ipAddr": "192.168.2.13",
    "name": "Camera Radial",
    "recordRate": 102400,
    "shotDurToSave": 30,
    "variableChannel": 1,
    "videoFileName": "AVI\\CamRad.avi",
    "width": 1280
  }
]' > /mnt/share/PhotronCamerasPC/CamsConfig.json
}


