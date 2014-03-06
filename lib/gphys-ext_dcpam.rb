#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 
# 
=begin
== GPhys Class

---glmean  
    全球平均

    RETURN VALUE
    * GPhys

    NOTE

---latmean  
    緯度平均

    RETURN VALUE
    * GPhys

    NOTE

---variance(axis=0,ave=nil) 
    分散

    ARGUMNETS    
    * index of axis
    * average (optional)

    RETURN VALUE
    * GPhys <- ??

    NOTE

---virtical_integral  
    鉛直積分

    RETURN VALUE
    * GPhys

    NOTE

---wm2mmyr  
    降水量の単位変換(W.m-2 -> mm.yr-1)

    RETURN VALUE
    * GPhys

    NOTE

---wm2mmhr  
    降水量の単位変換(W.m-2 -> mm.hr-1)

    RETURN VALUE
    * GPhys

    NOTE

---sig2press(ps) 
    鉛直座標変換(sig -> press)

    ARGUMNETS    

    RETURN VALUE
    * GPhys

    NOTE

---shape_sig2sigm(sigm)
    

    ARGUMNETS    

    RETURN VALUE
    * GPhys

    NOTE

---diff_sig(sigm)
    sigma微分の計算

    ARGUMNETS    

    RETURN VALUE
    * GPhys

    NOTE

---r_inp_z(sigm)
    半整数レベル(層境界)における値に変換

    ARGUMNETS    

    RETURN VALUE
    * GPhys

    NOTE

---day2min(hr_in_day)
    時間軸の単位変換(days -> min) 

    ARGUMNETS    
    * hours in a day

    RETURN VALUE
    * GPhys

    NOTE

---day2hrs(hr_in_day)
    時間軸の単位変換(day -> hrs) 

    ARGUMNETS    
    * hours in a day

    RETURN VALUE
    * GPhys

    NOTE

---min2hrs
    時間軸の単位変換(min -> hrs) 

    RETURN VALUE
    * GPhys

    NOTE

---hrs2min
    時間軸の単位変換(hrs -> min) 

    RETURN VALUE
    * GPhys

    NOTE

---hrs2day(hr_in_day)
    時間軸の単位変換(hrs -> day) 

    ARGUMNETS    
    * hours in a day

    RETURN VALUE
    * GPhys

    NOTE

---min2day(hr_in_day)
    時間軸の単位変換(min -> day) 


    ARGUMNETS    
    * hours in a day

    RETURN VALUE
    * GPhys

    NOTE

---skip_num(delnum)


    ARGUMNETS    

    RETURN VALUE
    * GPhys

    NOTE

---skip_time(skip,hr_in_day=24.0)


    ARGUMNETS    

    RETURN VALUE
    * GPhys

    NOTE

---lon_max #


    RETURN VALUE
    * GPhys　 <- ??

    NOTE

---local2degree #


    RETURN VALUE
    * GPhys

    NOTE

== AnalyDCPAM module
---local_time(gphys,hr_in_day)
    地方時変換

    ARGUMNETS    

    RETURN VALUE

    NOTE

---sig2press_save(dir,var_name)
    鉛直座標変換(sig -> press)

    ARGUMNETS    

    RETURN VALUE

    NOTE

---calc_press(ps,sig)
    気圧の計算

    ARGUMNETS    

    RETURN VALUE

    NOTE

---calc_planetary_albedo(osr)
    惑星アルベドの計算

    ARGUMNETS    

    RETURN VALUE

    NOTE

---calc_greenhouse_effect(osr,stemp)
    温室効果係数の計算

    ARGUMNETS    

    RETURN VALUE

    NOTE

---calc_msf_save(gv,gps,sigm)  
    質量流線関数の計算

    ARGUMNETS    

    RETURN VALUE

    NOTE

---calc_rh(gqvap,gtemp,gps) 
    相対湿度の計算

    ARGUMNETS    

    RETURN VALUE

    NOTE

---self.calc_prcwtr(dir) 
    可降水量の計算

    ARGUMNETS    

    RETURN VALUE

    NOTE


=end

require "numru/ggraph"
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/utiles.rb")
include NumRu
include Math
include NMath

module NumRu
  class GPhys
#    module AnalyDCPAM
      def glmean  # 全球平均
        gp = self.clone
        return gp.mean(0) if !gp.axnames.include?("lat")
        cos_phi = ( gp.axis("lat").to_gphys * (Math::PI/180.0) ).cos
        fact = cos_phi / cos_phi.mean
        gp_mean = (gp * fact).mean("lon","lat")
        return gp_mean
      end
      #---------------------- 
      def latmean  # 南北平均
        gp = self.clone
        cos_phi = ( gp.axis("lat").to_gphys * (Math::PI/180.0) ).cos
        fact = cos_phi / cos_phi.mean
        gp_mean = (gp * fact).mean("lat")
        return gp_mean
      end
      #----------------------
      def variance(axis=0,ave=nil) # 分散
        gp = self.clone
        ave = gp.glmean(axis) if ave.nil?
        result = (gp - ave)**2
        return result.glmean(axis)
      end
      #---------------------- 
      def virtical_integral  # 鉛直積分
        gp = self.clone
        begin
          if gp.data.file.class == NArray then
            sig_weight = gpopen(gp.data.file[0].path, "sig_weight")
          else
            sig_weight = gpopen(gp.data.file.path, "sig_weight")    
          end
          
        rescue
          if gp.data.file == nil then
            sig_weight = gpopen("./Temp.nc","sig_weight")
          else
            tmp = gp.data.file.path.split("/")
            sig_weight = gpopen(gp.data.file.path.sub(tmp[-1],"Temp.nc"),"sig_weight")
          end
        end
        
        gp_vintg = (gp * sig_weight).sum("sig")
        return gp_vintg
      end
      #----------------------
      def intg_delpress(gp)  # 鉛直積分(気圧)
        gp = self.clone
        return gp
        #    begin
        #      if gp.data.file.class == NArray then
        #        filename = gp.data.file[0].path
        #      else
        #        filename = gp.data.file.path
        #      end
        #      sig_weight = gpopen filename, "sig_weight"
        #      ps = gpopen File.dirname(filename)+"/"+"Ps.nc"
        #    rescue
        #      if gp.data.file == nil then
        #        sig_weight = gpopen "./Temp.nc","sig_weight"
        #        ps = gpopen "./Ps.nc"
        #      else
        #        tmp = gp.data.file.path.split("/")
        #        sig_weight = gpopen gp.data.file.path.sub(tmp[-1],"Temp.nc"),"sig_weight"
        #        ps = gpopen gp.data.file.path.sub(tmp[-1],"Ps.nc")
        #      end
        #    end
        #    gp_intg = (gp * ps * sig_weight).sum("sig")/Grav
      #    return gp_intg
      end
      #----------------------
      def wm2mmyr  # 降水量の単位変換(W.m-2 -> mm.yr-1)
        gp = self.clone
        return gp if !gp.units.to_s.include?("W")
        gp = gp*(3600 * 24 * 360) * 1000 / LatentHeat / WtWet 
        gp.units = Units["mm.yr-1"]
        return gp
      end
      #----------------------
      def wm2mmhr  # 降水量の単位変換(W.m-2 -> mm.hr-1)
        gp = self.clone
        return gp if !gp.units.to_s.include?("W")
        gp = gp* 3600 * 1000 / LatentHeat / WtWet 
        gp.units = Units["mm.hr-1"]
        return gp
      end
      #-----------------------------------------  
      def sig2press(ps) # 鉛直座標変換(sig -> press)
        gp = self.clone

        sig = gp.axis("sig").to_gphys if gp.axnames.include?("sig")
        sig = gp.axis("sigm").to_gphys if gp.axnames.include?("sigm")       

        # 気圧データの準備
        press = calc_press(ps,sig)
        
        # 補助座標に気圧を設定 
        gp.set_assoc_coords([press])
        
        # 気圧座標の値を準備
        press_crd = sig.val*RefPrs
        press_crd = VArray.new(press_crd, {"units"=>"Pa"}, "press")
        # 鉛直座標を気圧に変換
        gp_press = gp.interpolate(sig.name=>press_crd)
        
        return gp_press
      end
      # ---------------------------------------
      def shape_sig2sigm(sigm)
        gp = self.clone 
        lon = gp.axis("lon")
        lat = gp.axis("lat")
        time = gp.axis("time")
        result = GPhys.new(Grid.new(lon,lat,sigm.axis("sigm"),time),
                           VArray.new(
                                      NArray.sfloat(
                                                lon.length,lat.length,sigm.length,time.length)))
        result.name = gp.name
        result.units = gp.units
        result[false] = 0
        return result
      end
      # ---------------------------------------
      def diff_sig(sigm)
        gp = self.clone 
        result = gp.shape_sig2sigm(sigm)
        sig = gp.axis("sig").to_gphys.val
        (sig.length-1).times do |n|
        result[false,n+1,true].val = 
            (gp.cut("sig"=>sig[n+1]).val-gp.cut("sig"=>sig[n]).val)/
                                                 (sig[n+1]-sig[n])
        end
        return result
      end
      # ---------------------------------------
      def r_inp_z(sigm)
        z_gp = self.clone 
        sig = z_gp.axis("sig").to_gphys.val
        r_gp = sub_sig2sigm(z_gp,sigm)
        sigm = sigm.val
        r_gp[false,0,true].val = z_gp[false,0,true].val
        (sig.length-2).times do |n|
          alph = log(sigm[n+1]/sig[n+1]) / log(sig[n]/sig[n+1])
          beta = log(sig[n]/sigm[n+1]) / log(sig[n]/sig[n+1])
          r_gp[false,n+1,true].val = alph * z_gp[false,n,true].val 
                                  + beta * z_gp[false,n+1,true].val
        end
        r_gp[false,-1,true].val = z_gp[false,-1,true].val
        
        return r_gp
      end
      # ---------------------------------------
      def day2min(hr_in_day=24.0)
        gp = self.clone 
        time =  gp.axis("time").pos * hr_in_day * 60
        time.units = "min"
        gp.axis("time").set_pos(time)  
        return gp
      end
      # ---------------------------------------
      def day2hrs(hr_in_day=24.0)
        gp = self.clone 
        time =  gp.axis("time").pos * hr_in_day
        time.units = "hrs"
        gp.axis("time").set_pos(time)  
        return gp
      end
      #----------------------------------------
      def min2hrs
        gp = self.clone 
        time =  gp.axis("time").pos / 60
        time.units = "hrs"
        gp.axis("time").set_pos(time)
        return gp
      end
      #----------------------------------------
      def hrs2min
        gp = self.clone 
        time =  gp.axis("time").pos * 60
        time.units = "min"
        gp.axis("time").set_pos(time)
        return gp
      end
      #----------------------------------------
      def hrs2day(hr_in_day=24.0)
        gp = self.clone 
        time =  gp.axis("time").pos / hr_in_day
        time.units = "day"
        gp.axis("time").set_pos(time)  
        return gp
      end
      #----------------------------------------
      def min2day(hr_in_day=24.0)
        gp = self.clone 
        time =  gp.axis("time").pos / hr_in_day / 60
        time.units = "day"
        gp.axis("time").set_pos(time)
        return gp
      end
      #----------------------------------------
      def skip_num(delnum)
        gp = self.clone 
        gp_ary = []
        (gp.axis("time").length-1).times do |t|
          gp_ary << gp[false,t..t] if t%delnum == 0
        end
        result = GPhys.join(gp_ary)
        return result
      end
      #---------------------------------------
      def skip_time(skip,hr_in_day=24.0)
        gp = self.clone 

        time = gp.axis("time").pos
        time = time/hr_in_day   if time.units.to_s == "hrs"
        time = time/hr_in_day/60 if time.units.to_s == "min"
        time.units = "day" 
        gp.axis("time").set_pos(time)
        time = time.val
        
        gp_ary = []
        (time.length-1).times do |t|
          nowtime = time[0]+skip*t
          break if nowtime >= time[-1]
          gp_ary << gp.cut_rank_conserving("time"=>nowtime)
        end
        result = GPhys.join(gp_ary)
        return result
      end
      # --------------------------------------
      def diurnal(slon=nil) #
        gp = self.clone
        max = gp.lon_max
        sunrise = max/4
        sunset = max*3/4
        gp = gp.cut("lon"=>sunset..sunrise)
        return gp
      end
      # --------------------------------------
      def mask_diurnal(slon=nil) #
        gp = self.clone
        result = gp*day_mask(gp)
        return result
      end
      # ---------------------------------------
      def mask_night(slon=nil) #
        gp = self.clone
        result = gp*(1-day_mask(gp))
        return result
      end
      # ---------------------------------------
      def lon_max
        lon = self.axis("lon").to_gphys.val
        result = (lon[1]-lon[0])*lon.length
        return result
      end
      # -----------------------------------
      def local2degree
        gp = self.clone
        xcoord = gp.axis(0).to_gphys.val
        xmax = gp.lon_max
        return gp if xmax == 360
        a = 360/xmax
        local = gp.axis(0).pos * a
        local.units = "degree"
        gp.axis(0).set_pos(local)
        return gp
      end
#    end
  end
end
##############################################################
module AnalyDCPAM
  def local_time(gphys,hr_in_day)
    
    lon = gphys.axis('lon')
    local = lon.pos
    local = lon.pos*hr_in_day/360
    local.long_name = "local time"
    
    lon = lon.to_gphys
    local_time = lon.copy
    nlon = lon.length
    gp_local_converted = gphys.copy
#    GPhys.each_along_dims(gphys,"time") do |gp|
    gphys.axis("time").to_gphys.val.to_a.each_index do |t|
#      gp = gphys.cut_rank_conserving("time"=>time)
      gp = gphys[false,t..t]
      nowtime = gp.axis("time").to_gphys
      gp_local = gp.copy
      # 時間の単位を[day]に変更
      nowtime.val = nowtime.val/hr_in_day    if nowtime.units.to_s == "hrs"
      nowtime.val = nowtime.val/hr_in_day/60 if nowtime.units.to_s == "min"
      # 日付が変わる経度を検出
      local_time.val = nowtime.val + lon.val/360
      local_time.val = (local_time.val - local_time.val.to_i)*hr_in_day
      local_min_index = local_time.val.to_a.index(local_time.val.min)
      # データの並び替え
      if local_min_index != 0 then
        gp_local[0..nlon-1-local_min_index,false].val = gp[local_min_index..-1,false].val
        gp_local[nlon-local_min_index..-1,false].val = gp[0..local_min_index-1,false].val
      end
      gp_local_converted[false,t..t].val = gp_local[false].val 
    end

    # lon -> localtime 変換
    gp_local_converted.axis("lon").set_pos(local)

#    if gp_local_converted.size == 1
#      return gp_local_converted[0] 
#    else
#      return GPhys.join(gp_local_converted)
#    end
    return gp_local_converted
  end
  #-----------------------
  def calc_press(ps,sig)
    grid_a = []
    ps.axnames.each do |axname|
      grid_a << ps.axis(axname)
    end
    
    if ps.axnames.include? "time"
      grid_a.insert(-2,sig.axis(0))
    else
      grid_a << sig.axis(0)
    end

    grid_length = []
    grid_a.each do |axis|
      grid_length << axis.length
    end

    press_na = NArray.sfloat(*grid_length)
    grid = Grid.new(*grid_a)
    press = GPhys.new(grid,VArray.new(press_na))
    
    press[false] = 1
    press = press * ps
    press = press * sig

    press.units = "Pa"
    press.name = "press"
    press.long_name = "pressure"
    return press
  end
  #----------------------------------------- 
  def calc_planetary_albedo(osr)
    return 1.0 + osr.glmean/(SolarConst/4)
  end
  #----------------------------------------- 
  def calc_greenhouse_effect(osr,stemp)
    etemp = (SolarConst*(1.0-calc_planetary_albedo(osr))/(4*StB))**(1.0/4)
    return stemp.glmean/etemp
  end
  # --------------------------------------------
  def cos_ang(gp,hr_in_day=24.0) # cos(太陽天頂角) ##
    # gp は地方時変換済みであることが前提
    gp = gp.local2degree
    lon = gp.axis("lon").to_gphys if gp.axnames.include?("lon")
    lat = gp.axis("lat").to_gphys if gp.axnames.include?("lat")

    if gp.axnames.include?("time")
      time = gp.axis("time").to_gphys 
      gp = gp.min2day(hr_in_day) if gp.axis("time").pos.units.to_s == "min"
      gp = gp.hrs2day(hr_in_day) if gp.axis("time").pos.units.to_s == "hrs"
    end
#    slon = (time - time.to_i)*360
#    slon = UNumeric[slon[0].val,"degree"]    # 太陽直下点経度
    slon = UNumeric[0,"degree"]    # 太陽直下点経度
    
    ang = gp[false].copy
    ang[false] = -1.0
    ang.units = "1"
    ang = ang*((ang.axis("lon").to_gphys+slon)*PI/180.0).cos
    ang = ang*(ang.axis("lat").to_gphys*PI/180.0).cos
    return ang.mask_diurnal + 1e-14
  end
  # ---------------------------------------------
  def day_mask(gp,slon=0) #
    mask = gp.copy
    mask[false] = 0
    nmax = mask.axis(0).length
    mask[nmax/4..nmax*3/4,false] = 1
    mask.units = "1"
    return mask
  end
end
