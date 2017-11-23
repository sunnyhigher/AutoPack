#================= Xcode 自动打包脚本 ===============#
# $sh ....../AutoPack.sh (路径)
#
# 使用说明
# 在终端中输入 sh + 脚本路径
# 然后根据提示进行配置
# 如果不使用蒲公英，就不需要配置蒲公英信息
#
# LEPgyerApiKey 可在Info.plist中配置蒲公英apiKey
# LEPgyerUKey 可在Info.plist中配置蒲公英ukey
# LEPgyerPassword 可在Info.plist中配置蒲公英password
#!/bin/sh

result=''
uploadToPgyer()
{
	echo "蒲公英上传配置：" 
	echo "ipa路径:  " $1
	echo "UserKey: " $2
	echo "ApiKey:  " $3
	echo "Password:" $pgyerPassword
    echo "updateDescription:" $pgyerUpdateDescription
	result=$(curl -F "file=@$1" -F "uKey=$2" -F "_api_key=$3" -F "updateDescription=$pgyerUpdateDescription" -F "installType=2" -F "password=$pgyerPassword" 'https://qiniu-storage.pgyer.com/apiv1/app/upload')
}

tempPath="$(pwd)"
pathConfig="${tempPath}/打包配置信息/pkgtopgy_path.config"
pgyConfig="${tempPath}/打包配置信息/pgyer.config"
#判定并创建历史打包目录配置文件

if [ ! -f ${tempPath}/打包配置信息 ]; then
    mkdir ${tempPath}/打包配置信息
fi

if [ ! -f $pathConfig ] ; then 
	touch $pathConfig
fi
#判定并创建蒲公英配置文件
if [ ! -f $pgyConfig ] ; then 
	touch $pgyConfig
fi
#历史打包目录条数
lines=`sed -n '$=' ${pathConfig}` 

if [[ $lines == '' ]]; then
	lines=0
fi  

echo "请选择你需要打包的目录："
for i in `cat ${pathConfig} `
do
	echo  $((++no)) ":" $i
done
echo  $((++no)) ":" "${tempPath}"
	 
read -p "请选择打包目录(若无合适的目录请直接回车)：" pathselection
if [[ $pathselection >0 ]] && [[ $pathselection -le `expr $lines+1` ]] ; then
	if [[ $pathselection -le $lines ]] ; then
		project_path=`sed -n ${pathselection}p ${pathConfig}` 
	else 
		echo "已选目录：${tempPath}" 
		read -p "请确认上述已选目录：(y/n)" checkPath
		if [[ $checkPath = "y" ]] ; then
			project_path=$tempPath
		fi
	fi 
else
	echo "未找到合适的路径"
fi	

if [[ $project_path == '' ]]; then 
	read -p "请手动输入打包工程的绝对路径:" inputPath
	project_path=$inputPath
	if [[ $project_path != '' ]]; then 
		echo $project_path >> ${pathConfig}
		cat ${pathConfig}
	fi
fi
#

if [[ -d "$project_path" ]]; then
	echo "当前路径为：" $project_path
else
	echo "路径："$project_path
	echo "当前路径有误，已终止!!!\n"
	exit
fi
SECONDS=0
#取当前时间字符串添加到文件结尾
now=$(date +"%m_%d_%H_%M")
#工程名
cd ${project_path}
project=$(ls | grep xcodeproj | awk -F.xcodeproj '{print $1}')
#指定项目地址
workspace_path="$project_path/${project}.xcworkspace"
if [[ ! -d "$workspace_path" ]]; then
	echo "路径："$workspace_path
	echo "未找到.xcworkspace文件，已终止!!!"
	exit
fi
#工程配置文件路径
echo "检查蒲公英设置"
project_infoplist_path=${project_path}/${project}/Info.plist
pgyerApiKey=''
pgyerUKey=''
pgyerPassword=''
pgyerApiKey=$(/usr/libexec/PlistBuddy -c "print LEPgyerApiKey" ${project_infoplist_path})
pgyerUKey=$(/usr/libexec/PlistBuddy -c "print LEPgyerUKey" ${project_infoplist_path})
pgyerPassword=$(/usr/libexec/PlistBuddy -c "print LEPgyerPassword" ${project_infoplist_path})
if [[ $pgyerUKey = '' ]] || [[ $pgyerApiKey = '' ]]; then
	i=0
	for line in `cat ${pgyConfig}`;
	do 
		pgy_line_array[i++]=$line
	done
	
	lines=${#pgy_line_array[@]}  
	if [[ $lines > 0 ]]; then 
		echo "发现历史蒲公英配置："
		no=0
		for line in `cat ${pgyConfig}`;
			do    
			api=`echo ${line}|awk -F ',' '{print $1}'`
			user=`echo ${line}|awk -F ',' '{print $2}'`
			psw=`echo ${line}|awk -F ',' '{print $3}'`
			echo "    PgyApiKey: ${api} PgyUserKey: ${user} PgyerPassword: ${psw}"  
		done
		read -p "请选择蒲公英配置(若无合适的配置请直接回车)：" pgyindex
		if [[ $pgyindex >0 ]] && [[ $pgyindex -le `expr $lines+1` ]] ; then
			index=$(($pgyindex-1)) 
			str=${pgy_line_array[$index]}  
			pgyerApiKey=`echo ${str}|awk -F ',' '{print $1}'`
			pgyerUKey=`echo ${str}|awk -F ',' '{print $2}'`
			pgyerPassword=`echo ${str}|awk -F ',' '{print $3}'`
			echo "PgyApiKey: ${pgyerApiKey} PgyUserKey: ${pgyerUKey} PgyerPassword: ${pgyerPassword}" 
		fi
	fi
		
	isCheckPgy=0
	while [ $isCheckPgy == 0 ]
	do 
		if [[ $pgyerUKey = '' ]] || [[ $pgyerApiKey = '' ]]; then
			read -p "发现尚未配置蒲公英上传的apiKey及ukey,是否配置?(y/n)" checkConfig
			if [[ $checkConfig = "y" ]] ; then
				read -p "请输入蒲公英上传的apiKey:" apikey
				pgyerApiKey=$apikey
				read -p "请输入蒲公英上传的ukey:" ukey
				pgyerUKey=$ukey
				if [[ $pgyerUKey != '' ]] || [[ $pgyerApiKey != '' ]]; then
				
					if [[ $pgyerPassword = '' ]]; then
						echo '发现蒲公英下载密码，未在工程项目的Info.plist配置，配置名称为LEPgyerPassword'
						read -p "是否现在配置?(y/n)" checkpsw
						if [[ $checkpsw = "y" ]] ; then 
							read -p "蒲公英下载密码：" inputpsw
							pgyerPassword=$inputpsw
						fi
					fi
					isCheckPgy=1
				fi 
			else
				isCheckPgy=1
			fi
		else
			isCheckPgy=1
		fi
	done 
fi 
#指定项目的scheme名称
scheme=$project

#指定要打包的配置名
configuration="Release"

#指定打包所使用的输出方式，目前支持app-store, package, ad-hoc, enterprise, development, 和developer-id，即xcodebuild的method参数
export_method='enterprise'
#export_method='app-store'

#指定输出路径
mkdir "${HOME}/Desktop/${project}_${now}"

output_path="${HOME}/Desktop/${project}_${now}"

#指定输出归档文件地址
archive_path="$output_path/${project}_${now}.xcarchive"

#指定输出ipa地址
ipa_path="$output_path/$scheme.ipa"

#指定输出ipa名称
ipa_name="${project}_${now}.ipa"

#获取执行命令时的commit message
commit_msg="$1"

#plist文件所在路径
# plist 可选参数 app-store, package, ad-hoc, enterprise, development, developer-id
exportOptionsPlistPath="./${scheme}/DevelopmentExportOptionsPlist.plist"

#输出设定的变量值
#echo "=================配置信息==============="
#echo "begin package at ${now}"
#echo "workspace path: ${workspace_path}"
#echo "archive path: ${archive_path}"
#echo "ipa path: ${ipa_path}"
#echo "export method: ${export_method}"
#echo "commit msg: $1"
#pod update
#pod update --no-repo-update

echo '*** 正在 清理工程 ***'
xcodebuild \
clean -configuration ${workspace_path} -quiet  || exit
echo '*** 清理完成 ***'

echo '*** 正在 编译工程 For '${configuration}
xcodebuild \
archive -workspace ${scheme}.xcworkspace \
-scheme ${scheme} \
-configuration ${configuration} \
-archivePath build/${scheme}.xcarchive -quiet  || exit
echo '*** 编译完成 ***'

echo '*** 正在 打包 ***'
xcodebuild -exportArchive -archivePath build/${scheme}.xcarchive \
-configuration ${configuration} \
-exportPath ${output_path} \
-exportOptionsPlist ${exportOptionsPlistPath} \
-quiet || exit

# 删除build包
if [[ -d build ]]; then
    rm -rf build -r
fi

# 打包完成
if [ -e $output_path/$scheme.ipa ]; then
    echo "*** .ipa文件已导出 ***"
else
    echo "*** 创建.ipa文件失败 ***"
fi
    #输出总用时
    echo '*** 打包完成 共用时：${SECONDS}s ***'

# 上传蒲公英
if [[ $pgyerUKey = '' ]] || [[ $pgyerApiKey = '' ]]; then
	echo "因未设置蒲公英上传配置，已取消上传。您可以在工程项目的Info.plist文件中配置LEPgyerApiKey（蒲公英apiKey）、LEPgyerUKey（蒲公英userKey）及LEPgyerPassword（密码）。"
else 
	if [[ -f "$ipa_path" ]]; then
        echo '*** 准备上传蒲公英 ***'
        read -p "请输入软件更新描述：" releaseNotes
        pgyerUpdateDescription=$releaseNotes

		uploadToPgyer $ipa_path $pgyerUKey $pgyerApiKey $pgyerPassword $pgyerUpdateDescription
		while [[ $result == '' ]]
		do
			read -p "上传失败，是否重新上传到蒲公英?(y/n)" reUploadToPgyer
			if [[ $reUploadToPgyer = "y" ]] ; then
				uploadToPgyer $ipa_path $pgyerUKey $pgyerApiKey $pgyerPassword $pgyerUpdateDescription
			else
				echo "本次打包完成，ipa位置: ${ipa_path}" 
				exit
			fi
		done
		if [[ $result != '' ]]; then
			echo "蒲公英上传成功"
		fi 
	fi
fi
echo "本次打包完成"
exit
