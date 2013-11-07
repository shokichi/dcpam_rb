#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 
# 
require "numru/ggraph"
require 'numru/gphys'
require "./utiles_spe.rb"
include NumRu
include Math
include NMath
include Utiles_spe

module Analy
  def glmean(gp)  # 全球平均
    cos_phi = ( gp.axis("lat").to_gphys * (Math::PI/180.0) ).cos
    fact = cos_phi / cos_phi.mean
    gp_mean = (gp * fact).mean("lon","lat")
    return gp_mean
  end
  #---------------------- 
  def latmean(gp)  # 南北平均
    cos_phi = ( gp.axis("lat").to_gphys * (Math::PI/180.0) ).cos
    fact = cos_phi / cos_phi.mean
    gp_mean = (gp * fact).mean("lat")
    return gp_mean
  end
  #------------------------
  def std_error(narray,blocknum=nil) # 標準偏差
    blocknum = narray.length if blocknum.nil?
    ave = narray.mean
    var = NArray.sfloat(blocknum)
    range1 = 0
    delrange = narray.length/blocknum
    
    for n in 0..blocknum-1 
      range2 = range1 + delrange.to_i
      var[n] = narray[range1..range2-1].mean
      range1 = range2
    end
    
    std = (((var-ave)**2).mean)**0.5
    return std
  end
  
  #---------------------- 
  def virtical_integral(gp)  # 鉛直積分
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
  def self.wm2mmyr(gp)  # 降水量の単位変換(W.m-2 -> mm.yr-1)
    return gp if gp.units.to_s.include?("W")
    gp = gp*(3600 * 24 * 360) * 1000 / LatentHeat / WtWet 
    gp.units = Units["mm.yr-1"]
    return gp
  end
  #----------------------
  def self.wm2mmhr(gp)  # 降水量の単位変換(W.m-2 -> mm.hr-1)
    return gp if gp.units.to_s.include?("W")
    gp = gp* 3600 * 1000 / LatentHeat / WtWet 
    gp.units = Units["mm.hr-1"]
    return gp
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
  def self.sig2press(gp,ps) # 鉛直座標変換(sig -> press)
    #  ps = gpopen(gp.data.file.path.sub(gp.name+".nc","Ps.nc"),"Ps")
    # 座標データ取得
    time = gp.axis(-1).to_gphys
    sig = gp.axis(-2).to_gphys
    
    
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
    press_crd = VArray.new( sig.val*RefPrs, {"units"=>"Pa"}, "press")
    
    # 鉛直座標を気圧に変換
    gp_press = gp.interpolate(sig.name=>press_crd)
    
    return gp_press
  end
  
  #----------------------------------------- 
  def self.calc_msf(gv,gps,sigm)  # 質量流線関数の計算
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
  # ---------------------------------------
  def local_time(gphys,hr_in_day)
    
    lon = gphys.axis('lon')
    local = lon.pos
    local = lon.pos*hr_in_day/360
    local.long_name = "local time"
    
    lon = lon.to_gphys
    local_time = lon.copy
    nlon = lon.length
    
    gp_local_converted = GPhys.each_along_dims(gphys,"time"){ |gp|
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
      # lon -> localtime 変換
      gp_local.axis("lon").set_pos(local)
      return gp_local 
    }  
    return gp_local_converted
  end
  
  # ---------------------------------------
  def omega_ratio(name)# 名前解析 nameからomega/omega_Eを抽出
    if name[0..4] == "omega" or name[0..4] == "Omega" then
      var = name.sub("omega","").sub("Omega","")
      if var.include?("-")
        var = var.split("-")
        var = var[1].to_f/var[0].to_f
      elsif var.include?("/")
        var = var.split("/") 
        var = var[0].to_f/var[1].to_f
      end
      ratio = var.to_f
    else
      print "ERROR: [#{name}] can't decode\n"
      ratio = 1.0
    end
    return ratio
  end
  # ---------------------------------------
  def day2hrs(gp,name)
    hour_in_day = 24 / omega_ratio(name)
    time =  gp.axis("time").pos * hour_in_day
    gp.axis("time").set_pos(time)  
    return gp
  end
  #----------------------------------------
  def hrs2day(gp,hr_in_day)
    time =  gp.axis("time").pos / hr_in_day
    gp.axis("time").set_pos(time)  
    return gp
  end
  #----------------------------------------
  def min2day(gp,hr_in_day)
    time =  gp.axis("time").pos / hr_in_day / 60
    gp.axis("time").set_pos(time)
    return gp
  end
  #----------------------------------------
  def thinout(gp,delnum)
    time = 0
    result = GPhys.each_along_dims(gp,"time"){ |gphys|
      return gphys if time%delnum == 0
      time += 1
    }
    result
  end
end
