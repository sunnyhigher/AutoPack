# AutoPack
iOS 自动打包工具
###使用方法
在终端中输入`sh` + `脚本所在路径`
然后根据提示进行配置
如果不需要蒲公英，就不需要配置蒲公英信息

> LEPgyerApiKey 可在Info.plist中配置蒲公英apiKey
> LEPgyerUKey 可在Info.plist中配置蒲公英ukey
> LEPgyerPassword 可在Info.plist中配置蒲公英password

在`DevelopmentExportOptionsPlist.plist`中配置打包所使用的输出方式，目前支持`app-store`, `package`, `ad-hoc`, `enterprise`, `development`, 和`developer-id`
###注意事项
* 此脚本自动打包后，上传至蒲公英，如需其它，自行修改脚本。
* 在项目 info.plist 中设置`LEPgyerApiKey`与`LEPgyerUKey`设置

