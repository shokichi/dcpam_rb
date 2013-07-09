#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 
# 
module Utiles_skc 
  include NumRu
  include Math
  include NMath
  require "numru/ggraph"
  require 'numru/gphys'
 
  # 定数設定
  Grav       = UNumeric[9.8, "m.s-2"]
  Round      = UNumeric[6400000.0, "m"]
  QVapmol    = UNumeric[18.01528e-3, "kg.mol-1"]
  Drymol     = UNumeric[28.964e-3,"kg.mol-1"]
  RefPress   = UNumeric[1.4e+11,"Pa"]
  LatHeat    = UNumeric[43655,"J.mol-1"]
  Gasruniv   = UNumeric[8.314,"J.K-1.mol-1"]
  
  Es0        = UNumeric[611,"Pa"]
  Latentheat = LatHeat/QVapmol
  #          = UNumeric[2.5e+6,"J.kg-1"]

  module_function

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
      alph = vwind * cos_phi * ps * Round * PI * 2 / Grav 
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
#    grav = UNumeric[9.8, "m.s-2"]
#    round = UNumeric[6400000.0, "m"]
#    qvapmol = UNumeric[18.01528e-3, "kg.mol-1"]
#    drymol =UNumeric[28.964e-3,"kg.mol-1"]
#    p0 = UNumeric[1.4e+11,"Pa"]
#    latheat = UNumeric[43655,"J.mol-1"]
#    gasruniv = UNumeric[8.314,"J.K-1.mol-1"]
#  
#    es0 = UNumeric[611,"Pa"]
#    latentheat = UNumeric[2.5e+6,"J.kg-1"]
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
    #  qvap_sat = epsv * (RefPress / press) * (-latheat / (gasruniv * temp) ).exp
  
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
    Grav = UNumeric[9.8, "m.s-2"]
  
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

end


class Explist

  def initialize(file_list)  # 実験ファイルリストの読み込み
    @@filelist = file_list
    if @@filelist != nil then
      read_file
      get_exp_id
    else
      default
    end
  end
  
  private
  def read_file
    n = 0
    name = []
    dir = []
    begin
      fin = File.open(@@filelist,"r")
    rescue
      default
      error_msg
      return
    end
    loop{
      char = fin.gets
      break if char == nil
      next if char[0..0] == "#" # コメントアウト機能
      char = char.chop.split(",")
      name[n] = char[0]
      dir[n]  = char[1]
      dir[n]  = char[1].split(":") if char[1].include?(":") == true 
      n += 1
    }
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
  end

  def error_msg
    print "[#{@@filelist}] Such file is not exist \n"
    print "[#{@dir[0]}] Set directory \n"
  end

  public  
  attr_reader :dir, :name, :id
end
