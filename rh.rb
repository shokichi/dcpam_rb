#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 相対湿度の計算
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
require 'optparse'
include Utiles_spe
include NumRu
include Math
include NMath

# option
opt = OptionParser.new
opt.on('-r','--rank'){Flag_rank = true}
opt.parse!(ARGV) 
list = Utiles_spe::Explist.new(ARGV[0])

list.dir.each{ |dir| calc_rh_rank(dir) } if defined?(Flag_rank)
list.dir.each{|dir| calc_rh_save(dir)} if !defined?(Flag_rank)

