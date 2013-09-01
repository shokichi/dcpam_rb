#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 
# 
require "numru/ggraph"
require 'numru/gphys'
include NumRu
include Math
include NMath

module Utiles_spe 
# 定数
Grav    = UNumeric[9.8, "m.s-2"]       # 重力加速度
RPlanet = UNumeric[6371000.0, "m"]     # 惑星半径
RefPrs  = UNumeric[100000, "Pa"]       # 基準気圧
LatentHeat = UNumeric[2.5e+6,"J.kg-1"] # 凝結の潜熱
WtWet   = UNumeric[1000, "kg.m-3"]     # 水の密度
MolWtWet = UNumeric[18.01528e-3, "kg.mol-1"] # 水蒸気の平均分子量
MolWtDry = UNumeric[28.964e-3,"kg.mol-1"]    # 乾燥大気の平均分子量
GasRUniv = UNumeric[8.3144621,"J.K-1.mol-1"] # 気体定数


class Explist
  # 実験ファイルリストの読み込み
  def initialize(file_list)
    @@filelist = file_list
    if @@filelist != nil then
      read_file
      get_exp_id
    else
      default
    end
  end

  def refnum
   result = @name.index(@ref)
   return result
  end

  private

  def read_file
    begin
      fin = File.open(@@filelist,"r")
    rescue
      default
      error_msg
      return
    end
    analize(fin)
  end

  def analize(fin)
    name = []
    dir = []
    fin.each do |char|
      next if char[0..0] == "#" # コメントアウト機能
      char = char.chop.split(",")
      if char[0][0..0] == "!" # 基準実験
        char[0] = char[0].sub("!","")
        @ref = char[0]
      end    
      name << char[0]
      dir << char[1]
      dir << char[1].split(":") if char[1].include?(":") == true 
    end
    fin.close
    @dir = dir 
    @name = name
  end
  
  def get_exp_id
    @id = @@filelist.split("/")[-1].sub(".list","")
  end

  def default
    @name = [""]
    @dir  = ["./"]
    @id  = "none"
    @ref = @name
  end

  def error_msg
    print "[#{@@filelist}] No Such file \n"
    print "[#{@dir[0]}] Set current directory \n"
  end

  public  
  attr_reader :dir, :name, :id, :ref
end

#----------------------
def str_add(str,add_str)
  result = []
  if str.class == Array then
    str.each_index do |n|
      if add_str.class == Array then
        result[n] = str[n] + add_str[n]
      else
        result[n] = str[n] + add_str
      end
    end
  elsif add_str.class == Array and str.class != Array then
    add_str.each_index do |n|
      result[n] = str + add_str[n]
    end
  else
    result = str + add_str
  end
  return result
end 
#---------------------- 
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
      sig_weight = GPhys::IO.open(gp.data.file[0].path, "sig_weight")
    else
      sig_weight = GPhys::IO.open(gp.data.file.path, "sig_weight")    
    end
  rescue
    if gp.data.file == nil then
      sig_weight = GPhys::IO.open("./Temp.nc","sig_weight")
    else
      tmp = gp.data.file.path.split("/")
      sig_weight = GPhys::IO.open(gp.data.file.path.sub(tmp[-1],"Temp.nc"),"sig_weight")
    end
  end
  gp_vintg = GPhys.each_along_dims(gp,"time"){ |gphys|
    intg = (gphys * sig_weight).sum("sig")
    return intg
    }
  return gp_vintg
end

#----------------------
def self.wm2mmyr(gp)  # 降水量の単位変換(W.m-2 -> mm.yr-1)
# if gp.units.to_s == "W.m-2" then
  gp = gp*(3600 * 24 * 360) * 1000 / LatentHeat / WtWet 
  gp.units = Units["mm.yr-1"]
#  end
 return gp
end
#----------------------
def self.wm2mmhr(gp)  # 降水量の単位変換(W.m-2 -> mm.hr-1)
  gp = gp* 3600 * 1000 / LatentHeat / WtWet 
  gp.units = Units["mm.hr-1"]
 return gp
end

#-----------------------
def self.array2gp(x_var,y_var)  # 簡単GPhysオブジェクトの作成
  x_val = NArray.to_na(x_var) # x軸
  y_val = NArray.to_na(y_var) # y軸

  x_coord = Axis.new
  x_coord.name = "x_coord"
  x_coord.set_pos(VArray.new(x_val))
  grid = Grid.new(x_coord)
  gp = GPhys.new(grid,VArray.new(y_val))
  gp.name = "y_coord"
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
  sigm = GPhys::IO.open(dir + "QVap.nc", "sigm")

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
def local_time(gp,hr_in_day,nowtime=nil)

  lon = gp.axis('lon')
  local = lon.pos
  local = lon.pos*hr_in_day/360
  local.long_name = "local time"
  
  lon = lon.to_gphys
  local_time = lon.copy
  nlon = lon.length

  nowtime = gphys.axis("time").to_gphys if nowtime.nil?
  gp_local = gphys.copy
  # 時間の単位を[day]に変更
  nowtime.val = nowtime.val/hr_in_day    if nowtime.units.to_s == "hrs"
  nowtime.val = nowtime.val/hr_in_day/60 if nowtime.units.to_s == "min"
  # 日付が変わる経度を検出
  local_time.val = nowtime.val + lon.val/360
  local_time.val = (local_time.val - local_time.val.to_i)*hr_in_day
  local_min_index = local_time.val.to_a.index(local_time.val.min)
  # データの並び替え
  if local_min_index != 0 then
    gp_local[0..nlon-1-local_min_index,false].val = gphys[local_min_index..-1,false].val
    gp_local[nlon-local_min_index..-1,false].val = gphys[0..local_min_index-1,false].val
  end
  # lon -> localtime 変換
  gp_local.axis("lon").set_pos(local)

  return gp_local
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
#---------------------------------------
def gpopen(file,name=nil)
  name = File.basename(file,".nc").gsub("_","").sub("MT","").sub("local","") if name.nil?
  if defined?(Flag_rank) then
    gp = gpopen_rank(file,name)
    gp = gpopen_nomal(file,name) if gp.nil?
  else
    gp = gpopen_nomal(file,name)
    gp = gpopen_rank(file,name) if gp.nil?
  end

  print "[#{name}](#{File.dirname(file)}) is not exist \n" if gp.nil?
  return gp
end
# ---------------------------------------
def gpopen_nomal(file,name)
  begin
    gp = GPhys::IO.open file,name
  rescue
    gp = nil
  end
  return gp
end
# ---------------------------------------
def gpopen_rank(file,name)
  begin
    if !file.include?(name)
      gp = GPhys::IO.open file.sub(".nc","_rank000000.nc"), name
    else
      gp = GPhys::IO.open Dir.glob(file+"_rank*.nc"), name     #<=読み込みに時間がかかりすぎる
    end
  rescue
    gp = nil
  end 
  return gp
end
# ---------------------------------------
end
