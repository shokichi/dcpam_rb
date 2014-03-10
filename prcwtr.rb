#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 可降水量
#

require 'numru/ggraph'
require 'numru/gphys'
require 'optparse'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/dcpam.rb")
include Utiles
include NumRu
include Math


def calc_prcwtr(dir)
  data_name = 'PrcWtr'
  # file open
  gqv = gpopen dir+"QVap.nc"
  gps = gpopen dir+"Ps.nc"
  sig_weight = gpopen( dir+"QVap.nc","sig_weight")
  return if gqv.nil? || gps.nil? || sig_weight.nil?

  ofile = NetCDF.create( dir + data_name + '.nc')
  GPhys::NetCDF_IO.each_along_dims_write([gqv,gps], ofile, 'time') { 
    |qvap,ps|  

    qc = qvap * ps * sig_weight
    qc = qc.sum("sig") / Grav
    qc.units = 'kg.m-2'
    qc.long_name = 'precipitable water'
    qc.name = data_name

    [qc]
   }
  ofile.close
  print "[#{data_name}](#{dir}) is created \n"
end

opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.parse!(ARGV)
list = Utiles::Explist.new(ARGV[0])

list.dir.each{|dir| calc_prcwtr(dir)}
