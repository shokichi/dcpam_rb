#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# standerd figure
# ホフメラーダイアグラム

# 
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/lib/make_figure.rb")
require 'optparse'
include MKfig
include NumRu

config = {
  "Rain"=>{"nlev"=>20}
}

#################################################
# option
Opt = OptCharge::OptCharge.new(ARGV)
Opt.set

list = Utiles::Explist.new(ARGV[0])
IWS = get_iws

# DCL set
set_dcl(14)

if !Opt.charge[:name].nil? then
  make_figure(Opt.charge[:name],list,set_figopt)
else
  config.keys.each{ |name| make_figure(name,list,{:figtype=>"lontime"}.merge(config[name]))}
end

DCL.grcls
rename_img_file(list,__FILE__)
