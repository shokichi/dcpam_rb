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

# option
Opt = OptCharge::OptCharge.new(ARGV)
Opt.set

list = Utiles_spe::Explist.new(ARGV[0])
IWS = 2 if Opt.charge[:ps] || Opt.charge[:eps]
IWS = 4 if Opt.charge[:png]
IWS = 1 if !defined? IWS

# DCL set
set_dcl(14)

FigType = "lontime"
if !Opt.charge[:varname].nil? then
  make_figure(Opt.charge[:varname],list,set_figopt)
else
  make_figure("Rain",list,"nlev"=>20)
end

DCL.grcls
rename_img_file(list,__FILE__)
