#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 自転角速度変更実験用スクリプト
#

require "numru/ggraph"
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/utiles_omega.rb")
require 'optparse'
include Omega
include NumRu
include Math
include NMath

opt = OptionParser.new
opt.on("-a") {type = "a"}
opt.on("-b") {type = "b"}
opt.on("-c") {type = "c"}
opt.parse!(ARGV)


file_all = "/home/ishioka/link/all/fig/list/omega_all_MTlocal.list"
file_coriolis = "/home/ishioka/link/coriolis/fig/list/omega_coriolis_MTlocal.list"
file_diurnal = "/home/ishioka/link/diurnal/fig/list/omega_diurnal_MTlocal.list"


#drawfig([file_all,file_coriolis,file_diurnal],type)
drawclm([file_all,file_coriolis,file_diurnal])
#list = Utiles_spe::Explist.new(file_all)
#albedo = Utiles_spe.array2gp(get_omega(list),get_albedo(list))
#GGraph.scatter albedo.axis("noname").to_gphys,albedo, false
#list = Utiles_spe::Explist.new(file_all)
#albedo = Utiles_spe.array2gp(get_omega(list),get_albedo(list))
#GGraph.scatter albedo.axis("noname").to_gphys,albedo, false

