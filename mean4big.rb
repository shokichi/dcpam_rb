#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#  
# 

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/dcpam.rb")
require 'optparse'
include Utiles
include NumRu
include Math


def big_mean(dir,data_name)
  gphys = gpopen dir + data_name + '.nc'
  return if gphys.nil?
  ntime = gphys.axis('time').length
  ave = gphys[false,0]
  for i in 1..ntime-1
    ave = ave + gphys[false,i]
  end
  ave = ave/ntime
  ave = ave.mean('lon')
  ofile = NetCDF.create(dir + 'M' + data_name + '.nc')
  GPhys::IO.write(ofile, ave)
  ofile.close
end

def time_mean(dir,data_name)
  gphys = gpopen dir + data_name + '.nc'
  return if gphys.nil?
  ntime = gphys.axis('time').length
  ave = 0
  GPhys.each_along_dims(gphys,"time") do |gp|
    ave = ave + gp
  end
  ave = ave/ntime
  ofile2 = NetCDF.create(dir + 'MT' + data_name + '.nc')
  GPhys::IO.write(ofile2, ave)
  ofile2.close
end

def lon_mean(dir,data_name)
  gphys = gpopen dir + data_name + '.nc'
  return if gphys.nil?
  ofile2 = NetCDF.create(dir + 'ML' + data_name + '.nc')
  GPhys::NetCDF_IO.each_along_dims_write(gphys, ofile2, 'time') { 
    |sub|  
    subm = sub.mean('lon')
    [submean]
  }
  ofile2.close
end


# option
Opt = OptCharge::OptCharge.new(ARGV)
Opt.add_option("--time",:time_mean,"flag")
Opt.add_option("--lon",:lon_mean,"flag")
Opt.set

list = Utiles::Explist.new(ARGV[0])
IWS = get_iws

varname = Opt.charge[:name]

if Opt.charge[:time_mean]
  list.dir.each{|dir| time_mean(dir,varname)}
elsif  Opt.charge[:lon_mean]
  list.dir.each{|dir| lon_mean(dir,varname)}
else
  list.dir.each{|dir| big_mean(dir,varname)}
end

=begin
def time_mean_range(dir,data_name)
  gphys = GPhys::IO.open(dir + 'Up' + data_name + '.nc',data_name)
  rmiss = 0
  ntime = gphys.axis('time').length
  
  ave = NArrayMiss.to_nam(gphys[false,0].to_a,gphys[false,0].gt(rmiss))
  for i in 0..ntime-1
    ave = ave + NArrayMiss.to_nam(gphys[false,i].to_a,gphys[false,i].gt(rmiss))
  end
#  ave = ave/ntime
  ave = ave.mean(0)

  # NArray to GPhys
  gpave = GPhys.new(gphys[0,false,0].grid_copy,VArray.new(ave))
  gpave.name = data_name
  # write file
  ofile2 = NetCDF.create(dir + 'M' + 'Up'+ data_name + '.nc')
  GPhys::IO.write(ofile2, gpave)
  ofile2.close
end

def lon_mean(dir,data_name)
  gphys = GPhys::IO.open(dir + 'Mt' + data_name + '.nc',data_name)
  gphys = gphys.mean('lon')
  ofile2 = NetCDF.create(dir + 'M' + data_name + '.nc')
  GPhys::IO.write(ofile2, gphys)
  ofile2.close
end
=end


