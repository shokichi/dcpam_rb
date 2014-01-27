#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 
# 
require "numru/ggraph"
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/utiles_spe.rb")
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
        return gp if gp.units.to_s.include?("W")
        gp = gp*(3600 * 24 * 360) * 1000 / LatentHeat / WtWet 
        gp.units = Units["mm.yr-1"]
        return gp
      end
      #----------------------
      def wm2mmhr  # 降水量の単位変換(W.m-2 -> mm.hr-1)
        gp = self.clone
        return gp if gp.units.to_s.include?("W")
        gp = gp* 3600 * 1000 / LatentHeat / WtWet 
        gp.units = Units["mm.hr-1"]
        return gp
      end
      #-----------------------------------------  
      def sig2press(ps) # 鉛直座標変換(sig -> press)
        gp = self.clone
        # 座標データ取得
        time = gp.axis("time").to_gphys if gp.axnames.include?("time")
        sig = gp.axis("sig").to_gphys if gp.axnames.include?("sig")
        sig = gp.axis("sigm").to_gphys if gp.axnames.include?("sigm") 
        
        # 気圧データの準備
        press = calc_press(ps,sig)
        
        # 補助座標に気圧を設定 
        gp.set_assoc_coords([press])
        
        # 気圧座標の値を準備
        press_crd = VArray.new( sig.val*RefPrs, {"units"=>"Pa"}, "press")
        
        # 鉛直座標を気圧に変換
        gp_press = gp.interpolate(sig.name=>press_crd)
        
        return gp_press
      end
      # ---------------------------------------
      def sub_sig2sigm(sigm)
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
        result = sub_sig2sigm(gp,sigm)
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
      def day2min(hr_in_day)
        gp = self.clone 
        time =  gp.axis("time").pos * hr_in_day * 60
        time.units = "min"
        gp.axis("time").set_pos(time)  
        return gp
      end
      # ---------------------------------------
      def day2hrs(hr_in_day)
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
      def hrs2day(hr_in_day)
        gp = self.clone 
        time =  gp.axis("time").pos / hr_in_day
        time.units = "day"
        gp.axis("time").set_pos(time)  
        return gp
      end
      #----------------------------------------
      def min2day(hr_in_day)
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
      def diurnal(slon=nil)
        gp = self.clone
        max = gp.lon_max
        sunrise = max/4
        sunset = max*3/4
        gp = gp.cut("lon"=>sunset..sunrise)
        return gp
      end
      # --------------------------------------
      def mask_diurnal(slon=nil)
        gp = self.clone
        result = gp*day_mask(gp)
        return result
      end
      # ---------------------------------------
      def mask_night(slon=nil)
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
    lon = ps.axis(0)
    lat = ps.axis(1)
    time = ps.axis(2)
    press_na = NArray.sfloat(lon.length,lat.length,sig.length,time.length)
    grid = Grid.new(lon,lat,sig.axis(0),time)
    press = GPhys.new(grid,VArray.new(press_na))
    press.units = "Pa"
    press.name = "Press"
    press.long_name = "pressure"
    
    press[false] = 1
    press = press * ps
    press = press * sig
    return press
  end
  #----------------------------------------- 
  def sig2press_save(dir,var_name) # 鉛直座標変換(sig -> press)
    # ファイルオープン
    gphys = gpopen(dir + var_name +".nc",var_name)
    gps = gpopen(dir + "Ps.nc","Ps")
    
    # 座標データ取得
    sig = gphys.axis(-2).to_gphys
    
    ofile = NetCDF.create(dir + 'Prs_' + var_name + '.nc')
    GPhys::NetCDF_IO.each_along_dims_write([gphys,gps],ofile, 'time') { 
      |gp,ps|  
      
      # 気圧データの準備
      press = gp.copy
      press.units = 'Pa'
      press.name = "press"
      press.long_name = "pressure"
      press[false] = 0
      for k in 0..sig.length-1
        press[false,k,true] = ps * sig[k].val
      end
      
      # 補助座標に気圧を設定 
      gp.set_assoc_coords([press])
      
      # 気圧座標の値を準備
      press_crd = sig.val*RefPrs
      p press_crd
      press_crd = VArray.new( press_crd, {"units"=>"Pa"}, "press")
      
      # 鉛直座標を気圧に変換
      gp_press = gp.interpolate(sig.name=>press_crd)
      
      # 出力
      [gp_press]
    }
    
  end
  #----------------------------------------- 
  def calc_planetary_albedo(osr)
    return 1.0 + osr.glmean/(SolarConst/4)
  end
  #----------------------------------------- 
  def self.calc_msf_save(gv,gps,sigm)  # 質量流線関数の計算
    # file open
    if gqvap.name != "QVap" or gps.name != "Ps" or gtemp.name != "Temp"
      print "Argument is not [QVap,Temp,Ps]"
      return
    end
    # 座標データの取得
    lon = gv.axis("lon")
    lat = gv.axis("lat")
    
    data_name = 'Strm'
    ofile = NetCDF.create( dir + data_name + '.nc')
    GPhys::NetCDF_IO.each_along_dims_write([gv,gps], ofile, 'time') { 
      |vwind,ps|  
      
      time = vwind.axis("time")    
      
      msf_na = NArray.sfloat(lon.length,lat.length,sigm.length,time.length)
      grid = Grid.new(lon,lat,sigm.axis("sigm"),time)
      msf = GPhys.new(grid,VArray.new(msf_na))
      msf.units = 'kg.s-1'
      msf.long_name = 'mass stream function'
      msf.name = data_name
      msf[false] = 0
      
      cos_phi = ( vwind.axis("lat").to_gphys * (PI/180.0) ).cos
      alph = vwind * cos_phi * ps * RPlanet * PI * 2 / Grav 
      kmax = 15
      for i in 0..kmax
        k = kmax-i
        msf[false,k,true] = msf[false,k+1,true] +
          alph[false,k,true] * (sigm[k].val - sigm[k+1].val) 
      end
      [msf]
    }
    ofile.close
    print "[#{data_name}](#{dir}) is created\n"
  end
  # -------------------------------------------
  def self.calc_rh(gqvap,gtemp,gps) # 相対湿度の計算
    # file check
  if gqvap.name != "QVap" or gps.name != "Ps" or gtemp.name != "Temp"
    print "Argument is not [QVap,Temp,Ps]"
    return
  end
    
    # 座標データの取得
    lon = gtemp.axis('lon')
    lat = gtemp.axis('lat')
    sig = gtemp.axis('sig').to_gphys
    
    # 定数設定
    qvapmol = UNumeric[18.01528e-3, "kg.mol-1"]
    drymol =UNumeric[28.964e-3,"kg.mol-1"]
    p0 = UNumeric[1.4e+11,"Pa"]
    latheat = UNumeric[43655,"J.mol-1"]
    gasruniv = UNumeric[8.314,"J.K-1.mol-1"]
    
    es0 = UNumeric[611,"Pa"]
    latentheat = UNumeric[2.5e+6,"J.kg-1"]
    #  latheat = LatentHeat * MolWtWet
    
    gasrwet = gasruniv / qvapmol
    epsv = qvapmol / drymol
    
    # 
    data_name = 'RH'
    file = gqvap.data.file.path.sub("QVap",data_name)
    ofile = NetCDF.create(file)
    GPhys::NetCDF_IO.each_along_dims_write([gqvap,gps,gtemp],ofile,'time'){ 
      |qvap,ps,temp| 
      # 気圧の計算
      press = calc_press(ps,sig)    
      
      #    for k in 0..sig.length-1
      #      press[false,k,true] = ps * sig[k].val
      #    end
      
      # 飽和水蒸気圧の計算
      es = es0 * ( latentheat / gasrwet * ( 1/273.0 - 1/temp ) ).exp
      # 水蒸気圧の計算
      e = qvap * press / epsv
      # 相対湿度の計算
      rh = e / es * 100 # [%]
      
      # 飽和非湿の計算
      #    qvap_sat = epsv * (p0 / press) * (-latheat / (gasruniv * temp) ).exp
      # 相対湿度の計算
      #    rh = qvap / qvap_sat * 100 # [%]
      
      rh.units = '%'
      rh.long_name = 'relative humidity'
      rh.name = data_name  
      
      [rh]
    }
    ofile.close
    print "[#{data_name}](#{file}) is created\n"
  end
  
  # --------------------------------------------
  def self.calc_prcwtr(dir) # 可降水量の計算
    # file open
    gqv = gpopen(dir + "QVap.nc", "QVap")
    gps = gpopen(dir + "Ps.nc", "Ps")
    sigm = gpopen(dir + "QVap.nc", "sigm")
    
    lon = gqv.axis("lon")
    lat = gqv.axis("lat")
    
    data_name = 'PrcWtr'
    ofile = NetCDF.create( dir + data_name + '.nc')
    GPhys::NetCDF_IO.each_along_dims_write([gqv,gps], ofile, 'time') { 
      |qvap,ps|  
      #
      time = qvap.axis("time")    
      
      qc_na = NArray.sfloat(lon.length,lat.length,time.length)
      grid = Grid.new(lon,lat,time)
      qc = GPhys.new(grid,VArray.new(qc_na))
      qc.units = 'kg.m-2'
      qc.long_name = 'precipitable water'
      qc.name = data_name
      qc[false] = 0
      
      alph = qvap * ps / Grav 
      kmax = 22
      for i in 0..kmax
        k = kmax-i
        qc = qc + alph[false,k,true] * (sigm[k].val - sigm[k+1].val) 
      end
      [qc]
    }
    ofile.close
    print "[#{data_name}](#{dir}) is created\n"
  end  
  # --------------------------------------------
  def cos_ang(gp,hr_in_day=24.0) # cos(太陽天頂角) 
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
  def day_mask(gp,slon=0)
    mask = gp.copy
    mask[false] = 0
    nmax = mask.axis(0).length
    mask[nmax/4..nmax*3/4,false] = 1
    mask.units = "1"
    return mask
  end
end
