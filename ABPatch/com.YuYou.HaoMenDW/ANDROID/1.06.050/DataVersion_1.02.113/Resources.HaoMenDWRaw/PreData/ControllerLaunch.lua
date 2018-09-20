ControllerLaunch = {}

function ControllerLaunch:new(o)
	o = o or {}  
    setmetatable(o,self)  
    self.__index = self		

    if(self.Instance==nil)
	then
		self.ControllerName = "Launch"						
		self.LaunchConfigLoader = nil				
		self.CanCheckLoadDataDone = false
		self.PreViewLoadDone = false
		self.Instance = o
	end

    return self.Instance  
end

function ControllerLaunch.onCreate()
	print("ControllerLaunch:onCreate")		      
	local casinos_context = CS.Casinos.CasinosContext.Instance
    local predata_persistentdata_path = casinos_context.PathMgr:combinePersistentDataPath(
            CS.Casinos.CasinosContext.Instance.UiMgr.ResourcesRowPathRoot .. "PreData/")    	
	casinos_context.CasinosLua:doString("PreViewMgr")
	casinos_context:setPreViewMgr()
	local launch = ControllerLaunch:new(nil)	
	launch.PreViewMgr = PreViewMgr:new(nil)
	
	local ui_name_loading = "PreLoading"
	local ui_path_loading = predata_persistentdata_path .. ui_name_loading .. "/" .. string.lower(ui_name_loading) .. ".ab"	
	local ui_name_msgbox = "PreMsgBox"
	local ui_path_msgbox = predata_persistentdata_path .. ui_name_msgbox .. "/" .. string.lower(ui_name_msgbox) .. ".ab"	
	casinos_context:luaAsyncLoadLocalUiBundle(
	function()
		launch:_loadABDone()
	end
	,ui_path_loading,ui_path_msgbox)	
end

function ControllerLaunch:onDestroy()
end

function ControllerLaunch.onUpdate(tm)	
	local launch = ControllerLaunch:new(nil)	
	if (launch.LaunchConfigLoader ~= nil)
    then
        launch.LaunchConfigLoader:update(tm)
    end

    if (launch.CanCheckLoadDataDone)
    then        
        local casinos_context = CS.Casinos.CasinosContext.Instance
        local load_datadone = casinos_context.LoadDataDone
        if (load_datadone==true and launch.PreViewLoadDone == true)
        then
            launch.CanCheckLoadDataDone = false                     
            casinos_context:InitUCenterSDK(casinos_context.UserConfig.Current.UCenterDomain, casinos_context.Config.AppId)
			
            local view_preloading = launch.PreViewMgr.createView("PreLoading")			
			view_preloading.setTip("正在玩命加载美术资源，稍后即可进入游戏...")            			
            casinos_context.Listener:OnInitializeBegin(casinos_context.EbDataMgr,ControllerLaunch._initializeDone)
        end
    end
end

function ControllerLaunch:onHandleEv(ev)	
end

function ControllerLaunch:getModle()
end

function ControllerLaunch:copyStreamingAssetsToPersistentDataPath()
   local controller_launch = ControllerLaunch:new(nil)	
   local view_preloading = controller_launch.PreViewMgr.createView("PreLoading")
   view_preloading.setTip("首次进入游戏，解压资源，该过程不产生任何流量")

   local launch = CS.Casinos.CasinosContext.Instance.Launch
   if (launch.ParseStreamingAssetsDataInfo ~= nil)
   then
        CS.Casinos.CasinosContext.Instance.CopyStreamingAssetsToPersistentDataPath:startCopy(launch.ParseStreamingAssetsDataInfo.ListData,
             function(current_index, total_count)
				controller_launch:_firstCopyStreamingAssetsDataPro(current_index, total_count)
			 end,
			 ControllerLaunch._firstCopyStreamingAssetsDataDown)
   end
end

function ControllerLaunch:_loadABDone()		
    local view_preloading = self.PreViewMgr.createView("PreLoading")
	view_preloading.setTip("正在努力加载配置，请耐心等待...")
    self.PreViewLoadDone = true   
    self.LaunchConfigLoader = CS.Casinos.LaunchConfigLoader()
    local maic_path = CS.Casinos.CasinosContext.Instance:GetMainCPath()
    self.LaunchConfigLoader:loadConfig(maic_path, 
	function(config)
		self:_loadConfigDone(config)	
	end
	)
end
        
function ControllerLaunch:_firstCopyStreamingAssetsDataPro(current_index, total_count)
   -- local launch = ControllerLaunch:new(nil)
   local pro = current_index / total_count
   local view_preloading = self.PreViewMgr.createView("PreLoading")
   view_preloading.setLoadingProgress(pro * 100) 
end
        
function ControllerLaunch._firstCopyStreamingAssetsDataDown()
	local launch = CS.Casinos.CasinosContext.Instance.Launch
    launch.ParseStreamingAssetsDataInfo:writeStreamingAssetsDataFileList2Persistent()
    CS.UnityEngine.PlayerPrefs.SetString(CS.Casinos.CasinosContext.LocalDataVersionKey, 
	        CS.Casinos.CasinosContext.Instance.Config.InitDataVersion)
    launch.ParseStreamingAssetsDataInfo = nil
end
        
function ControllerLaunch:_loadConfigDone(config)	
	-- local launch = ControllerLaunch:new(nil)	
    local casinos_context = CS.Casinos.CasinosContext.Instance
    casinos_context.CasinosLua:addLuaFile(casinos_context.Config.ConfigName, config)
    casinos_context.CasinosLua:doMainCLua(casinos_context.Config.ConfigName)
    casinos_context.MainCLua = MainC
    self.CanCheckLoadDataDone = true
end        

function ControllerLaunch._initializeDone()
   CS.Casinos.CasinosContext.Instance.Listener:OnInitializeEnd()
   CS.Casinos.CasinosContext.Instance:createController("Login")
end