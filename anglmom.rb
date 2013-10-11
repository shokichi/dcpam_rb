#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 絶対角運動量の計算
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
require 'optparse'
include Utiles_spe
include NumRu
include Math

def anglmom(dir,name)
  data_name = 'AnglMom'
  # file open
  gu = gpopen(dir + "U.nc", "U")
  gps = gpopen(dir + "Ps.nc", "Ps")
  sigm = gpopen(dir + "U.nc","sigm")
  time = gpopen(dir + "U.nc","time")
  return gu.nil or gps.nil? or sigm.nil? or time.nil? 

  # constants
  sec_in_day = UNumeric[86400, "s"]  #<= 24 hrs/day

  if defined?(HrInDay).nil? and HrInDay.nil? then
    hr_in_day = HrInDay 
  else
    hr_in_day = 24 / omega_ratio(list.name[n])
  end

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

opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-h VAL","--hr_in_day=VAL") {|hr_in_day| HrInDay = hr_in_day.to_i}
opt.parse!(ARGV)

list = Utiles_spe::Explist.new(ARGV[0])
HrInDay = 24 if list.id.include?("diurnal")
list.dir.each_index{|n| anglmom(list.dir[n],list.name[n])} 
