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
    return @name.index(@ref)
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
  attr_reader :dir, :name, :id, :ref, :refnum
end

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
def self.str_add(str,add_str)
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
def self.glmean(gp)  # 全球平均
  cos_phi = ( gp.axis("lat").to_gphys * (Math::PI/180.0) ).cos
  fact = cos_phi / cos_phi.mean
  gp_mean = (gp * fact).mean("lon","lat")
  return gp_mean
end
#---------------------- 
def self.latmean(gp)  # 南北平均
  cos_phi = ( gp.axis("lat").to_gphys * (Math::PI/180.0) ).cos
  fact = cos_phi / cos_phi.mean
  gp_mean = (gp * fact).mean("lat")
  return gp_mean
end

#---------------------- 
def self.virtical_integral(gp)  # 鉛直積分
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
  gp = gp*(3600 * 24 * 360) * 1000 / LetentHeat / WtWet 
  gp.units = Units["mm.yr-1"]
#  end
 return gp
end
#----------------------
def self.wm2mmhr(gp)  # 降水量の単位変換(W.m-2 -> mm.hr-1)
  gp = gp* 3600 * 1000 / LetentHeat / WtWet 
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
def calc_msf(dir)  # 質量流線関数の計算
  # file open
  gv = gpopen(dir + "V.nc", "V")
  gps = gpopen(dir + "Ps.nc", "Ps")
  sigm = gpopen(dir + "V.nc", "sigm")

  # 定数設定

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
def calc_rh(dir) # 相対湿度の計算
  # file open
  gqvap = gpopen(dir + "QVap.nc", "QVap")
  gps = gpopen(dir + "Ps.nc", "Ps")
  gtemp = gpopen(dir + "Temp.nc", "Temp")

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
  latheat = LatentHeat * MolWtWet

  gasrwet = gasruniv / qvapmol
  epsv = qvapmol / drymol


  data_name = 'RH'
  ofile = NetCDF.create( dir + data_name + '.nc')
  GPhys::NetCDF_IO.each_along_dims_write([gqvap,gps,gtemp],ofile,'time'){ 
    |qvap,ps,temp| 

    time = ps.axis('time')  
 
    # 気圧の計算
    press_na = NArray.sfloat(lon.length,lat.length,
                             sig.length,time.length)
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
def local_time(gp,hr_in_day)

  time = gp.axis("time").to_gphys
  lon = gp.axis('lon')

  if time.units.to_s=='min' 
    time = time / 60
    time.units = 'hrs'
  elsif time.units.to_s=='day'
    time = time * 24
    time.units = 'hrs'
  end

  local_time = lon.pos / 360 * hr_in_day
  local_time.long_name = "local time"
  local_time.units = "hrs"
  lon = lon.to_gphys
  dlon = lon[1].val-lon[0].val
  
  gphys_local = GPhys.each_along_dims([gp,time],"time"){ 
    |gphys,gtime|

    gp_local = gphys.copy
    gp_local[false] = 0

    hr = gtime.val/hr_in_day
    hr = hr - hr.to_i

    eqtime = 360*hr
    local = lon + eqtime
    for i in 0..local.length-1
      if local[i].val > 360 then
        local[i].val = local[i].val-360.0
      end
    end
    min = local.val.min
    for i in 0..lon.length-1
      n = local.to_a.index(min + dlon*i)
      gp_local[i,false].val = gphys[n,false].val
    end

    gp_local.axis(0).set_pos(local_time)
    return gp_local
  }
  return gphys_local
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
def gpopen(file,name)
  begin
    gp = GPhys::IO.open file, name
  rescue
    if !file.include?(name)
      gp = GPhys::IO.open file.sub(".nc","_rank000000.nc"), name
    else
      dir = File::dirname(file)+"/"
      file = Utiles_spe.str_add(dir,`ls #{file.sub(".nc","_rank")}*.nc`.split("\n"))
      gp = GPhys::IO.open file, name
    end
  end
  return gp
end
# ---------------------------------------
end
