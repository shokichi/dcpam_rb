#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 可降水量
#

require 'numru/ggraph'
require 'numru/gphys'
require 'optparse'
require File.expand_path(File.dirname(__FILE__)+"/lib/dcpam.rb")
include Utiles
include NumRu
include Math

Opt = OptCharge::OptCharge.new
Opt.set

list = Utiles::Explist.new(ARGV[0])
list.dir.each{|dir| calc_prcwtr_save(dir)}
