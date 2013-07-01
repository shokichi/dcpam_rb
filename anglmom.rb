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
    gu = GPhys::IO.open(dir + "U.nc", "U")
    gps = GPhys::IO.open(dir + "Ps.nc", "Ps")
    sigm = GPhys::IO.open(dir + "U.nc","sigm")
  rescue
    print "[#{data_name}](#{dir}) is not created \n"
    return
  end
  # constants
  grav = UNumeric[9.8, "m.s-2"]      #<= 重力加速度
  round = UNumeric[6400000, "m"]     #<= 惑星半径
  sec_in_day = UNumeric[86400, "s"]  #<= 24 hrs/day

  # 
  theta = (gu.axis("lat").to_gphys * (PI/180.0))
  omega = 2*PI/sec_in_day
  omega = omega * Utiles_spe.omega_ratio(name)

  # 計算
  ofile = NetCDF.create( dir + data_name + '.nc')
  GPhys::NetCDF_IO.each_along_dims_write([gu,gps], ofile, 'time') { 
    |uwind,ps|  

    angl = uwind.copy
    angl[false] = 0
    
    angl = (round * theta.cos * omega + uwind ) * round * theta.cos

    angl.units = 'm2.s-1'
    angl.long_name = 'angular momentum'
    angl.name = data_name
    [angl]
  }
  ofile.close
  print "[#{data_name}](#{dir}) is created \n"
end


dir, name = Utiles_spe.explist(ARGV[0])
(0..dir.length-1).each{|n| anglmom(dir[n],name[n])} 
