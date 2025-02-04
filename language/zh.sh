#!/usr/bin/env bash
# Chinese
# native: 中文

mycodeInterfaceQuery="请选择你要调用的网卡设备"
mycodeAllocatingInterfaceNotice="分配保留接口 $CGrn\"\$interfaceIdentifier\"."
mycodeDeallocatingInterfaceNotice="释放保留接口 $CGrn\"\$interfaceIdentifier\"."
mycodeInterfaceAllocatedNotice="${CGrn}接口分配成功!"
mycodeInterfaceAllocationFailedError="${CRed}接口保留失败!"
mycodeReidentifyingInterface="重命名接口."
mycodeUnblockingWINotice="解除所有占用无线接口设备的进程..."
#mycodeFindingExtraWINotice="查询USB外部网卡接口设备..."
mycodeRemovingExtraWINotice="正在移除USB外部网卡接口设备..."
mycodeFindingWINotice="寻找可用的USB外部网卡接口设备..."
mycodeSelectedBusyWIError="选择的USB外部网卡接口设备正在被调用!"
mycodeSelectedBusyWITip="这通常是由使用所选接口的网络管理员引起的。我们建议您$CGrn 正常停止网络管理器$CClr 或将其配置为忽略所选接口或者在流量之前运行 \"export mycodeWIKillProcesses=1\" before mycode to kill it but we suggest you$CRed avoid using the killer flag${CClr}."
mycodeGatheringWIInfoNotice="采集接口信息..."
mycodeUnknownWIDriverError="找不到网卡设备"
mycodeUnloadingWIDriverNotice="等待接口 \"\$interface\" 卸载..."
mycodeLoadingWIDriverNotice="等待接口 \"\$interface\" 加载..."
mycodeFindingConflictingProcessesNotice="自动查询干扰mycode运行的进程..."
mycodeKillingConflictingProcessesNotice="结束干扰mycode运行的进程..."
mycodePhysicalWIDeviceUnknownError="${CRed}Unable to determine interface's physical device!"
mycodeStartingWIMonitorNotice="启动监听模式..."
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
mycodeTargetSearchingInterfaceQuery="选择用于目标搜索的无线接口."
mycodeTargetTrackerInterfaceQuery="为目标跟踪选择无线接口."
mycodeTargetTrackerInterfaceQueryTip="${CSYel}可能需要选择专用接口.$CClr"
mycodeTargetTrackerInterfaceQueryTip2="${CBRed}如果您不确定，请选择\"${CBYel}跳过${CBRed}\"!$CClr"
mycodeIncompleteTargettingInfoNotice="缺少ESSID，BSSID或频道信息!"
mycodeTargettingAccessPointAboveNotice="mycode正在瞄准上面的接入点."
mycodeContinueWithTargetQuery="继续这个目标?"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
mycodeStartingScannerNotice="启动扫描, 请稍等..."
mycodeStartingScannerTip="目标AP出现后,按 Ctrl+C 关闭mycode扫描"
mycodePreparingScannerResultsNotice="综合扫描的结果获取中,请稍等..."
mycodeScannerFailedNotice="你的无线网卡好像不支持 (没有发现APs)"
mycodeScannerDetectedNothingNotice="没有发现访问点, 请返回重试..."
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
mycodeHashFileDoesNotExistError="Hash文件不存在!"
mycodeHashInvalidError="${CRed}错误$CClr, 无效的Hash文件!"
mycodeHashValidNotice="${CGrn}成功$CClr, Hash效验完成!"
mycodePathToHandshakeFileQuery="指定捕获到的握手包存放的路径 $CClr(例如: /.../dump-01.cap)"
mycodePathToHandshakeFileReturnTip="要返回，请将hash路径留空"
mycodeAbsolutePathInfo="捕获到握手包后存放的绝对路径"
mycodeEmptyOrNonExistentHashError="${CRed}错误$CClr, 路径指向不存在或空的hash文件"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
mycodeScannerChannelQuery="选择要扫描的信道"
mycodeScannerChannelOptionAll="扫描所有信道 "
mycodeScannerChannelOptionSpecific="扫描指定信道"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
mycodeScannerChannelSingleTip="单一信道"
mycodeScannerChannelMiltipleTip="多个信道"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
mycodeScannerHeader="mycode 扫描仪"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
mycodeHashSourceQuery="选择一种方式来检查握手包获取状态"
mycodeHashSourcePathOption="检测文件的路径"
mycodeHashSourceRescanOption="握手包目录(重新扫描)"
mycodeFoundHashNotice="发现目标热点的Hash文件."
mycodeUseFoundHashQuery="你想要使用这个文件吗?"
mycodeUseFoundHashOption="使用抓取到的hash文件"
mycodeSpecifyHashPathOption="指定hash路径"
mycodeHashVerificationMethodQuery="选择Hash的验证方法"
mycodeHashVerificationMethodPyritOption="pyrit 验证"
mycodeHashVerificationMethodAircrackOption="aircrack-ng 验证 (${CYel}不推荐$CClr)"
mycodeHashVerificationMethodCowpattyOption="cowpatty 验证 (${CGrn}推荐用这个$CClr)"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
mycodeAttackQuery="请选择一个攻击方式"
mycodeAttackInProgressNotice="${CCyn}\$mycodeAttack$CClr 正在进行攻击......"
mycodeSelectAnotherAttackOption="选择启动攻击方式"
mycodeAttackResumeQuery="此攻击已经配置完毕"
mycodeAttackRestoreOption="恢复攻击"
mycodeAttackResetOption="重置攻击"
mycodeAttackRestartOption="重启"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
mycodeGeneralSkipOption="${CYel}跳过"
mycodeGeneralBackOption="${CRed}返回"
mycodeGeneralExitOption="${CRed}退出"
mycodeGeneralRepeatOption="${CRed}重试"
mycodeGeneralNotFoundError="未找到"
mycodeGeneralXTermFailureError="${CRed}无法启动xterm会话（可能是错误配置）"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
mycodeCleanupAndClosingNotice="清理进程并退出"
mycodeKillingProcessNotice="Killing ${CGry}\$targetID$CClr"
mycodeRestoringPackageManagerNotice="恢复 ${CCyn}\$PackageManagerCLT$CClr"
mycodeDisablingMonitorNotice="关闭监听模式界面"
mycodeDisablingExtraInterfacesNotice="关闭USB外部网卡接口"
mycodeDisablingPacketForwardingNotice="关闭 ${CGry}转发数据包"
mycodeDisablingCleaningIPTablesNotice="清理 ${CGry}iptables"
mycodeRestoringTputNotice="恢复 ${CGry}tput"
mycodeDeletingFilesNotice="删除 ${CGry}文件"
mycodeRestartingNetworkManagerNotice="重启 ${CGry}网络管理"
mycodeCleanupSuccessNotice="所有进程清理完成!"
mycodeThanksSupportersNotice="再次感谢使用mycode!"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

# FLUXSCRIPT END
