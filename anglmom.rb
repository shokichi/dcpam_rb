#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 絶対角運動量の計算
#

require 'numru/ggraph'
require 'numru/gphys'
require '/home/ishioka/ruby/lib/utiles_spe'
include Utiles_spe
include NumRu
include Math

def anglmom(dir,name)
  data_name = 'AnglMom'
  # file open
  begin
    gu = gpopen(dir + "U.nc", "U")
    gps = gpopen(dir + "Ps.nc", "Ps")
    sigm = gpopen(dir + "U.nc","sigm")
    time = gpopen(dir + "U.nc","time")
  rescue
    print "[#{data_name}](#{dir}) is not created \n"
    return
  end
  # constants
  Grav    = UNumeric[9.8, "m.s-2"]       # 重力加速度
  RPlanet = UNumeric[6371000.0, "m"]     # 惑星半径
  sec_in_day = UNumeric[86400, "s"]  #<= 24 hrs/day

  hr_in_day = 24 / omega_ratio(list.name[n])

  omega = 2*PI/sec_in_day           # Earth
  omega = omega * 24.0 / hr_in_day

  #
  theta = (gu.axis("lat").to_gphys * (PI/180.0))

  # 計算
  ofile = NetCDF.create( dir + data_name + '.nc')
  GPhys::NetCDF_IO.each_along_dims_write([gu,gps], ofile, 'time') { 
    |uwind,ps|  

    angl = uwind.copy
    angl[false] = 0
    
    angl = (RPlanet * theta.cos * omega + uwind ) * RPlanet * theta.cos

    angl.units = 'm2.s-1'
    angl.long_name = 'angular momentum'
    angl.name = data_name
    [angl]
  }
  ofile.close
  print "[#{data_name}](#{dir}) is created \n"
end


list = Utiles_spe::Explist.new(ARGV[0])
list.dir.length.each_index{|n| anglmom(list.dir[n],list.name[n])} 
