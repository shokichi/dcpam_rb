#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 飽和水蒸気圧の計算
#

require 'numru/ggraph'
require 'numru/gphys'
require 'optparse'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu
include Math

ES0 = UNumeric[611,"Pa"]

def calc_es(dir,name)
  temp = gpopen dir + "Temp.nc"
  return if temp.nil?

  if defined?(HrInDay) and !HrInDay.nil? then
    hr_in_day = HrInDay
  else
    hr_in_day = 24 / Utiles_spe.omega_ratio(name)
  end

  ave = 0
  data_name = "Es"
  GPhys::NetCDF_IO.each_along_dims_write(temp, ofile,'time') { 
    |tmp|
    es = 
      ES0 * ( LatentHeat/(GasRUniv/MolWtWet)*(1/273.0- 1/tmp)).exp
    es = local_time(es,hr_in_day)
    ave += es
  }
  es.name = data_name
  es.long_name = "saturation vapor pressure"
  ave = ave[false,0]/temp.axis("time").pos.length
  ofile = NetCDF.create(file.sub(data_name,"MTlocal_" + data_name))
  GPhys::IO.write(ofile, ave)
  ofile.close
end


opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-h VAL","--hr_in_day=VAL") {|hr_in_day| HrInDay = hr_in_day.to_i}
opt.parse!(ARGV)
list = Utiles_spe::Explist.new(ARGV[0])
HrInDay = 24 if list.id.include?("coriolis")

list.dir.each_index{|n| calc_es(list.dir[n],list.name[n]) } 
