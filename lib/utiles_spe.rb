#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 
# 
module Utiles_spe 
include NumRu
include Math
include NMath
require "numru/ggraph"
require 'numru/gphys'
 
#---------------------- 
def self.explist(file_list)  # 実験ファイルリストの読み込み
  dir = []
  name = []
  if file_list != nil then
    if file_list[0..0] == "-" 
      dir[0] = "./"
      name[0] = ""
    else
      begin
        fin = File.open(file_list,"r")
      rescue
        dir[0] = system("pwd")
        name[0] = ""
        print "not exist  [#{file_list}]\n"
        print "set directory  [#{dir[0]}]\n"
        return dir, name
      end  
      n = 0 
      loop{
        char = fin.gets
        if char == nil then  break  end
        if char[0..0] == "#" then next end # コメントアウト機能
        char = char.chop.split(",")
        name[n] = char[0]
        dir[n] = char[1]
        if dir[n].include?(":") == true then
          dir[n] = dir[n].split(":")
        end 
        n += 1
      }
      fin.close
    end
  else
    dir[0] = "./"
    name[0] = ""
  end
  return dir, name
end
#----------------------
def self.str_add(char,str)
  if char.class == Array then
    for n in 0..char.size-1
      char[n] = char[n] + str
    end    
  else
    char = char + str
  end  
  return char
end 
#---------------------- 
def self.glmean(gp)  # 全球平均の計算
  cos_phi = ( gp.axis("lat").to_gphys * (Math::PI/180.0) ).cos
  fact = cos_phi / cos_phi.mean
  gp_mean = (gp * fact).mean("lon","lat")
  return gp_mean
end

#---------------------- 
def self.virtical_integral(gp)  # 鉛直積分
  begin
    sig_weight = GPhys::IO.open(gp.data.file.path, "sig_weight")
  rescue
    if gp.data.file == nil then
      sig_weight = GPhys::IO.open("./Temp.nc","sig_weight")
    else
      tmp = gp.data.file.path.split("/")
      sig_weight = GPhys::IO.open(gp.data.file.path.sub(tmp[-1],"Temp.nc"),"sig_weight")
    end
  end
  gp_vintg = GPhys.each_along_dims(gp,"time"){ |gphys|
    (gphys * sig_weight).sum("sig") 
    }
  return gp_vintg
end

#----------------------
def self.wm2mmyr(gp)  # 降水量の単位変換(W.m-2 -> mm.yr-1)
# if gp.units.to_s == "W.m-2" then
  r = UNumeric[2265900, "J.kg-1"]
  rho = UNumeric[1000, "kg.m-3"]
  gp = gp*(3600 * 24 * 360) * 1000 / r / rho 
  gp.units = Units["mm.yr-1"]
#  end
 return gp
end

#-----------------------
def self.array2gp(x_var,y_var)  # 簡単GPhysオブジェクトの作成
  x_val = NArray.to_na(x_var) # x軸
  y_val = NArray.to_na(y_var) # y軸

  x_coord = Axis.new
  x_coord.set_pos(VArray.new(x_val))
  grid = Grid.new(x_coord)
  gp = GPhys.new(grid,VArray.new(y_val))

  return gp
end

#----------------------------------------- 
def sig2press_save(dir,var_name) # 鉛直座標変換(sig -> press)
  # ファイルオープン
  gphys = GPhys::IO.open(dir + var_name +".nc",var_name)
  gps = GPhys::IO.open(dir + "Ps.nc","Ps")

  # 座標データ取得
  time = gphys.axis(-1).to_gphys
  sig = gphys.axis(-2).to_gphys
  
  # 定数設定
  p0 = UNumeric[100000, "Pa"]
  
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
    press_crd = sig.val*p0
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
#  ps = GPhys::IO.open(gp.data.file.path.sub(gp.name+".nc","Ps.nc"),"Ps")
  # 座標データ取得
  time = gp.axis(-1).to_gphys
  sig = gp.axis(-2).to_gphys

  # 定数設定
  p0 = UNumeric[100000, "Pa"]
  
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
  press_crd = VArray.new( sig.val*p0, {"units"=>"Pa"}, "press")

  # 鉛直座標を気圧に変換
  gp_press = gp.interpolate(sig.name=>press_crd)

  return gp_press
end

#----------------------------------------- 
def calc_msf(dir)  # 質量流線関数の計算
  # file open
  gv = GPhys::IO.open(dir + "V.nc", "V")
  gps = GPhys::IO.open(dir + "Ps.nc", "Ps")
  sigm = GPhys::IO.open(dir + "V.nc", "sigm")

  # 定数設定
  grav = UNumeric[9.8, "m.s-2"]
  round = UNumeric[6400000.0, "m"]

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
    alph = vwind * cos_phi * ps * round * PI * 2 / grav 
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
def calc_rh(dir) # 相対湿度の計算
  # file open
  gqvap = GPhys::IO.open(dir + "QVap.nc", "QVap")
  gps = GPhys::IO.open(dir + "Ps.nc", "Ps")
  gtemp = GPhys::IO.open(dir + "Temp.nc", "Temp")

  # 座標データの取得
  lon = gtemp.axis('lon')
  lat = gtemp.axis('lat')
  sig = gtemp.axis('sig').to_gphys

  # 定数設定
  grav = UNumeric[9.8, "m.s-2"]
  round = UNumeric[6400000.0, "m"]
  qvapmol = UNumeric[18.01528e-3, "kg.mol-1"]
  drymol =UNumeric[28.964e-3,"kg.mol-1"]
  p0 = UNumeric[1.4e+11,"Pa"]
  latheat = UNumeric[43655,"J.mol-1"]
  gasruniv = UNumeric[8.314,"J.K-1.mol-1"]

  es0 = UNumeric[611,"Pa"]
  latentheat = UNumeric[2.5e+6,"J.kg-1"]
  gasrwet = gasruniv / qvapmol
  epsv = qvapmol / drymol


  data_name = 'RH'
  ofile = NetCDF.create( dir + data_name + '.nc')
  GPhys::NetCDF_IO.each_along_dims_write([gqvap,gps,gtemp],ofile,'time'){ 
    |qvap,ps,temp| 

    time = ps.axis('time')  
 
    # 気圧の計算
    press_na = NArray.sfloat(lon.length,lat.length,sig.length,time.length)
    grid = Grid.new(lon,lat,sig.axis('sig'),time)
    press = GPhys.new(grid,VArray.new(press_na))
    press.units = 'Pa'

    for k in 0..sig.length-1
      press[false,k,true] = ps * sig[k].val
    end

    # 飽和水蒸気圧の計算
    es = es0 * ( latentheat / gasrwet * ( 1/273.0 - 1/temp ) ).exp
  
    # 飽和非湿の計算
  #  qvap_sat = epsv * (p0 / press) * (-latheat / (gasruniv * temp) ).exp

    # 水蒸気圧の計算
    e = qvap * press / epsv

    # 相対湿度の計算
    rh = e / es * 100 # [%]
  #  rh = qvap / qvap_sat * 100 # [%]

    rh.units = '%'
    rh.long_name = 'relative humidity'
    rh.name = data_name  

    [rh]
    }
  ofile.close
  print "[#{data_name}](#{dir}) is created\n"
end

# --------------------------------------------
def calc_prcwtr(dir) # 可降水量の計算
  # file open
  gqv = GPhys::IO.open(dir + "QVap.nc", "QVap")
  gps = GPhys::IO.open(dir + "Ps.nc", "Ps")
  sigm = GPhys::IO.open(dir + "QVap.nc", "sigm")

  # constant
  grav = UNumeric[9.8, "m.s-2"]

  lon = gqv.axis("lon")
  lat = gqv.axis("lat")

  data_name = 'QVapCulumu'
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

    alph = qvap * ps / grav 
    kmax = 15
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
def mirror_lat(gp) # 折り返し(緯度)
  lat = gp.axis("lat").to_gphys
  if lat.max != -lat.min then
    print "Can not mirror [#{gp.name}]\n"
    return gp
  end
  mirror = gp.cut("lat"=>0..90).copy
  mirror[false] = 0
  (0..lat.length/2-1).each{|n|
    mirror.cut("lat"=>lat.val).val = 
      (gp.cut("lat"=>lat.val).val + gp.cut("lat"=>-lat.val).val)/2}  
  return mirror
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
# ---------------------------------------
end
